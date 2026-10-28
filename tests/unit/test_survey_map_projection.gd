extends GutTest

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


func test_world_to_normalized_disk_conversion() -> void:
	var center: Vector2 = SurveyMapProjection.world_to_normalized_disk(Vector3.ZERO, 5000.0)
	assert_eq(center, Vector2.ZERO)

	var rim_east: Vector2 = SurveyMapProjection.world_to_normalized_disk(
		Vector3(5000.0, 0.0, 0.0), 5000.0
	)
	assert_almost_eq(rim_east.x, 1.0, 0.0001)
	assert_almost_eq(rim_east.y, 0.0, 0.0001)

	var rim_south: Vector2 = SurveyMapProjection.world_to_normalized_disk(
		Vector3(0.0, 0.0, 5000.0), 5000.0
	)
	assert_almost_eq(rim_south.x, 0.0, 0.0001)
	assert_almost_eq(rim_south.y, 1.0, 0.0001)


func test_normalized_disk_to_world_conversion() -> void:
	var world_pt: Vector3 = SurveyMapProjection.normalized_disk_to_world(
		Vector2(0.5, -0.5), 5000.0, 250.0
	)
	assert_almost_eq(world_pt.x, 2500.0, 0.001)
	assert_almost_eq(world_pt.y, 250.0, 0.001)
	assert_almost_eq(world_pt.z, -2500.0, 0.001)


func test_yaw_to_heading_degrees() -> void:
	assert_almost_eq(SurveyMapProjection.yaw_to_heading_degrees(0.0), 0.0, 0.01)
	assert_eq(
		SurveyMapProjection.heading_degrees_to_cardinal(
			SurveyMapProjection.yaw_to_heading_degrees(0.0)
		),
		"N"
	)

	# In Godot, turning right means negative yaw (-PI/2)
	assert_almost_eq(SurveyMapProjection.yaw_to_heading_degrees(-PI * 0.5), 90.0, 0.01)
	assert_eq(
		SurveyMapProjection.heading_degrees_to_cardinal(
			SurveyMapProjection.yaw_to_heading_degrees(-PI * 0.5)
		),
		"E"
	)

	assert_almost_eq(SurveyMapProjection.yaw_to_heading_degrees(PI), 180.0, 0.01)
	assert_eq(
		SurveyMapProjection.heading_degrees_to_cardinal(
			SurveyMapProjection.yaw_to_heading_degrees(PI)
		),
		"S"
	)

	assert_almost_eq(SurveyMapProjection.yaw_to_heading_degrees(PI * 0.5), 270.0, 0.01)
	assert_eq(
		SurveyMapProjection.heading_degrees_to_cardinal(
			SurveyMapProjection.yaw_to_heading_degrees(PI * 0.5)
		),
		"W"
	)


func test_evaluate_traversal_zone() -> void:
	# Center basin
	var center_eval: Dictionary = SurveyMapProjection.evaluate_traversal_zone(
		Vector3(0.0, 250.0, 0.0), _config
	)
	assert_eq(center_eval["zone"], SurveyMapProjection.TraversalZone.INTERIOR)
	assert_false(center_eval["is_off_disk"])
	assert_false(center_eval["is_underside"])

	# Tundra (r = 3500m, ratio = 0.70)
	var tundra_eval: Dictionary = SurveyMapProjection.evaluate_traversal_zone(
		Vector3(3500.0, 250.0, 0.0), _config
	)
	assert_eq(tundra_eval["zone"], SurveyMapProjection.TraversalZone.TUNDRA)

	# Ice Wall (r = 4700m, ratio = 0.94)
	var ice_wall_eval: Dictionary = SurveyMapProjection.evaluate_traversal_zone(
		Vector3(4700.0, 250.0, 0.0), _config
	)
	assert_eq(ice_wall_eval["zone"], SurveyMapProjection.TraversalZone.ICE_WALL)

	# Off disk in Abyss (r = 5200m)
	var abyss_eval: Dictionary = SurveyMapProjection.evaluate_traversal_zone(
		Vector3(5200.0, 0.0, 0.0), _config
	)
	assert_eq(abyss_eval["zone"], SurveyMapProjection.TraversalZone.ABYSS)
	assert_true(abyss_eval["is_off_disk"])

	# Underside (y = -300m, disk thickness = 500m -> underside_y = -250m)
	var underside_eval: Dictionary = SurveyMapProjection.evaluate_traversal_zone(
		Vector3(100.0, -300.0, 100.0), _config
	)
	assert_eq(underside_eval["zone"], SurveyMapProjection.TraversalZone.UNDERSIDE)
	assert_true(underside_eval["is_underside"])


func test_world_to_map_point_north_up_and_heading_up() -> void:
	var map_size: Vector2 = Vector2(200.0, 200.0)
	var center: Vector3 = Vector3(1000.0, 0.0, 1000.0)
	var target: Vector3 = Vector3(1500.0, 0.0, 1000.0)  # 500m East (+X)
	var view_radius: float = 1000.0

	# North up: +X should map to +X on map
	var pt_north: Vector2 = SurveyMapProjection.world_to_map_point(
		target, center, view_radius, map_size, SurveyMapProjection.RotationMode.NORTH_UP, 0.0
	)
	assert_almost_eq(pt_north.x, 150.0, 0.01)
	assert_almost_eq(pt_north.y, 100.0, 0.01)

	# Heading up looking East (yaw = -PI/2): East (+X) is forward (-Y on screen)
	var pt_heading: Vector2 = SurveyMapProjection.world_to_map_point(
		target,
		center,
		view_radius,
		map_size,
		SurveyMapProjection.RotationMode.HEADING_UP,
		-PI * 0.5
	)
	# Delta is (500, 0). Rotated by -PI/2: (500 * cos(-PI/2) - 0, 500 * sin(-PI/2)) = (0, -500)
	# So offset is (0, -50px), map point is (100, 50)
	assert_almost_eq(pt_heading.x, 100.0, 0.1)
	assert_almost_eq(pt_heading.y, 50.0, 0.1)
