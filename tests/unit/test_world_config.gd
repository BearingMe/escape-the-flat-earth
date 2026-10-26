extends GutTest


func test_default_world_resource_has_valid_disc_and_session_dimensions() -> void:
	var config: WorldConfig = load("res://common/data/world_default.tres") as WorldConfig
	assert_not_null(config)
	assert_eq(config.validate(), OK)
	assert_eq(config.disk_radius_m, 5000.0)
	assert_eq(config.disk_thickness_m, 500.0)
	assert_eq(config.max_players, 6)
	assert_eq(ProjectSettings.get_setting("physics/3d/default_gravity"), 0.0)


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
