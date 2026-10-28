extends GutTest


func test_pursuit_velocity_direction_and_magnitude() -> void:
	var current: Vector3 = Vector3(0.0, 0.0, 0.0)
	var target: Vector3 = Vector3(10.0, 5.0, 0.0)

	var vel: Vector3 = AISteeringModel.calculate_pursuit_velocity(current, target, 8.0)
	assert_almost_eq(vel.x, 8.0, 0.01)
	assert_almost_eq(vel.z, 0.0, 0.01)
	assert_almost_eq(vel.length(), 8.0, 0.01)


func test_flee_velocity() -> void:
	var current: Vector3 = Vector3(0.0, 0.0, 0.0)
	var threat: Vector3 = Vector3(10.0, 0.0, 0.0)

	var vel: Vector3 = AISteeringModel.calculate_flee_velocity(current, threat, 6.0)
	assert_almost_eq(vel.x, -6.0, 0.01)


func test_range_check() -> void:
	var a: Vector3 = Vector3(0.0, 0.0, 0.0)
	var b: Vector3 = Vector3(3.0, 0.0, 4.0)  # dist = 5.0

	assert_true(AISteeringModel.is_target_in_range(a, b, 5.0))
	assert_true(AISteeringModel.is_target_in_range(a, b, 6.0))
	assert_false(AISteeringModel.is_target_in_range(a, b, 4.9))


func test_magnetic_pull() -> void:
	var anomaly_pos: Vector3 = Vector3(0.0, 0.0, 0.0)
	var close_pos: Vector3 = Vector3(5.0, 0.0, 0.0)
	var far_pos: Vector3 = Vector3(25.0, 0.0, 0.0)

	var pull_close: Vector3 = AISteeringModel.calculate_magnetic_pull(
		close_pos, anomaly_pos, 18.0, 300.0
	)
	var pull_far: Vector3 = AISteeringModel.calculate_magnetic_pull(
		far_pos, anomaly_pos, 18.0, 300.0
	)

	# Pull direction is towards anomaly (-X)
	assert_lt(pull_close.x, 0.0)
	assert_gt(pull_close.length(), 0.0)
	# Past 18m -> 0 pull
	assert_almost_eq(pull_far.length(), 0.0, 0.01)
