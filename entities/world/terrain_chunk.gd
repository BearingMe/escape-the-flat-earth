class_name TerrainChunk
extends StaticBody3D

var _population: TerrainChunkPopulation


func configure(
	chunk_coordinate: Vector2i,
	generator: DiskTerrainGenerator,
	population_generator: TerrainPopulationGenerator
) -> Error:
	if generator == null or population_generator == null or World.config.validate() != OK:
		return ERR_INVALID_PARAMETER
	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_instance == null or collision_shape == null:
		return ERR_UNCONFIGURED
	var terrain_mesh: ArrayMesh = generator.build_chunk_mesh(chunk_coordinate)
	if terrain_mesh == null or terrain_mesh.get_surface_count() == 0:
		return ERR_DOES_NOT_EXIST
	mesh_instance.mesh = terrain_mesh
	mesh_instance.material_override = _terrain_material()
	var generated_collision: ConcavePolygonShape3D = terrain_mesh.create_trimesh_shape()
	if generated_collision == null:
		return ERR_CANT_CREATE
	collision_shape.shape = generated_collision
	_population = population_generator.build_chunk_population(chunk_coordinate)
	if _population.size() > 0:
		var population_view: TerrainPopulationView = TerrainPopulationView.new()
		var population_result: Error = population_view.configure(
			_population, chunk_coordinate, World.config.terrain_chunk_size_m
		)
		if population_result != OK:
			population_view.free()
			return population_result
		population_view.name = "PopulationView"
		add_child(population_view)
	position = Vector3(
		float(chunk_coordinate.x) * World.config.terrain_chunk_size_m,
		World.config.disk_thickness_m * 0.5,
		float(chunk_coordinate.y) * World.config.terrain_chunk_size_m
	)
	return OK


func get_population_data() -> TerrainChunkPopulation:
	return _population


func _terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
