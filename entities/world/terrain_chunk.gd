class_name TerrainChunk
extends StaticBody3D


func configure(chunk_coordinate: Vector2i, generator: DiskTerrainGenerator) -> Error:
	if generator == null or World.config.validate() != OK:
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
	position = Vector3(
		float(chunk_coordinate.x) * World.config.terrain_chunk_size_m,
		World.config.disk_thickness_m * 0.5,
		float(chunk_coordinate.y) * World.config.terrain_chunk_size_m
	)
	return OK


func _terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#718f45")
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
