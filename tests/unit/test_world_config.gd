extends GutTest


func test_default_world_resource_has_valid_disc_and_session_dimensions() -> void:
	var config: WorldConfig = load("res://common/data/world_default.tres") as WorldConfig
	assert_not_null(config)
	assert_eq(config.validate(), OK)
	assert_eq(config.disk_radius_m, 5000.0)
	assert_eq(config.disk_thickness_m, 500.0)
	assert_eq(config.max_players, 6)
	assert_eq(config.terrain_chunk_size_m, 128.0)
	assert_eq(config.terrain_cells_per_chunk, 16)
	assert_eq(config.terrain_height_max_m, 65.0)
	assert_eq(ProjectSettings.get_setting("physics/3d/default_gravity"), 9.8)
	assert_eq(
		ProjectSettings.get_setting("physics/3d/default_gravity_vector"), Vector3(0.0, -1.0, 0.0)
	)


func test_invalid_world_dimensions_and_player_cap_are_rejected() -> void:
	var config: WorldConfig = WorldConfig.new()
	config.disk_radius_m = 0.0
	assert_eq(config.validate(), ERR_INVALID_PARAMETER)
	config.disk_radius_m = 5000.0
	config.disk_thickness_m = INF
	assert_eq(config.validate(), ERR_INVALID_PARAMETER)
	config.disk_thickness_m = 500.0
	config.max_players = 7
	assert_eq(config.validate(), ERR_INVALID_PARAMETER)
	config.max_players = 6
	config.terrain_height_max_m = config.terrain_height_min_m
	assert_eq(config.validate(), ERR_INVALID_PARAMETER)


func test_world_config_dictionary_round_trip_is_complete_and_validated() -> void:
	var config: WorldConfig = World.config.duplicate(true) as WorldConfig
	config.world_seed = 24680
	var reconstructed: WorldConfig = WorldConfig.from_dictionary(config.to_dictionary())
	assert_not_null(reconstructed)
	assert_eq(reconstructed.to_dictionary(), config.to_dictionary())
	var malformed: Dictionary = config.to_dictionary()
	malformed["terrain_cells_per_chunk"] = 1
	assert_null(WorldConfig.from_dictionary(malformed))
	malformed = config.to_dictionary()
	malformed["world_seed"] = "not-a-seed"
	assert_null(WorldConfig.from_dictionary(malformed))
