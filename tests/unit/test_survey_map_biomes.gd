extends GutTest

var _config: WorldConfig
var _raster: SurveyMapRaster


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

	_raster = SurveyMapRaster.new()
	_raster.configure(_config, _config.world_seed, 64)


func test_chart_image_generation_and_size() -> void:
	var start_usec: int = Time.get_ticks_usec()
	var img: Image = _raster.generate_chart_image()
	var duration_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	assert_not_null(img)
	assert_eq(img.get_width(), 64)
	assert_eq(img.get_height(), 64)
	# Fast generation check (< 100ms even in debug)
	assert_lt(duration_ms, 150.0)


func test_abyss_pixels_are_transparent() -> void:
	var img: Image = _raster.generate_chart_image()
	# Corners are at u = +-1, v = +-1 => r = sqrt(2) > 1.0
	var corner_color: Color = img.get_pixel(0, 0)
	assert_eq(corner_color.a, 0.0)

	var corner_color_br: Color = img.get_pixel(63, 63)
	assert_eq(corner_color_br.a, 0.0)


func test_center_and_inner_pixels_are_opaque() -> void:
	var img: Image = _raster.generate_chart_image()
	var center_color: Color = img.get_pixel(32, 32)
	assert_gt(center_color.a, 0.0)


func test_texture_creation() -> void:
	var tex: ImageTexture = _raster.get_or_create_texture()
	assert_not_null(tex)
	assert_eq(tex.get_width(), 64)
	assert_eq(tex.get_height(), 64)


func test_biome_sampling_consistency_with_terrain_generator() -> void:
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	generator.configure(_config, _config.world_seed)

	var test_points: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(1000.0, 500.0),
		Vector2(-2000.0, 1500.0),
		Vector2(3600.0, 0.0),
		Vector2(0.0, 4700.0),
	]

	for pt: Vector2 in test_points:
		var expected_id: int = generator.sample_biome_id(pt.x, pt.y)
		var raster_id: int = _raster.sample_biome_at_world(pt.x, pt.y)
		assert_eq(raster_id, expected_id, "Biome match at (%.0f, %.0f)" % [pt.x, pt.y])
