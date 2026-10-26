extends GutTest

var _field: DiskGravityField
var _config: WorldConfig


func before_each() -> void:
	_config = WorldConfig.new()
	_field = DiskGravityField.new()
	assert_eq(_field.configure(_config), OK)


func test_central_surface_gravity_is_calibrated_on_both_sides() -> void:
	var top_gravity: Vector3 = _field.gravity_at(Vector3(0.0, _config.disk_thickness_m * 0.5, 0.0))
	var underside_gravity: Vector3 = _field.gravity_at(
		Vector3(0.0, -_config.disk_thickness_m * 0.5, 0.0)
	)
	assert_almost_eq(top_gravity.y, -_config.central_surface_gravity_m_s2, 0.001)
	assert_almost_eq(underside_gravity.y, _config.central_surface_gravity_m_s2, 0.001)
	assert_almost_eq(top_gravity.x, 0.0, 0.001)
	assert_almost_eq(top_gravity.z, 0.0, 0.001)


func test_central_surface_gravity_uses_configured_dimensions_and_strength() -> void:
	var custom_config: WorldConfig = WorldConfig.new()
	custom_config.disk_radius_m = 2000.0
	custom_config.disk_thickness_m = 100.0
	custom_config.central_surface_gravity_m_s2 = 3.0
	var custom_field: DiskGravityField = DiskGravityField.new()
	assert_eq(custom_field.configure(custom_config), OK)
	var surface_gravity: Vector3 = custom_field.gravity_at(Vector3(0.0, 50.0, 0.0))
	assert_almost_eq(surface_gravity.y, -3.0, 0.001)


func test_center_is_symmetric_and_gravity_points_toward_the_disc() -> void:
	assert_eq(_field.gravity_at(Vector3.ZERO), Vector3.ZERO)
	var outside_top: Vector3 = _field.gravity_at(Vector3(0.0, 1000.0, 0.0))
	var outside_bottom: Vector3 = _field.gravity_at(Vector3(0.0, -1000.0, 0.0))
	assert_true(outside_top.y < 0.0)
	assert_true(outside_bottom.y > 0.0)
	assert_almost_eq(outside_top.y, -outside_bottom.y, 0.001)


func test_off_axis_field_is_finite_and_radially_inward() -> void:
	var gravity: Vector3 = _field.gravity_at(
		Vector3(_config.disk_radius_m * 0.45, _config.disk_thickness_m * 0.5, 0.0)
	)
	assert_true(gravity.is_finite())
	assert_true(gravity.x < 0.0)
	assert_true(gravity.y < 0.0)
	assert_almost_eq(gravity.z, 0.0, 0.001)


func test_off_axis_field_matches_independent_volume_integral_references() -> void:
	# Direct reference values use independent 240x1024x160 volume quadrature.
	var above_surface: Vector3 = _field.gravity_at(Vector3(2250.0, 375.0, 0.0))
	var beyond_rim: Vector3 = _field.gravity_at(Vector3(5750.0, 100.0, 0.0))
	assert_almost_eq(above_surface.x, -2.49201, 0.04)
	assert_almost_eq(above_surface.y, -9.41216, 0.04)
	assert_almost_eq(beyond_rim.x, -6.23610, 0.04)
	assert_almost_eq(beyond_rim.y, -0.30257, 0.04)


func test_field_is_continuous_across_the_outer_rim() -> void:
	var radius: float = _config.disk_radius_m
	var inside: Vector3 = _field.gravity_at(Vector3(radius - 1.0, 0.0, 0.0))
	var at_rim: Vector3 = _field.gravity_at(Vector3(radius, 0.0, 0.0))
	var outside: Vector3 = _field.gravity_at(Vector3(radius + 1.0, 0.0, 0.0))
	assert_true(inside.is_finite() and at_rim.is_finite() and outside.is_finite())
	assert_lt(absf(inside.x - outside.x), 0.05)
	assert_lt(absf(inside.y - outside.y), 0.05)


func test_numerical_to_far_field_transition_is_continuous() -> void:
	var near_transition: Vector3 = _field.gravity_at(Vector3(39999.5, 0.0, 0.0))
	var far_transition: Vector3 = _field.gravity_at(Vector3(40000.5, 0.0, 0.0))
	assert_lt(absf(near_transition.x - far_transition.x), 0.00002)
	assert_almost_eq(near_transition.y, far_transition.y, 0.00002)


func test_invalid_configuration_and_non_finite_position_fail_closed() -> void:
	var invalid_config: WorldConfig = WorldConfig.new()
	invalid_config.disk_thickness_m = -1.0
	assert_eq(_field.configure(invalid_config), ERR_INVALID_PARAMETER)
	assert_eq(_field.gravity_at(Vector3(INF, 0.0, 0.0)), Vector3.ZERO)
