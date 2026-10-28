extends GutTest


func test_momentum_calculation() -> void:
	assert_almost_eq(ImpactDamageModel.calculate_momentum(10.0, 5.0), 50.0, 0.01)
	assert_almost_eq(ImpactDamageModel.calculate_momentum(0.0, 10.0), 0.0, 0.01)
	assert_almost_eq(ImpactDamageModel.calculate_momentum(-5.0, 10.0), 0.0, 0.01)


func test_impact_damage_threshold() -> void:
	# Momentum = 15 kg * 1.0 m/s = 15 kg*m/s < threshold (24) -> 0 damage
	var light_impact: float = ImpactDamageModel.calculate_impact_damage(15.0, 1.0)
	assert_almost_eq(light_impact, 0.0, 0.01)

	# Momentum = 20 kg * 5.0 m/s = 100 kg*m/s > threshold (24)
	# Expected = (100 - 24) * 0.06 = 4.56
	var med_impact: float = ImpactDamageModel.calculate_impact_damage(20.0, 5.0)
	assert_almost_eq(med_impact, 4.56, 0.01)


func test_impact_damage_cap() -> void:
	# Massive boulder at high speed: 500 kg * 50 m/s = 25,000 kg*m/s
	var massive_impact: float = ImpactDamageModel.calculate_impact_damage(500.0, 50.0)
	assert_almost_eq(massive_impact, ImpactDamageModel.MAX_DAMAGE_CAP, 0.01)


func test_throw_velocity_mass_scaling() -> void:
	var forward: Vector3 = Vector3(0.0, 0.0, -1.0)
	var player_vel: Vector3 = Vector3(2.0, 0.0, 0.0)

	var light_vel: Vector3 = ImpactDamageModel.calculate_throw_velocity(
		forward, player_vel, 20.0, 5.0
	)
	var heavy_vel: Vector3 = ImpactDamageModel.calculate_throw_velocity(
		forward, player_vel, 20.0, 80.0
	)

	# Light prop should be thrown significantly faster than heavy prop
	assert_gt(light_vel.length(), heavy_vel.length())
	# Inherits half of thrower velocity
	assert_almost_eq(light_vel.x, 1.0, 0.01)
	assert_almost_eq(heavy_vel.x, 1.0, 0.01)
