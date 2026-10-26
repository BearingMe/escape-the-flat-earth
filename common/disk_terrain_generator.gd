class_name DiskTerrainGenerator
extends RefCounted

const SURFACE_CLEARANCE_M: float = 0.02
const BIOME_WEIGHT_SHARPNESS: float = 3.0
const TUNDRA_START_RATIO: float = 0.66
const TUNDRA_BOUNDARY_VARIATION: float = 0.045
const TUNDRA_TRANSITION_HALF_WIDTH: float = 0.025
const ICE_WALL_START_RATIO: float = 0.91
const ICE_WALL_BOUNDARY_VARIATION: float = 0.012
const ICE_WALL_TRANSITION_HALF_WIDTH: float = 0.01

var _config: WorldConfig
var _height_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _ruggedness_noise: FastNoiseLite
var _boundary_noise: FastNoiseLite
var _mountain_ridge_noise: FastNoiseLite
var _detail_noise: FastNoiseLite
var _biomes: Array[TerrainBiomeDefinition] = []
var _core_biomes: Array[TerrainBiomeDefinition] = []


func configure(config: WorldConfig, seed_value: int) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	if TerrainBiomeCatalog.validate() != OK:
		return ERR_INVALID_DATA
	_config = config.duplicate(true) as WorldConfig
	_biomes = TerrainBiomeCatalog.all_biomes()
	_core_biomes = TerrainBiomeCatalog.core_biomes()
	_height_noise = _create_noise(seed_value ^ 0x13579BDF, _config.terrain_noise_frequency, 4)
	_temperature_noise = _create_noise(
		seed_value ^ 0x2468ACE1, maxf(_config.terrain_noise_frequency * 0.32, 0.00001), 3
	)
	_moisture_noise = _create_noise(
		seed_value ^ 0x31415927, maxf(_config.terrain_noise_frequency * 0.41, 0.00001), 3
	)
	_ruggedness_noise = _create_noise(
		seed_value ^ 0x27182819, maxf(_config.terrain_noise_frequency * 0.52, 0.00001), 3
	)
	_boundary_noise = _create_noise(
		seed_value ^ 0x5A17C3D9, maxf(_config.terrain_noise_frequency * 0.23, 0.00001), 2
	)
	_mountain_ridge_noise = _create_noise(
		seed_value ^ 0x6C8E9CF5, _config.terrain_noise_frequency * 1.35, 4
	)
	_detail_noise = _create_noise(seed_value ^ 0x7F4A7C15, _config.terrain_noise_frequency * 2.1, 2)
	return OK


func _create_noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.frequency = frequency
	noise.seed = seed_value
	return noise


func sample_height(world_x: float, world_z: float) -> float:
	if _config == null or _height_noise == null or not is_finite(world_x) or not is_finite(world_z):
		return 0.0
	var biome_weights: PackedFloat32Array = sample_biome_weights(world_x, world_z)
	var base_height_factor: float = (
		(clampf(_height_noise.get_noise_2d(world_x, world_z), -1.0, 1.0) + 1.0) * 0.5
	)
	var detail_value: float = _detail_noise.get_noise_2d(world_x, world_z)
	var ridge_value: float = 1.0 - absf(_mountain_ridge_noise.get_noise_2d(world_x, world_z))
	var height: float = 0.0
	for biome_index: int in range(_biomes.size()):
		var biome: TerrainBiomeDefinition = _biomes[biome_index]
		var shaped_height: float = clampf(
			base_height_factor + detail_value * biome.detail_strength, 0.0, 1.0
		)
		shaped_height = pow(shaped_height, biome.elevation_curve)
		if biome.biome_id == TerrainBiomeDefinition.Id.MOUNTAINS:
			shaped_height = maxf(shaped_height, ridge_value * 0.82)
		var biome_min_height: float = lerpf(
			_config.terrain_height_min_m, _config.terrain_height_max_m, biome.elevation_min_ratio
		)
		var biome_max_height: float = lerpf(
			_config.terrain_height_min_m, _config.terrain_height_max_m, biome.elevation_max_ratio
		)
		height += (
			biome_weights[biome_index] * lerpf(biome_min_height, biome_max_height, shaped_height)
		)
	var distance_from_center: float = Vector2(world_x, world_z).length()
	var edge_falloff: float = minf(_config.terrain_edge_falloff_m, _config.disk_radius_m)
	var fade_start: float = _config.disk_radius_m - edge_falloff
	if distance_from_center <= fade_start:
		return height
	var fade_amount: float = clampf((distance_from_center - fade_start) / edge_falloff, 0.0, 1.0)
	var smooth_fade: float = fade_amount * fade_amount * (3.0 - 2.0 * fade_amount)
	return lerpf(height, 0.0, smooth_fade)


