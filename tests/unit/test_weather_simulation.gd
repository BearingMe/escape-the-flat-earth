extends GutTest

var _config: WorldConfig
var _sim: WeatherSimulation


func before_each() -> void:
	_config = WorldConfig.new()
	_config.disk_radius_m = 5000.0
	_config.disk_thickness_m = 500.0
	_config.world_seed = 17320508
	_config.max_players = 4
	_config.terrain_chunk_size_m = 128.0
	_config.terrain_cells_per_chunk = 16
	_config.terrain_height_min_m = 0.0
	_config.terrain_height_max_m = 65.0
	_config.terrain_noise_frequency = 0.0015
	_config.terrain_view_radius_chunks = 1
	_config.terrain_edge_falloff_m = 256.0

	_sim = WeatherSimulation.new()
	_sim.configure(_config, _config.world_seed)


func test_barometric_pressure_formula() -> void:
	# Surface altitude y = 250m (thickness/2)
	var sea_level_cond: WeatherCondition = _sim.sample_weather(
		Vector3(0.0, 250.0, 0.0), TerrainBiomeDefinition.Id.PLAINS
	)
	assert_almost_eq(sea_level_cond.pressure_kpa, 101.325, 0.01)

	# Mountain elevation +840m above sea level (y = 1090m)
	# P = 101.325 * exp(-840 / 8400) = 101.325 * exp(-0.1) ~= 91.68 kPa
	var high_cond: WeatherCondition = _sim.sample_weather(
		Vector3(0.0, 1090.0, 0.0), TerrainBiomeDefinition.Id.PLAINS
	)
	assert_almost_eq(high_cond.pressure_kpa, 101.325 * exp(-0.1), 0.05)
	assert_lt(high_cond.pressure_kpa, sea_level_cond.pressure_kpa)


func test_temperature_lapse_rate() -> void:
	var base_cond: WeatherCondition = _sim.sample_weather(
		Vector3(0.0, 250.0, 0.0), TerrainBiomeDefinition.Id.PLAINS
	)
	# 1000m above surface: lapse rate is 6.5 C drop per 1000m
	var high_cond: WeatherCondition = _sim.sample_weather(
		Vector3(0.0, 1250.0, 0.0), TerrainBiomeDefinition.Id.PLAINS
	)
	var temp_diff: float = base_cond.temperature_c - high_cond.temperature_c
	assert_almost_eq(temp_diff, 6.5, 0.01)


func test_biome_climatology_differences() -> void:
	var plains_cond: WeatherCondition = _sim.sample_weather(
		Vector3(0.0, 250.0, 0.0), TerrainBiomeDefinition.Id.PLAINS
	)
	var ice_wall_cond: WeatherCondition = _sim.sample_weather(
		Vector3(4700.0, 250.0, 0.0), TerrainBiomeDefinition.Id.ICE_WALL
	)

	assert_gt(plains_cond.temperature_c, 10.0)
	assert_lt(ice_wall_cond.temperature_c, -20.0)
	assert_gt(ice_wall_cond.wind_velocity.length(), plains_cond.wind_velocity.length())


func test_deterministic_simulation() -> void:
	var sim2: WeatherSimulation = WeatherSimulation.new()
	sim2.configure(_config, _config.world_seed)

	_sim.advance_time(125.0)
	sim2.advance_time(125.0)

	var pos: Vector3 = Vector3(1500.0, 260.0, -800.0)
	var cond1: WeatherCondition = _sim.sample_weather(pos, TerrainBiomeDefinition.Id.FOREST)
	var cond2: WeatherCondition = sim2.sample_weather(pos, TerrainBiomeDefinition.Id.FOREST)

	assert_almost_eq(cond1.temperature_c, cond2.temperature_c, 0.001)
	assert_almost_eq(cond1.humidity, cond2.humidity, 0.001)
	assert_almost_eq(cond1.pressure_kpa, cond2.pressure_kpa, 0.001)
	assert_eq(cond1.precipitation_type, cond2.precipitation_type)
	assert_almost_eq(cond1.precipitation_intensity, cond2.precipitation_intensity, 0.001)


func test_override_controls() -> void:
	_sim.force_weather(WeatherCondition.PrecipitationType.STORM, 0.8)
	assert_true(_sim.is_override_active())

	var cond: WeatherCondition = _sim.sample_weather(Vector3.ZERO, TerrainBiomeDefinition.Id.PLAINS)
	assert_eq(cond.precipitation_type, WeatherCondition.PrecipitationType.STORM)
	assert_almost_eq(cond.precipitation_intensity, 0.8, 0.001)

	_sim.clear_override()
	assert_false(_sim.is_override_active())


func test_state_sync_roundtrip() -> void:
	_sim.advance_time(450.0)
	_sim.force_weather(WeatherCondition.PrecipitationType.BLIZZARD, 0.75)

	var sync_dict: Dictionary = _sim.get_sync_state()

	var client_sim: WeatherSimulation = WeatherSimulation.new()
	client_sim.configure(_config, _config.world_seed)
	client_sim.apply_sync_state(sync_dict)

	assert_almost_eq(client_sim.get_sim_time(), 450.0, 0.01)
	assert_true(client_sim.is_override_active())

	var cond_host: WeatherCondition = _sim.sample_weather(
		Vector3(2000.0, 250.0, 0.0), TerrainBiomeDefinition.Id.TUNDRA
	)
	var cond_client: WeatherCondition = client_sim.sample_weather(
		Vector3(2000.0, 250.0, 0.0), TerrainBiomeDefinition.Id.TUNDRA
	)

	assert_eq(cond_host.precipitation_type, cond_client.precipitation_type)
	assert_almost_eq(cond_host.precipitation_intensity, cond_client.precipitation_intensity, 0.01)
