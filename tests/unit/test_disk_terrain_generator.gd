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
	var left_colors: PackedColorArray = left_arrays[Mesh.ARRAY_COLOR]
	var right_colors: PackedColorArray = right_arrays[Mesh.ARRAY_COLOR]
	var stride: int = World.config.terrain_cells_per_chunk + 1
	for z_index: int in range(stride):
		var left_index: int = World.config.terrain_cells_per_chunk * stride + z_index
		assert_almost_eq(left_vertices[left_index].y, right_vertices[z_index].y, 0.000001)
		assert_true(left_normals[left_index].is_equal_approx(right_normals[z_index]))
		assert_true(left_colors[left_index].is_equal_approx(right_colors[z_index]))


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


func test_all_five_biomes_are_reachable_and_perimeter_ice_is_continuous() -> void:
	assert_eq(TerrainBiomeCatalog.validate(), OK)
	var definitions: Array[TerrainBiomeDefinition] = TerrainBiomeCatalog.all_biomes()
	assert_eq(definitions.size(), 5)
	var unique_colors: Dictionary = {}
	for definition: TerrainBiomeDefinition in definitions:
		unique_colors[definition.terrain_color] = true
	assert_eq(unique_colors.size(), definitions.size())
	var malformed_definition: TerrainBiomeDefinition = (
		definitions[0].duplicate(true) as TerrainBiomeDefinition
	)
	malformed_definition.elevation_max_ratio = 1.5
	assert_eq(malformed_definition.validate(), ERR_INVALID_DATA)
	var generator: DiskTerrainGenerator = _create_generator(World.config, World.config.world_seed)
	var observed_biomes: Dictionary = {}
	var sample_step_m: float = World.config.disk_radius_m * 0.05
	for x_step: int in range(-11, 12):
		for z_step: int in range(-11, 12):
			var world_point: Vector2 = Vector2(x_step, z_step) * sample_step_m
			if world_point.length() <= World.config.disk_radius_m * 0.55:
				observed_biomes[generator.sample_biome_id(world_point.x, world_point.y)] = true
	for biome_id: int in range(TerrainBiomeDefinition.Id.MOUNTAINS + 1):
		assert_true(
			observed_biomes.has(biome_id),
			"Biome %d was not found in the interior sample grid" % biome_id
		)
	for angle_step: int in range(32):
		var angle: float = TAU * float(angle_step) / 32.0
		var perimeter_point: Vector2 = (
			Vector2(cos(angle), sin(angle)) * World.config.disk_radius_m * 0.96
		)
		assert_eq(
			generator.sample_biome_id(perimeter_point.x, perimeter_point.y),
			TerrainBiomeDefinition.Id.ICE_WALL
		)
		assert_gt(generator.sample_height(perimeter_point.x, perimeter_point.y), 0.0)
	var tundra_point: Vector2 = Vector2(World.config.disk_radius_m * 0.78, 0.0)
	assert_eq(
		generator.sample_biome_id(tundra_point.x, tundra_point.y), TerrainBiomeDefinition.Id.TUNDRA
	)


func test_biome_weights_are_deterministic_normalized_and_blended_at_boundaries() -> void:
	var first: DiskTerrainGenerator = _create_generator(World.config, 98765)
	var second: DiskTerrainGenerator = _create_generator(World.config, 98765)
	var found_blended_tundra_boundary: bool = false
	var radius: float = World.config.disk_radius_m * 0.66
	for angle_step: int in range(64):
		var angle: float = TAU * float(angle_step) / 64.0
		var world_x: float = cos(angle) * radius
		var world_z: float = sin(angle) * radius
		var weights: PackedFloat32Array = first.sample_biome_weights(world_x, world_z)
		var repeated_weights: PackedFloat32Array = second.sample_biome_weights(world_x, world_z)
		assert_eq(weights.size(), TerrainBiomeDefinition.Id.size())
		assert_true(weights == repeated_weights)
		var total_weight: float = 0.0
		for weight: float in weights:
			assert_gte(weight, 0.0)
			total_weight += weight
		assert_almost_eq(total_weight, 1.0, 0.00001)
		var interior_weight: float = weights[TerrainBiomeDefinition.Id.PLAINS]
		interior_weight += weights[TerrainBiomeDefinition.Id.FOREST]
		interior_weight += weights[TerrainBiomeDefinition.Id.MOUNTAINS]
		if weights[TerrainBiomeDefinition.Id.TUNDRA] > 0.05 and interior_weight > 0.05:
			found_blended_tundra_boundary = true
			var height_before: float = first.sample_height(world_x - 1.0, world_z)
			var height_after: float = first.sample_height(world_x + 1.0, world_z)
			assert_lt(absf(height_after - height_before), 1.0)
	assert_true(found_blended_tundra_boundary)
	assert_eq(first.sample_biome(0.0, 0.0).biome_id, first.sample_biome_id(0.0, 0.0))


func _create_generator(config: WorldConfig, seed_value: int) -> DiskTerrainGenerator:
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	assert_eq(generator.configure(config, seed_value), OK)
	return generator
