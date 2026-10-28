extends GutTest

const MINIMAP_SCENE: PackedScene = preload("res://ui/map/minimap.tscn")

var _minimap: MinimapHUD
var _player: Node3D
var _config: WorldConfig


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

	_player = Node3D.new()
	_player.name = "TestPlayer"
	_player.position = Vector3(0.0, 250.0, 0.0)
	add_child_autofree(_player)

	_minimap = MINIMAP_SCENE.instantiate() as MinimapHUD
	add_child_autofree(_minimap)
	_minimap.configure_world(_config, _config.world_seed)
	_minimap.bind_player(_player)


func test_initial_telemetry_at_origin() -> void:
	_minimap._process(0.016)
	var telemetry: Dictionary = _minimap.get_telemetry()
	assert_almost_eq(float(telemetry.get("position_x", -1.0)), 0.0, 0.1)
	assert_almost_eq(float(telemetry.get("position_z", -1.0)), 0.0, 0.1)
	assert_almost_eq(float(telemetry.get("heading_deg", -1.0)), 0.0, 0.1)
	assert_eq(telemetry.get("cardinal", ""), "N")

	var zone_info: Dictionary = telemetry.get("zone_info", {})
	assert_eq(zone_info.get("zone", -1), SurveyMapProjection.TraversalZone.INTERIOR)
	assert_false(zone_info.get("is_off_disk", true))
	assert_false(zone_info.get("is_underside", true))


func test_telemetry_updates_with_movement_and_heading() -> void:
	_player.position = Vector3(100.0, 255.0, -200.0)
	# Yaw = -PI/2 (looking East)
	_player.rotation.y = -PI * 0.5

	_minimap._process(0.016)
	var telemetry: Dictionary = _minimap.get_telemetry()
	assert_almost_eq(float(telemetry.get("position_x", 0.0)), 100.0, 0.1)
	assert_almost_eq(float(telemetry.get("position_z", 0.0)), -200.0, 0.1)
	assert_almost_eq(float(telemetry.get("heading_deg", 0.0)), 90.0, 0.1)
	assert_eq(telemetry.get("cardinal", ""), "E")


func test_traversal_zone_transitions() -> void:
	# 1. Tundra
	_player.position = Vector3(3600.0, 250.0, 0.0)
	_minimap._process(0.016)
	var telemetry_tundra: Dictionary = _minimap.get_telemetry()
	var zone_tundra: Dictionary = telemetry_tundra.get("zone_info", {})
	assert_eq(zone_tundra.get("zone", -1), SurveyMapProjection.TraversalZone.TUNDRA)

	# 2. Ice Wall Rim
	_player.position = Vector3(4700.0, 250.0, 0.0)
	_minimap._process(0.016)
	var telemetry_rim: Dictionary = _minimap.get_telemetry()
	var zone_rim: Dictionary = telemetry_rim.get("zone_info", {})
	assert_eq(zone_rim.get("zone", -1), SurveyMapProjection.TraversalZone.ICE_WALL)

	# 3. Off-disk Abyss
	_player.position = Vector3(5100.0, 100.0, 0.0)
	_minimap._process(0.016)
	var telemetry_abyss: Dictionary = _minimap.get_telemetry()
	var zone_abyss: Dictionary = telemetry_abyss.get("zone_info", {})
	assert_eq(zone_abyss.get("zone", -1), SurveyMapProjection.TraversalZone.ABYSS)
	assert_true(zone_abyss.get("is_off_disk", false))

	# 4. Underside
	_player.position = Vector3(0.0, -300.0, 0.0)
	_minimap._process(0.016)
	var telemetry_under: Dictionary = _minimap.get_telemetry()
	var zone_under: Dictionary = telemetry_under.get("zone_info", {})
	assert_eq(zone_under.get("zone", -1), SurveyMapProjection.TraversalZone.UNDERSIDE)
	assert_true(zone_under.get("is_underside", false))


func test_zoom_cycling() -> void:
	assert_eq(_minimap.current_zoom, SurveyMapProjection.ZoomLevel.LOCAL_NEAR)
	_minimap.cycle_zoom()
	assert_eq(_minimap.current_zoom, SurveyMapProjection.ZoomLevel.LOCAL_FAR)
	_minimap.cycle_zoom()
	assert_eq(_minimap.current_zoom, SurveyMapProjection.ZoomLevel.FULL_DISK)
	_minimap.cycle_zoom()
	assert_eq(_minimap.current_zoom, SurveyMapProjection.ZoomLevel.LOCAL_NEAR)


func test_rotation_mode_toggling() -> void:
	assert_eq(_minimap.rotation_mode, SurveyMapProjection.RotationMode.HEADING_UP)
	_minimap.toggle_rotation_mode()
	assert_eq(_minimap.rotation_mode, SurveyMapProjection.RotationMode.NORTH_UP)
	_minimap.toggle_rotation_mode()
	assert_eq(_minimap.rotation_mode, SurveyMapProjection.RotationMode.HEADING_UP)


func test_fullscreen_map_toggle() -> void:
	assert_false(_minimap.is_fullscreen_open())
	_minimap.toggle_fullscreen_map()
	assert_true(_minimap.is_fullscreen_open())
	_minimap.toggle_fullscreen_map()
	assert_false(_minimap.is_fullscreen_open())


func test_teammate_marker_registration_and_removal() -> void:
	var teammate_pos: Vector3 = Vector3(50.0, 250.0, 50.0)
	var pos_cb: Callable = func() -> Vector3: return teammate_pos

	_minimap.register_teammate(2, "Teammate_2", pos_cb)
	assert_true(_minimap._teammates.has(2))

	_minimap.unregister_teammate(2)
	assert_false(_minimap._teammates.has(2))
