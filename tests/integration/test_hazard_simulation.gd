extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _player: ObserverPlayer


func before_each() -> void:
	World.set_seed(17320508)
	_player = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player.configure(1, "player_1_1", "TestSubject")
	_player.position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(_player)


func test_hazard_system_barrier_contraction_and_damage() -> void:
	var hazards: HazardSystem = HazardSystem.new()
	# Fast 10-second contraction from 1000m to 100m
	hazards.configure(1000.0, 100.0, 10.0, Vector2.ZERO)

	assert_almost_eq(hazards.get_current_barrier_radius(), 1000.0, 0.01)

	# Player stands at x = 500m
	_player.position = Vector3(500.0, 0.0, 0.0)

	var weather: WeatherCondition = WeatherCondition.new()
	weather.temperature_c = 15.0

	# Advance hazards 10 seconds -> barrier shrinks to 100m
	hazards.advance_time(10.0)
	assert_almost_eq(hazards.get_current_barrier_radius(), 100.0, 0.01)

	# Now player is 400m deep outside the barrier
	var initial_health: float = _player.health
	var eval: Dictionary = hazards.evaluate_player_hazards(_player, weather, 1.0)

	assert_true(eval["in_storm"])
	assert_gt(float(eval["damage"]), 0.0)
	assert_lt(_player.health, initial_health)


func test_frostbite_mitigation_with_thermal_inventory_item() -> void:
	var hazards: HazardSystem = HazardSystem.new()
	hazards.configure(5000.0, 5000.0, 100.0, Vector2.ZERO)

	var freezing_weather: WeatherCondition = WeatherCondition.new()
	freezing_weather.temperature_c = -30.0

	# Without thermal wrap: takes full frostbite
	var initial_health: float = _player.health
	hazards.evaluate_player_hazards(_player, freezing_weather, 1.0)
	var dmg_unprotected: float = initial_health - _player.health
	assert_gt(dmg_unprotected, 0.0)

	# Add thermal insulation wrap to inventory
	_player.inventory.add_item("thermal_insulation", 1, 10, 1.0)
	_player.health = 100.0
	_player.survival.health = 100.0

	hazards.evaluate_player_hazards(_player, freezing_weather, 1.0)
	var dmg_protected: float = 100.0 - _player.health
	assert_lt(dmg_protected, dmg_unprotected * 0.3)
