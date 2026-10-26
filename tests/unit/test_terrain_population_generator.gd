extends GutTest


func test_same_seed_and_chunk_coordinates_produce_same_static_population() -> void:
	var config: WorldConfig = World.config.duplicate(true) as WorldConfig
	var first_generator: TerrainPopulationGenerator = _create_population_generator(config, 918273)
	var second_generator: TerrainPopulationGenerator = _create_population_generator(config, 918273)
	var other_seed_generator: TerrainPopulationGenerator = _create_population_generator(
		config, 918274
	)
	var first: TerrainChunkPopulation = first_generator.build_chunk_population(Vector2i.ZERO)
	var repeated: TerrainChunkPopulation = second_generator.build_chunk_population(Vector2i.ZERO)
	var different_seed: TerrainChunkPopulation = other_seed_generator.build_chunk_population(
		Vector2i.ZERO
	)
	assert_gt(first.size(), 0)
	assert_eq(first.fingerprint, repeated.fingerprint)
	assert_eq(first.cell_coordinates, repeated.cell_coordinates)
	assert_eq(first.stable_ids, repeated.stable_ids)
	assert_eq(first.positions, repeated.positions)
	assert_eq(first.prop_kinds, repeated.prop_kinds)
	assert_ne(first.fingerprint, different_seed.fingerprint)
	assert_ne(first.stable_ids, different_seed.stable_ids)


func test_placements_are_chunk_owned_surface_snapped_slope_limited_and_spawn_safe() -> void:
	var config: WorldConfig = World.config.duplicate(true) as WorldConfig
	var terrain_generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	assert_eq(terrain_generator.configure(config, 556677), OK)
	var population_generator: TerrainPopulationGenerator = TerrainPopulationGenerator.new()
	assert_eq(population_generator.configure(config, terrain_generator, 556677), OK)
	var occupied_cells: Dictionary = {}
	var occupied_ids: Dictionary = {}
	var placement_positions: PackedVector3Array = PackedVector3Array()
	var checked_placements: int = 0
	for chunk_coordinate: Vector2i in [Vector2i.ZERO, Vector2i(1, 0)]:
		var population: TerrainChunkPopulation = population_generator.build_chunk_population(
			chunk_coordinate
		)
		for index: int in range(population.size()):
			var cell: Vector2i = population.cell_coordinates[index]
			var stable_id: String = population.stable_ids[index]
			assert_false(occupied_cells.has(cell), "A border cell was populated by two chunks")
			assert_false(
				occupied_ids.has(stable_id), "A prop identity was duplicated across chunks"
			)
			occupied_cells[cell] = true
			occupied_ids[stable_id] = true
			var position: Vector3 = population.positions[index]
			assert_eq(
				Vector2i(
					floori(position.x / config.terrain_chunk_size_m),
					floori(position.z / config.terrain_chunk_size_m)
				),
				chunk_coordinate
			)
			assert_almost_eq(
				position.y,
				(
					terrain_generator.sample_height(position.x, position.z)
					+ DiskTerrainGenerator.SURFACE_CLEARANCE_M
				),
				0.0001
			)
			assert_gt(Vector2(position.x, position.z).length(), 42.0)
			assert_lt(Vector2(position.x, position.z).length(), config.disk_radius_m - 10.0)
			assert_eq(
				population.biome_ids[index],
				terrain_generator.sample_biome_id(position.x, position.z)
			)
			var max_slope: float = deg_to_rad(
				TerrainPopulationGenerator.MAX_SLOPE_DEGREES[population.prop_kinds[index]]
			)
			assert_lte(population.surface_normals[index].angle_to(Vector3.UP), max_slope + 0.0001)
			assert_true(position.is_finite())
			assert_true(population.surface_normals[index].is_finite())
			placement_positions.append(position)
			checked_placements += 1
	assert_gt(checked_placements, 0)
	for first_index: int in range(placement_positions.size()):
		for second_index: int in range(first_index + 1, placement_positions.size()):
			var first_position: Vector3 = placement_positions[first_index]
			var second_position: Vector3 = placement_positions[second_index]
			assert_gt(
				Vector2(first_position.x, first_position.z).distance_to(
					Vector2(second_position.x, second_position.z)
				),
				8.0,
				"Population placements should retain visible footprint clearance"
			)


func test_biome_profiles_define_distinct_population_pools() -> void:
	assert_eq(TerrainBiomeCatalog.validate(), OK)
	assert_gt(TerrainBiomeCatalog.get_biome(TerrainBiomeDefinition.Id.PLAINS).shrub_density, 0.0)
	assert_gt(TerrainBiomeCatalog.get_biome(TerrainBiomeDefinition.Id.FOREST).tree_density, 0.0)
	assert_gt(TerrainBiomeCatalog.get_biome(TerrainBiomeDefinition.Id.MOUNTAINS).rock_density, 0.0)
	assert_gt(TerrainBiomeCatalog.get_biome(TerrainBiomeDefinition.Id.TUNDRA).debris_density, 0.0)
	assert_gt(
		TerrainBiomeCatalog.get_biome(TerrainBiomeDefinition.Id.ICE_WALL).ice_formation_density, 0.0
	)
	var invalid_profile: TerrainBiomeDefinition = (
		TerrainBiomeCatalog.PLAINS.duplicate(true) as TerrainBiomeDefinition
	)
	invalid_profile.tree_density = 0.8
	invalid_profile.shrub_density = 0.8
	assert_eq(invalid_profile.validate(), ERR_INVALID_DATA)


func _create_population_generator(
	config: WorldConfig, seed_value: int
) -> TerrainPopulationGenerator:
	var terrain_generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	assert_eq(terrain_generator.configure(config, seed_value), OK)
	var population_generator: TerrainPopulationGenerator = TerrainPopulationGenerator.new()
	assert_eq(population_generator.configure(config, terrain_generator, seed_value), OK)
	return population_generator
