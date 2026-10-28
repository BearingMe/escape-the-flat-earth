extends GutTest


func test_state_names() -> void:
	assert_eq(PlayerTraversalState.state_name(PlayerTraversalState.State.NORMAL), "Normal")
	assert_eq(PlayerTraversalState.state_name(PlayerTraversalState.State.CLIMBING), "Climbing")
	assert_eq(PlayerTraversalState.state_name(PlayerTraversalState.State.RAGDOLL), "Ragdoll")
	assert_eq(PlayerTraversalState.state_name(PlayerTraversalState.State.CARRIED), "Carried")


func test_can_climb_surface_normal() -> void:
	# Vertical wall normal: Vector3(1, 0, 0)
	assert_true(PlayerTraversalState.can_climb(Vector3(1.0, 0.0, 0.0)))
	assert_true(PlayerTraversalState.can_climb(Vector3(0.0, 0.2, -0.98).normalized()))

	# Flat ground normal: Vector3(0, 1, 0) -> not climbable
	assert_false(PlayerTraversalState.can_climb(Vector3(0.0, 1.0, 0.0)))

	# Ceiling normal: Vector3(0, -1, 0) -> not climbable
	assert_false(PlayerTraversalState.can_climb(Vector3(0.0, -1.0, 0.0)))


func test_knockdown_and_stumble_thresholds() -> void:
	# Damage threshold is 20
	assert_false(PlayerTraversalState.should_knockdown_from_damage(15.0))
	assert_true(PlayerTraversalState.should_knockdown_from_damage(20.0))
	assert_true(PlayerTraversalState.should_knockdown_from_damage(45.0))

	# Fall stumble threshold is 18 m/s
	assert_false(PlayerTraversalState.should_stumble_from_fall(12.0))
	assert_true(PlayerTraversalState.should_stumble_from_fall(18.5))
