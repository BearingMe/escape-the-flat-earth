extends GutTest


func test_controller_look_axis_uses_deadzone_and_remapped_range() -> void:
	assert_eq(ObserverPlayer.shape_controller_look(Vector2(0.1, 0.0)), Vector2.ZERO)
	var half_input: Vector2 = ObserverPlayer.shape_controller_look(Vector2(0.59, 0.0))
	assert_almost_eq(half_input.x, 0.5, 0.001)
	assert_almost_eq(half_input.y, 0.0, 0.001)
	var full_input: Vector2 = ObserverPlayer.shape_controller_look(Vector2(1.0, 0.0))
	assert_almost_eq(full_input.x, 1.0, 0.001)


func test_look_delta_wraps_yaw_and_clamps_pitch() -> void:
	var observer: ObserverPlayer = ObserverPlayer.new()
	observer._local_yaw = PI - 0.1
	observer._local_pitch = 0.0
	observer._apply_look_delta(Vector2(-0.3, -10.0))
	assert_almost_eq(observer._local_yaw, -PI + 0.2, 0.001)
	assert_almost_eq(observer._local_pitch, ObserverPlayer.MAX_VIEW_PITCH, 0.001)
	observer.free()


func test_camera_sensitivities_are_configurable() -> void:
	var observer: ObserverPlayer = ObserverPlayer.new()
	observer.mouse_sensitivity = 0.004
	observer.controller_sensitivity = 3.0
	observer._apply_mouse_motion(Vector2(5.0, -5.0))
	assert_almost_eq(observer.mouse_sensitivity, 0.004, 0.0001)
	assert_almost_eq(observer.controller_sensitivity, 3.0, 0.0001)
	assert_almost_eq(observer._local_yaw, -0.02, 0.0001)
	assert_almost_eq(observer._local_pitch, 0.02, 0.0001)
	observer.free()


func test_mouse_look_is_location_independent_across_disk_inspection_points() -> void:
	var observer: ObserverPlayer = ObserverPlayer.new()
	var inspection_points: Array[Vector3] = [
		Vector3(0.0, 250.0, 0.0), Vector3(5000.0, 250.0, 0.0), Vector3(0.0, -250.0, 0.0)
	]
	for point: Vector3 in inspection_points:
		observer.position = point
		observer._local_yaw = 0.0
		observer._local_pitch = 0.0
		observer._apply_mouse_motion(Vector2(40.0, -20.0))
		assert_almost_eq(observer._local_yaw, -0.1, 0.0001)
		assert_almost_eq(observer._local_pitch, 0.05, 0.0001)
	observer.free()