func sample_biome_weights(world_x: float, world_z: float) -> PackedFloat32Array:
	var weights: PackedFloat32Array = PackedFloat32Array()
	if (
		_config == null
		or _temperature_noise == null
		or not is_finite(world_x)
		or not is_finite(world_z)
	):
		return weights
	var temperature: float = _temperature_noise.get_noise_2d(world_x, world_z)
	var moisture: float = _moisture_noise.get_noise_2d(world_x, world_z)
	var ruggedness: float = (_ruggedness_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
	var core_weights: PackedFloat32Array = PackedFloat32Array()
	var core_total: float = 0.0
	for biome: TerrainBiomeDefinition in _core_biomes:
		var temperature_delta: float = temperature - biome.temperature_preference
		var moisture_delta: float = moisture - biome.moisture_preference
		var ruggedness_delta: float = ruggedness - biome.ruggedness_preference
		var climate_distance: float = (
			pow(temperature_delta, 2.0)
			+ pow(moisture_delta, 2.0)
			+ pow(ruggedness_delta * 1.25, 2.0)
		)
		var core_weight: float = exp(-climate_distance * BIOME_WEIGHT_SHARPNESS)
		core_weights.append(core_weight)
		core_total += core_weight
	if core_total <= 0.0:
		return weights
	for core_index: int in range(core_weights.size()):
		core_weights[core_index] /= core_total

	var radius_ratio: float = Vector2(world_x, world_z).length() / _config.disk_radius_m
	var boundary_noise: float = _boundary_noise.get_noise_2d(world_x, world_z)
	var tundra_start: float = TUNDRA_START_RATIO + boundary_noise * TUNDRA_BOUNDARY_VARIATION
	var ice_wall_start: float = ICE_WALL_START_RATIO + boundary_noise * ICE_WALL_BOUNDARY_VARIATION
	var tundra_coverage: float = _smoothstep(
		tundra_start - TUNDRA_TRANSITION_HALF_WIDTH,
		tundra_start + TUNDRA_TRANSITION_HALF_WIDTH,
		radius_ratio
	)
	var ice_wall_coverage: float = _smoothstep(
		ice_wall_start - ICE_WALL_TRANSITION_HALF_WIDTH,
		ice_wall_start + ICE_WALL_TRANSITION_HALF_WIDTH,
		radius_ratio
	)
	var interior_coverage: float = (1.0 - tundra_coverage) * (1.0 - ice_wall_coverage)
	var tundra_weight: float = tundra_coverage * (1.0 - ice_wall_coverage)
	for core_weight: float in core_weights:
		weights.append(core_weight * interior_coverage)
	weights.append(tundra_weight)
	weights.append(ice_wall_coverage)
	return weights


func sample_biome_id(world_x: float, world_z: float) -> int:
	var weights: PackedFloat32Array = sample_biome_weights(world_x, world_z)
	if weights.size() != _biomes.size():
		return TerrainBiomeDefinition.Id.PLAINS
	var dominant_index: int = 0
	for biome_index: int in range(1, weights.size()):
		if weights[biome_index] > weights[dominant_index]:
			dominant_index = biome_index
	return _biomes[dominant_index].biome_id


func sample_biome(world_x: float, world_z: float) -> TerrainBiomeDefinition:
	return TerrainBiomeCatalog.get_biome(sample_biome_id(world_x, world_z))


func _smoothstep(edge_start: float, edge_end: float, value: float) -> float:
	var amount: float = clampf((value - edge_start) / (edge_end - edge_start), 0.0, 1.0)
	return amount * amount * (3.0 - 2.0 * amount)


func sample_mesh_cell_max_height(world_x: float, world_z: float) -> float:
	if _config == null:
		return 0.0
	var sample_step: float = _config.terrain_chunk_size_m / float(_config.terrain_cells_per_chunk)
	var left_x: float = floorf(world_x / sample_step) * sample_step
	var near_z: float = floorf(world_z / sample_step) * sample_step
	return maxf(
		maxf(sample_height(left_x, near_z), sample_height(left_x + sample_step, near_z)),
		maxf(
			sample_height(left_x, near_z + sample_step),
			sample_height(left_x + sample_step, near_z + sample_step)
		)
	)


func build_chunk_mesh(chunk_coordinate: Vector2i) -> ArrayMesh:
	if _config == null or _height_noise == null:
		return null
	var cells: int = _config.terrain_cells_per_chunk
	var stride: int = cells + 1
	var step: float = _config.terrain_chunk_size_m / float(cells)
	var origin_x: float = float(chunk_coordinate.x) * _config.terrain_chunk_size_m
	var origin_z: float = float(chunk_coordinate.y) * _config.terrain_chunk_size_m
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var inside_disk: PackedByteArray = PackedByteArray()
	vertices.resize(stride * stride)
	normals.resize(stride * stride)
	colors.resize(stride * stride)
	inside_disk.resize(stride * stride)

	for x_index: int in range(stride):
		for z_index: int in range(stride):
			var local_x: float = float(x_index) * step
			var local_z: float = float(z_index) * step
			var world_x: float = origin_x + local_x
			var world_z: float = origin_z + local_z
			var vertex_index: int = x_index * stride + z_index
			vertices[vertex_index] = Vector3(
				local_x, sample_height(world_x, world_z) + SURFACE_CLEARANCE_M, local_z
			)
			var biome_weights: PackedFloat32Array = sample_biome_weights(world_x, world_z)
			var blended_color: Color = Color(0.0, 0.0, 0.0, 0.0)
			for biome_index: int in range(_biomes.size()):
				blended_color += _biomes[biome_index].terrain_color * biome_weights[biome_index]
			colors[vertex_index] = blended_color
			inside_disk[vertex_index] = (
				1
				if Vector2(world_x, world_z).length_squared() <= pow(_config.disk_radius_m, 2.0)
				else 0
			)
			var gradient_x: float = (
				(sample_height(world_x + step, world_z) - sample_height(world_x - step, world_z))
				/ (2.0 * step)
			)
			var gradient_z: float = (
				(sample_height(world_x, world_z + step) - sample_height(world_x, world_z - step))
				/ (2.0 * step)
			)
			normals[vertex_index] = Vector3(-gradient_x, 1.0, -gradient_z).normalized()

	for x_index: int in range(cells):
		for z_index: int in range(cells):
			var index_00: int = x_index * stride + z_index
			var index_10: int = (x_index + 1) * stride + z_index
			var index_01: int = x_index * stride + z_index + 1
			var index_11: int = (x_index + 1) * stride + z_index + 1
			if (
				inside_disk[index_00] == 0
				or inside_disk[index_10] == 0
				or inside_disk[index_01] == 0
				or inside_disk[index_11] == 0
			):
				continue
			indices.append_array(PackedInt32Array([index_00, index_10, index_01]))
			indices.append_array(PackedInt32Array([index_10, index_11, index_01]))

	if indices.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func chunk_fingerprint(chunk_coordinate: Vector2i) -> int:
	if _config == null or _height_noise == null:
		return 0
	var cells: int = _config.terrain_cells_per_chunk
	var step: float = _config.terrain_chunk_size_m / float(cells)
	var origin_x: float = float(chunk_coordinate.x) * _config.terrain_chunk_size_m
	var origin_z: float = float(chunk_coordinate.y) * _config.terrain_chunk_size_m
	var fingerprint: int = 17
	for x_index: int in range(cells + 1):
		for z_index: int in range(cells + 1):
			var sampled_height: int = roundi(
				(
					sample_height(
						origin_x + float(x_index) * step, origin_z + float(z_index) * step
					)
					* 1000.0
				)
			)
			fingerprint = (fingerprint * 31 + sampled_height) % 2147483647
			fingerprint = (
				(
					fingerprint * 31
					+ sample_biome_id(
						origin_x + float(x_index) * step, origin_z + float(z_index) * step
					)
				)
				% 2147483647
			)
	return fingerprint


static func chunk_intersects_disk(chunk_coordinate: Vector2i, config: WorldConfig) -> bool:
	if config == null or config.validate() != OK:
		return false
	var left: float = float(chunk_coordinate.x) * config.terrain_chunk_size_m
	var right: float = left + config.terrain_chunk_size_m
	var top: float = float(chunk_coordinate.y) * config.terrain_chunk_size_m
	var bottom: float = top + config.terrain_chunk_size_m
	var nearest_x: float = clampf(0.0, left, right)
	var nearest_z: float = clampf(0.0, top, bottom)
	return Vector2(nearest_x, nearest_z).length_squared() < pow(config.disk_radius_m, 2.0)
