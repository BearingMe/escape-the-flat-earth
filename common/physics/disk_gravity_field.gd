class_name DiskGravityField
extends RefCounted

const RADIAL_SAMPLES: int = 32
const ANGULAR_SAMPLES: int = 128
const DEPTH_SAMPLES: int = 24
const RADIAL_GRID_STEP: float = 1.0 / 128.0
const VERTICAL_GRID_STEP: float = 1.0 / 512.0
const MAX_CACHE_ENTRIES: int = 8192
const FAR_FIELD_BLEND_START: float = 7.5
const FAR_FIELD_RADIUS: float = 8.0

var _radius_m: float = 5000.0
var _thickness_ratio: float = 0.1
var _gravity_scale: float = 1.0
var _softening: float = 0.0005
var _configured: bool = false
var _profile_cache: Dictionary = {}
var _cache_order: Array[Vector2i] = []


func configure(config: WorldConfig) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	_radius_m = config.disk_radius_m
	_thickness_ratio = config.disk_thickness_m / _radius_m
	var surface_integral: float = (
		2.0 * PI * (1.0 + _thickness_ratio - sqrt(1.0 + _thickness_ratio * _thickness_ratio))
	)
	if not is_finite(surface_integral) or surface_integral <= 0.0:
		return ERR_INVALID_PARAMETER
	_gravity_scale = config.central_surface_gravity_m_s2 / surface_integral
	_softening = minf(_thickness_ratio / float(DEPTH_SAMPLES), 1.0 / float(RADIAL_SAMPLES)) * 0.06
	_profile_cache.clear()
	_cache_order.clear()
	_configured = true
	return OK


func gravity_at(position: Vector3) -> Vector3:
	if not _configured or not position.is_finite():
		return Vector3.ZERO
	var horizontal_position: Vector2 = Vector2(position.x, position.z)
	var radial_distance: float = horizontal_position.length()
	var radial_units: float = radial_distance / _radius_m
	var vertical_units: float = absf(position.y) / _radius_m
	var normalized_distance: float = Vector2(radial_units, vertical_units).length()
	if normalized_distance <= 0.0000001:
		return Vector3.ZERO
	var far_field: Vector3 = _far_field_gravity(position, normalized_distance)
	if normalized_distance >= FAR_FIELD_RADIUS:
		return far_field
	var gravity: Vector3
	if radial_distance <= 0.000001:
		var axis_integral: float = _axis_vertical_integral(vertical_units)
		gravity = Vector3.UP * axis_integral * _gravity_scale * signf(position.y)
	else:
		var profile: Vector2 = _interpolated_profile(radial_units, vertical_units)
		var radial_direction: Vector3 = Vector3(horizontal_position.x, 0.0, horizontal_position.y)
		radial_direction /= radial_distance
		var vertical_sign: float = signf(position.y)
		gravity = (
			radial_direction * profile.x * _gravity_scale
			+ Vector3.UP * profile.y * _gravity_scale * vertical_sign
		)
	if normalized_distance > FAR_FIELD_BLEND_START:
		var blend_fraction: float = clampf(
			(
				(normalized_distance - FAR_FIELD_BLEND_START)
				/ (FAR_FIELD_RADIUS - FAR_FIELD_BLEND_START)
			),
			0.0,
			1.0
		)
		var blend: float = blend_fraction * blend_fraction * (3.0 - 2.0 * blend_fraction)
		gravity = gravity.lerp(far_field, blend)
	return gravity


