extends GutTest


func test_initial_survival_state() -> void:
	var state: SurvivalState = SurvivalState.new()
	assert_almost_eq(state.health, 100.0, 0.01)
	assert_almost_eq(state.stamina, 100.0, 0.01)
	assert_almost_eq(state.hunger, 100.0, 0.01)
	assert_almost_eq(state.thirst, 100.0, 0.01)
	assert_almost_eq(state.core_temperature_c, 37.0, 0.01)
	assert_false(state.is_incapacitated)
	assert_false(state.is_dead)


func test_stamina_drain_and_regeneration() -> void:
	var state: SurvivalState = SurvivalState.new()
	# Sprinting drains stamina
	state.tick(2.0, 20.0, true, false, false)
	assert_lt(state.stamina, 100.0)

	# Resting regenerates stamina
	var drained_val: float = state.stamina
	state.tick(1.0, 20.0, false, false, false)
	assert_gt(state.stamina, drained_val)


func test_thermal_transfer_and_hypothermia() -> void:
	var state: SurvivalState = SurvivalState.new()
	# Simulate severe freezing conditions (-25C Ice Wall) for 100 seconds
	for i: int in range(50):
		state.tick(2.0, -25.0, false, false, false)

	assert_lt(state.core_temperature_c, 37.0)
	assert_lt(state.core_temperature_c, SurvivalState.HYPOTHERMIA_TEMP_C)
	# Health should suffer attrition damage from hypothermia
	assert_lt(state.health, 100.0)


func test_underside_freezing_profile() -> void:
	var state: SurvivalState = SurvivalState.new()
	# Underside has no sun, freezing cold
	for i: int in range(30):
		state.tick(2.0, 25.0, false, false, true)

	assert_lt(state.core_temperature_c, 37.0)


func test_consumption_and_nourishment() -> void:
	var state: SurvivalState = SurvivalState.new()
	state.hunger = 40.0
	state.thirst = 30.0
	state.health = 50.0

	# Consume canned beans (+40 food, +10 water, +5 heal)
	state.consume(40.0, 10.0, 5.0, 0.5)

	assert_almost_eq(state.hunger, 80.0, 0.01)
	assert_almost_eq(state.thirst, 40.0, 0.01)
	assert_almost_eq(state.health, 55.0, 0.01)


func test_incapacitation_bleedout_and_revival() -> void:
	var state: SurvivalState = SurvivalState.new()
	# Take lethal 150 damage
	state.apply_damage(150.0)

	assert_almost_eq(state.health, 0.0, 0.01)
	assert_true(state.is_incapacitated)
	assert_false(state.is_dead)

	# Revive player
	var revived: bool = state.revive(40.0)
	assert_true(revived)
	assert_false(state.is_incapacitated)
	assert_almost_eq(state.health, 40.0, 0.01)


func test_bleedout_timeout_results_in_death() -> void:
	var state: SurvivalState = SurvivalState.new()
	state.apply_damage(100.0)
	assert_true(state.is_incapacitated)

	# Bleedout for 35 seconds (> 30s)
	state.tick(35.0, 20.0, false, false, false)
	assert_true(state.is_dead)
	# Dead player cannot be revived
	assert_false(state.revive(50.0))
