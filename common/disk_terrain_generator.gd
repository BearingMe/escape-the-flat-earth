class_name DiskTerrainGenerator
extends RefCounted

const SURFACE_CLEARANCE_M: float = 0.02

var _config: WorldConfig
var _noise: FastNoiseLite


func configure(config: WorldConfig, seed_value: int) -> Error:
	if config == null or config.validate() != OK:
		return ERR_INVALID_PARAMETER
	_config = config.duplicate(true) as WorldConfig
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_noise.frequency = _config.terrain_noise_frequency
	_noise.seed = seed_value
	return OK


func sample_height(world_x: float, world_z: float) -> float:
	if _config == null or _noise == null or not is_finite(world_x) or not is_finite(world_z):
		return 0.0
	var noise_value: float = clampf(_noise.get_noise_2d(world_x, world_z), -1.0, 1.0)
	var height: float = lerpf(
		_config.terrain_height_min_m, _config.terrain_height_max_m, (noise_value + 1.0) * 0.5
	)
	var distance_from_center: float = Vector2(world_x, world_z).length()
	var edge_falloff: float = minf(_config.terrain_edge_falloff_m, _config.disk_radius_m)
	var fade_start: float = _config.disk_radius_m - edge_falloff
	if distance_from_center <= fade_start:
		return height
	var fade_amount: float = clampf((distance_from_center - fade_start) / edge_falloff, 0.0, 1.0)
	var smooth_fade: float = fade_amount * fade_amount * (3.0 - 2.0 * fade_amount)
	return lerpf(height, 0.0, smooth_fade)


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
	if _config == null or _noise == null:
		return null
	var cells: int = _config.terrain_cells_per_chunk
	var stride: int = cells + 1
	var step: float = _config.terrain_chunk_size_m / float(cells)
	var origin_x: float = float(chunk_coordinate.x) * _config.terrain_chunk_size_m
	var origin_z: float = float(chunk_coordinate.y) * _config.terrain_chunk_size_m
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var inside_disk: PackedByteArray = PackedByteArray()
	vertices.resize(stride * stride)
	normals.resize(stride * stride)
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
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func chunk_fingerprint(chunk_coordinate: Vector2i) -> int:
	if _config == null or _noise == null:
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
