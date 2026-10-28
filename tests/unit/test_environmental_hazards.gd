extends GutTest


func test_wind_push_force_threshold_and_scaling() -> void:
	# Wind speed 4 m/s (< 6 m/s threshold) -> 0 push force
	var light_wind: Vector3 = Vector3(4.0, 0.0, 0.0)
	var push_light: Vector3 = EnvironmentalHazardModel.calculate_wind_push_force(light_wind)
	assert_almost_eq(push_light.length(), 0.0, 0.01)

	# Wind speed 16 m/s (> 6 m/s threshold) -> push force = (16 - 6) * 22 = 220 N
	var gale_wind: Vector3 = Vector3(16.0, 0.0, 0.0)
	var push_gale: Vector3 = EnvironmentalHazardModel.calculate_wind_push_force(gale_wind, 1.0)
	assert_almost_eq(push_gale.x, 220.0, 0.01)

	# In shelter (exposure = 0.2) -> 220 * 0.2 = 44 N
	var push_shelter: Vector3 = EnvironmentalHazardModel.calculate_wind_push_force(gale_wind, 0.2)
	assert_almost_eq(push_shelter.x, 44.0, 0.01)


func test_frostbite_damage_and_mitigation() -> void:
	# Mild weather (10C) -> 0 damage
	var dmg_mild: float = EnvironmentalHazardModel.calculate_frostbite_damage(
		10.0, false, false, 1.0
	)
	assert_almost_eq(dmg_mild, 0.0, 0.01)

	# Severe cold (-30C): severity = abs(-30 - -10) = 20. Rate = 20 * 0.25 = 5.0 dmg/sec
	var dmg_cold: float = EnvironmentalHazardModel.calculate_frostbite_damage(
		-30.0, false, false, 2.0
	)
	assert_almost_eq(dmg_cold, 10.0, 0.01)

	# With thermal gear (80% mitigation) -> 10.0 * 0.2 = 2.0 dmg
	var dmg_geared: float = EnvironmentalHazardModel.calculate_frostbite_damage(
		-30.0, true, false, 2.0
	)
	assert_almost_eq(dmg_geared, 2.0, 0.01)

	# In shelter -> 0 damage
	var dmg_sheltered: float = EnvironmentalHazardModel.calculate_frostbite_damage(
		-30.0, false, true, 2.0
	)
	assert_almost_eq(dmg_sheltered, 0.0, 0.01)


func test_firmament_barrier_damage() -> void:
	var center: Vector2 = Vector2.ZERO
	var radius: float = 3000.0

	# Inside safe zone (r = 2000m) -> 0 damage
	var dmg_inside: float = EnvironmentalHazardModel.calculate_firmament_barrier_damage(
		Vector3(2000.0, 0.0, 0.0), center, radius, 1.0
	)
	assert_almost_eq(dmg_inside, 0.0, 0.01)
	assert_true(
		EnvironmentalHazardModel.is_inside_safe_zone(Vector3(2000.0, 0.0, 0.0), center, radius)
	)

	# Outside safe zone (r = 3100m, depth = 100m) -> rate = 2.5 + (100 * 0.04) = 6.5 dmg/sec
	var dmg_outside: float = EnvironmentalHazardModel.calculate_firmament_barrier_damage(
		Vector3(3100.0, 0.0, 0.0), center, radius, 2.0
	)
	assert_almost_eq(dmg_outside, 13.0, 0.01)
	assert_false(
		EnvironmentalHazardModel.is_inside_safe_zone(Vector3(3100.0, 0.0, 0.0), center, radius)
	)
