extends GutTest


func test_same_seed_and_configuration_produce_identical_samples_and_fingerprints() -> void:
	var first: DiskTerrainGenerator = _create_generator(World.config, 17320508)
	var second: DiskTerrainGenerator = _create_generator(World.config, 17320508)
	assert_almost_eq(
		first.sample_height(120.0, -640.0), second.sample_height(120.0, -640.0), 0.000001
	)
	assert_eq(first.chunk_fingerprint(Vector2i(2, -5)), second.chunk_fingerprint(Vector2i(2, -5)))


func test_different_seeds_produce_different_terrain() -> void:
	var first: DiskTerrainGenerator = _create_generator(World.config, 17320508)
	var second: DiskTerrainGenerator = _create_generator(World.config, 24681357)
	assert_ne(first.chunk_fingerprint(Vector2i(7, -11)), second.chunk_fingerprint(Vector2i(7, -11)))


func test_adjacent_chunk_mesh_edges_share_identical_heights_and_normals() -> void:
	var generator: DiskTerrainGenerator = _create_generator(World.config, 12345)
	var left_mesh: ArrayMesh = generator.build_chunk_mesh(Vector2i(0, 0))
	var right_mesh: ArrayMesh = generator.build_chunk_mesh(Vector2i(1, 0))
	assert_not_null(left_mesh)
	assert_not_null(right_mesh)
	var left_arrays: Array = left_mesh.surface_get_arrays(0)
	var right_arrays: Array = right_mesh.surface_get_arrays(0)
	var left_vertices: PackedVector3Array = left_arrays[Mesh.ARRAY_VERTEX]
	var right_vertices: PackedVector3Array = right_arrays[Mesh.ARRAY_VERTEX]
	var left_normals: PackedVector3Array = left_arrays[Mesh.ARRAY_NORMAL]
	var right_normals: PackedVector3Array = right_arrays[Mesh.ARRAY_NORMAL]
	var stride: int = World.config.terrain_cells_per_chunk + 1
	for z_index: int in range(stride):
		var left_index: int = World.config.terrain_cells_per_chunk * stride + z_index
		assert_almost_eq(left_vertices[left_index].y, right_vertices[z_index].y, 0.000001)
		assert_true(left_normals[left_index].is_equal_approx(right_normals[z_index]))


func test_terrain_height_fades_to_disk_edge_and_mesh_triangles_stay_inside_boundary() -> void:
	var generator: DiskTerrainGenerator = _create_generator(World.config, 8675309)
	assert_almost_eq(generator.sample_height(World.config.disk_radius_m, 0.0), 0.0, 0.000001)
	var chunk_coordinate: Vector2i = Vector2i(35, 15)
	var mesh: ArrayMesh = generator.build_chunk_mesh(chunk_coordinate)
	assert_not_null(mesh)
	var mesh_arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = mesh_arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = mesh_arrays[Mesh.ARRAY_INDEX]
	var origin: Vector2 = Vector2(
		float(chunk_coordinate.x) * World.config.terrain_chunk_size_m,
		float(chunk_coordinate.y) * World.config.terrain_chunk_size_m
	)
	for vertex_index: int in indices:
		var vertex: Vector3 = vertices[vertex_index]
		var world_xz: Vector2 = origin + Vector2(vertex.x, vertex.z)
		assert_lte(world_xz.length(), World.config.disk_radius_m + 0.0001)


func _create_generator(config: WorldConfig, seed_value: int) -> DiskTerrainGenerator:
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	assert_eq(generator.configure(config, seed_value), OK)
	return generator