func _interpolated_profile(radial_units: float, vertical_units: float) -> Vector2:
	var radial_cell: int = floori(radial_units / RADIAL_GRID_STEP)
	var vertical_cell: int = floori(vertical_units / VERTICAL_GRID_STEP)
	var radial_fraction: float = (radial_units / RADIAL_GRID_STEP) - float(radial_cell)
	var vertical_fraction: float = (vertical_units / VERTICAL_GRID_STEP) - float(vertical_cell)
	var lower_left: Vector2 = _profile_at(radial_cell, vertical_cell)
	var lower_right: Vector2 = _profile_at(radial_cell + 1, vertical_cell)
	var upper_left: Vector2 = _profile_at(radial_cell, vertical_cell + 1)
	var upper_right: Vector2 = _profile_at(radial_cell + 1, vertical_cell + 1)
	var lower: Vector2 = lower_left.lerp(lower_right, radial_fraction)
	var upper: Vector2 = upper_left.lerp(upper_right, radial_fraction)
	return lower.lerp(upper, vertical_fraction)


func _profile_at(radial_cell: int, vertical_cell: int) -> Vector2:
	var key: Vector2i = Vector2i(radial_cell, vertical_cell)
	if _profile_cache.has(key):
		return _profile_cache[key]
	var radial_units: float = float(radial_cell) * RADIAL_GRID_STEP
	var vertical_units: float = float(vertical_cell) * VERTICAL_GRID_STEP
	var value: Vector2 = _integrate_profile(radial_units, vertical_units)
	_profile_cache[key] = value
	_cache_order.append(key)
	if _cache_order.size() > MAX_CACHE_ENTRIES:
		var expired_key: Vector2i = _cache_order.pop_front()
		_profile_cache.erase(expired_key)
	return value


func _integrate_profile(radial_units: float, vertical_units: float) -> Vector2:
	if radial_units <= 0.000001:
		return Vector2(0.0, _axis_vertical_integral(vertical_units))
	var volume_element: float = (
		PI * _thickness_ratio / float(RADIAL_SAMPLES * ANGULAR_SAMPLES * DEPTH_SAMPLES)
	)
	var radial_acceleration: float = 0.0
	var vertical_acceleration: float = 0.0
	var source_half_height: float = _thickness_ratio * 0.5
	for radial_index: int in range(RADIAL_SAMPLES):
		var source_radius: float = sqrt((float(radial_index) + 0.5) / float(RADIAL_SAMPLES))
		for depth_index: int in range(DEPTH_SAMPLES):
			var source_y: float = (
				-source_half_height
				+ (float(depth_index) + 0.5) * _thickness_ratio / float(DEPTH_SAMPLES)
			)
			for angular_index: int in range(ANGULAR_SAMPLES):
				var angle: float = TAU * (float(angular_index) + 0.5) / float(ANGULAR_SAMPLES)
				var delta_x: float = source_radius * cos(angle) - radial_units
				var delta_z: float = source_radius * sin(angle)
				var delta_y: float = source_y - vertical_units
				var distance_squared: float = (
					delta_x * delta_x
					+ delta_y * delta_y
					+ delta_z * delta_z
					+ _softening * _softening
				)
				var inverse_distance_cubed: float = (
					1.0 / (distance_squared * sqrt(distance_squared))
				)
				radial_acceleration += delta_x * inverse_distance_cubed * volume_element
				vertical_acceleration += delta_y * inverse_distance_cubed * volume_element
	return Vector2(radial_acceleration, vertical_acceleration)


func _axis_vertical_integral(vertical_units: float) -> float:
	if vertical_units <= 0.000001:
		return 0.0
	var half_height: float = _thickness_ratio * 0.5
	var lower_offset: float = vertical_units - half_height
	var upper_offset: float = vertical_units + half_height
	var lower_value: float = absf(lower_offset) - sqrt(1.0 + lower_offset * lower_offset)
	var upper_value: float = absf(upper_offset) - sqrt(1.0 + upper_offset * upper_offset)
	return -2.0 * PI * (upper_value - lower_value)


func _far_field_gravity(position: Vector3, normalized_distance: float) -> Vector3:
	var effective_mass: float = PI * _thickness_ratio
	var magnitude: float = (
		_gravity_scale * effective_mass / (normalized_distance * normalized_distance)
	)
	return -position.normalized() * magnitude
