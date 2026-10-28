class_name EnvironmentalHazardModel
extends RefCounted


static func calculate_wind_push_force(
	wind_velocity: Vector3, exposure_factor: float = 1.0
) -> Vector3:
	if not wind_velocity.is_finite() or exposure_factor <= 0.0:
		return Vector3.ZERO
	# Only horizontal wind push
	var horizontal_wind: Vector3 = Vector3(wind_velocity.x, 0.0, wind_velocity.z)
	var speed: float = horizontal_wind.length()
	if speed < 6.0:
		return Vector3.ZERO
	var push_magnitude: float = (speed - 6.0) * 22.0 * clampf(exposure_factor, 0.0, 1.0)
	return horizontal_wind.normalized() * push_magnitude


static func calculate_frostbite_damage(
	temperature_c: float, has_thermal_gear: bool, in_shelter: bool, delta: float
) -> float:
	if in_shelter or temperature_c > -10.0 or delta <= 0.0:
		return 0.0
	var cold_severity: float = absf(temperature_c - (-10.0))
	var damage_rate: float = cold_severity * 0.25
	if has_thermal_gear:
		damage_rate *= 0.20  # 80% mitigation
	return damage_rate * delta


static func calculate_firmament_barrier_damage(
	world_pos: Vector3, barrier_center: Vector2, barrier_radius_m: float, delta: float
) -> float:
	if not world_pos.is_finite() or delta <= 0.0:
		return 0.0
	var pos_2d: Vector2 = Vector2(world_pos.x, world_pos.z)
	var dist: float = pos_2d.distance_to(barrier_center)
	if dist <= barrier_radius_m:
		return 0.0
	var outside_depth: float = dist - barrier_radius_m
	var damage_rate: float = 2.5 + (outside_depth * 0.04)
	return damage_rate * delta


static func is_inside_safe_zone(
	world_pos: Vector3, barrier_center: Vector2, barrier_radius_m: float
) -> bool:
	if not world_pos.is_finite():
		return false
	return Vector2(world_pos.x, world_pos.z).distance_to(barrier_center) <= barrier_radius_m
