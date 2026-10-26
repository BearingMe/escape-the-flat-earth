extends GutTest


func test_ground_acceleration_approaches_walk_speed_at_configured_rate() -> void:
	var next_velocity: Vector3 = ObserverPlayer.approach_horizontal_velocity(
		Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 0.0, ObserverPlayer.WALK_SPEED_M_S, 24.0, 0.1
	)
	assert_almost_eq(next_velocity.x, 0.0, 0.0001)
	assert_almost_eq(next_velocity.y, 0.0, 0.0001)
	assert_almost_eq(next_velocity.z, -2.4, 0.0001)


func test_braking_reduces_horizontal_speed_without_changing_vertical_velocity() -> void:
	var next_velocity: Vector3 = ObserverPlayer.approach_horizontal_velocity(
		Vector3(0.0, -3.0, -6.0), Vector3.ZERO, 0.0, ObserverPlayer.WALK_SPEED_M_S, 36.0, 0.1
	)
	assert_almost_eq(next_velocity.x, 0.0, 0.0001)
	assert_almost_eq(next_velocity.y, -3.0, 0.0001)
	assert_almost_eq(next_velocity.z, -2.4, 0.0001)


func test_diagonal_intent_is_speed_limited_and_non_finite_values_are_rejected() -> void:
	var next_velocity: Vector3 = ObserverPlayer.approach_horizontal_velocity(
		Vector3.ZERO, Vector3(1.0, 50.0, -1.0), 0.0, 6.0, 100.0, 1.0
	)
	assert_almost_eq(next_velocity.length(), 6.0, 0.0001)
	assert_true(ObserverPlayer.is_valid_movement_intent(Vector3(0.5, 0.0, -0.5), 0.0, 0.0))
	assert_false(ObserverPlayer.is_valid_movement_intent(Vector3(0.0, 1.0, 0.0), 0.0, 0.0))
	assert_false(ObserverPlayer.is_valid_movement_intent(Vector3(2.0, 0.0, 0.0), 0.0, 0.0))
	assert_false(ObserverPlayer.is_valid_movement_intent(Vector3(INF, 0.0, 0.0), 0.0, 0.0))


func test_stable_player_spawn_slots_are_spaced_around_the_disk_center() -> void:
	var first: ObserverPlayer = ObserverPlayer.new()
	var second: ObserverPlayer = ObserverPlayer.new()
	first.configure(1, "player_8675309_1", "First")
	second.configure(2, "player_8675309_2", "Second")
	assert_gt(first.position.distance_to(second.position), 2.9)
	assert_almost_eq(first.position.y, World.config.disk_thickness_m * 0.5 + 0.05, 0.0001)
	first.free()
	second.free()
