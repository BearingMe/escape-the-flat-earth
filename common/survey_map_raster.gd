class_name SurveyMapRaster
extends RefCounted

const DEFAULT_RESOLUTION: int = 256
const COLOR_VOID: Color = Color(0.02, 0.03, 0.05, 0.0)
const COLOR_RIM_LINE: Color = Color(0.85, 0.92, 1.0, 0.9)
const COLOR_GRID_LINE: Color = Color(0.2, 0.35, 0.45, 0.35)
const COLOR_TROPIC_LINE: Color = Color(0.35, 0.5, 0.6, 0.4)
const COLOR_POLE: Color = Color(0.9, 0.85, 0.5, 0.8)

var _config: WorldConfig
var _seed_value: int = 0
var _resolution: int = DEFAULT_RESOLUTION
var _generator: DiskTerrainGenerator
var _cached_image: Image
var _cached_texture: ImageTexture


func configure(config: WorldConfig, seed_value: int, resolution: int = DEFAULT_RESOLUTION) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	if resolution < 32 or resolution > 1024:
		return ERR_INVALID_PARAMETER

	_config = config.duplicate(true) as WorldConfig
	_seed_value = seed_value
	_resolution = resolution
	_generator = DiskTerrainGenerator.new()
	var gen_err: Error = _generator.configure(_config, _seed_value)
	if gen_err != OK:
		return gen_err

	return OK


func generate_chart_image() -> Image:
	if _generator == null:
		return null

	var img: Image = Image.create_empty(_resolution, _resolution, false, Image.FORMAT_RGBA8)
	var half_res: float = float(_resolution) * 0.5
	var inv_half_res: float = 1.0 / half_res

	for y: int in range(_resolution):
		var v: float = (float(y) + 0.5 - half_res) * inv_half_res
		for x: int in range(_resolution):
			var u: float = (float(x) + 0.5 - half_res) * inv_half_res
			var radial_ratio: float = sqrt(u * u + v * v)

			if radial_ratio > 1.0:
				img.set_pixel(x, y, COLOR_VOID)
				continue

			var world_x: float = u * _config.disk_radius_m
			var world_z: float = v * _config.disk_radius_m

			var biome_id: int = _generator.sample_biome_id(world_x, world_z)
			var biome_def: TerrainBiomeDefinition = TerrainBiomeCatalog.get_biome(biome_id)
			var base_color: Color = (
				biome_def.terrain_color if biome_def != null else Color.DARK_GRAY
			)

			base_color.a = 1.0
			var pixel_color: Color = base_color

			if absf(radial_ratio - 1.0) < (1.5 * inv_half_res):
				pixel_color = pixel_color.lerp(COLOR_RIM_LINE, 0.85)
			elif absf(radial_ratio - SurveyMapProjection.ICE_WALL_RATIO) < (1.2 * inv_half_res):
				pixel_color = pixel_color.lerp(COLOR_RIM_LINE, 0.65)
			elif (
				absf(radial_ratio - SurveyMapProjection.TUNDRA_RATIO) < (1.0 * inv_half_res)
				or absf(radial_ratio - 0.5) < (1.0 * inv_half_res)
			):
				pixel_color = pixel_color.lerp(COLOR_TROPIC_LINE, 0.5)
			elif radial_ratio < (3.0 * inv_half_res):
				pixel_color = pixel_color.lerp(COLOR_POLE, 0.75)
			else:
				var angle: float = atan2(v, u)
				var angle_step: float = TAU / 12.0
				var mod_angle: float = absf(fmod(angle + PI, angle_step))
				if mod_angle < (0.8 * inv_half_res / maxf(radial_ratio, 0.1)):
					pixel_color = pixel_color.lerp(COLOR_GRID_LINE, 0.3)

			img.set_pixel(x, y, pixel_color)

	_cached_image = img
	return img


func get_or_create_texture() -> ImageTexture:
	if _cached_texture != null:
		return _cached_texture
	var img: Image = _cached_image
	if img == null:
		img = generate_chart_image()
	if img == null:
		return null
	_cached_texture = ImageTexture.create_from_image(img)
	return _cached_texture


func sample_biome_at_world(world_x: float, world_z: float) -> int:
	if _generator == null:
		return TerrainBiomeDefinition.Id.PLAINS
	return _generator.sample_biome_id(world_x, world_z)
