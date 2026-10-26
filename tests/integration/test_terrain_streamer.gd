extends GutTest

const TERRAIN_STREAMER_SCENE: PackedScene = preload("res://entities/world/terrain_streamer.tscn")
const DISK_SCENE: PackedScene = preload("res://entities/world/disk.tscn")

var _original_world_config: WorldConfig
var _original_session_role: String
var _active_observer: ObserverPlayer


func before_each() -> void:
	_original_world_config = World.config
	_original_session_role = Net.session_role
	World.config = World.config.duplicate(true) as WorldConfig
	World.config.terrain_cells_per_chunk = 4
	World.config.terrain_view_radius_chunks = 0


func after_each() -> void:
	if Net.session_role == "host":
		World.clear_static_prop_registry()
	Net.session_role = _original_session_role
	World.config = _original_world_config
	_active_observer = null


func _physics_process(delta: float) -> void:
	if is_instance_valid(_active_observer):
		_active_observer._simulate_authoritative_movement(delta)


func test_streamer_loads_separate_regions_and_unloads_distant_chunks() -> void:
	var streamer: TerrainStreamer = TERRAIN_STREAMER_SCENE.instantiate() as TerrainStreamer
	autofree(streamer)
	add_child(streamer)
	assert_eq(streamer.configure_host_world(), OK)
	streamer.update_streaming_for_positions(
		[Vector3(10.0, 0.0, 10.0), Vector3(1040.0, 0.0, 1040.0)]
	)
	assert_eq(streamer.get_loaded_chunk_count(), 2)
	assert_true(streamer.get_loaded_chunk_coordinates().has(Vector2i(0, 0)))
	assert_true(streamer.get_loaded_chunk_coordinates().has(Vector2i(8, 8)))
	streamer.update_streaming_for_positions([Vector3(10.0, 0.0, 10.0)])
	assert_eq(streamer.get_loaded_chunk_count(), 1)
	assert_eq(streamer.get_loaded_chunk_coordinates(), [Vector2i(0, 0)])


func test_desired_chunks_are_deduplicated_for_players_in_shared_region() -> void:
	var desired: Array[Vector2i] = TerrainStreamer.desired_chunk_coordinates(
		[Vector3(10.0, 0.0, 10.0), Vector3(40.0, 20.0, 50.0)], World.config
	)
	assert_eq(desired, [Vector2i(0, 0)])
	var distant: Array[Vector2i] = TerrainStreamer.desired_chunk_coordinates(
		[Vector3(10.0, 0.0, 10.0), Vector3(1040.0, 20.0, 1040.0)], World.config
	)
	assert_eq(distant.size(), 2)
	assert_true(distant.has(Vector2i(0, 0)))
	assert_true(distant.has(Vector2i(8, 8)))


func test_chunk_population_batches_and_host_registry_follow_streaming() -> void:
	World.set_seed(17320508)
	Net.session_role = "host"
	var streamer: TerrainStreamer = TERRAIN_STREAMER_SCENE.instantiate() as TerrainStreamer
	autofree(streamer)
	streamer.set_process(false)
	add_child(streamer)
	assert_eq(streamer.configure_host_world(), OK)
	var original_fingerprint: int = streamer.get_population_fingerprint(Vector2i.ZERO)
	var original_population_count: int = streamer.get_population_count(Vector2i.ZERO)
	assert_gt(original_population_count, 0)
	streamer.update_streaming_for_positions([Vector3(10.0, 0.0, 10.0)])
	var original_chunk: TerrainChunk = streamer.get_node("Chunk_0_0") as TerrainChunk
	assert_not_null(original_chunk)
	if World.has_host_authority():
		assert_eq(World.get_active_static_prop_count(), original_population_count)
		var first_prop_id: String = original_chunk.get_population_data().stable_ids[0]
		var first_prop_record: Dictionary = World.get_active_static_prop_record(first_prop_id)
		assert_eq(first_prop_record.get("state"), "static")
		assert_eq(first_prop_record.get("chunk"), Vector2i.ZERO)
	var population_view: TerrainPopulationView = (
		original_chunk.get_node("PopulationView") as TerrainPopulationView
	)
	assert_not_null(population_view)
	assert_gt(population_view.get_child_count(), 0)
	for visual_batch: Node in population_view.get_children():
		assert_true(visual_batch is MultiMeshInstance3D)
		assert_gt((visual_batch as MultiMeshInstance3D).multimesh.instance_count, 0)
	streamer.update_streaming_for_positions([Vector3(1040.0, 0.0, 1040.0)])
	assert_eq(streamer.get_loaded_chunk_coordinates(), [Vector2i(8, 8)])
	assert_true(original_chunk.is_queued_for_deletion())
	assert_eq(streamer.get_loaded_chunk_count(), 1)
	assert_not_null(streamer.get_node_or_null("Chunk_8_8"))
	if World.has_host_authority():
		assert_eq(
			World.get_active_static_prop_count(), streamer.get_population_count(Vector2i(8, 8))
		)
	assert_eq(streamer.get_population_fingerprint(Vector2i.ZERO), original_fingerprint)
	assert_eq(streamer.get_population_count(Vector2i.ZERO), original_population_count)


func test_spawned_character_lands_on_generated_heightfield_collision() -> void:
	World.set_seed(17320508)
	World.config.terrain_height_min_m = 24.0
	var disk: Node = DISK_SCENE.instantiate()
	autofree(disk)
	add_child(disk)
	var streamer: TerrainStreamer = TERRAIN_STREAMER_SCENE.instantiate() as TerrainStreamer
	autofree(streamer)
	add_child(streamer)
	assert_eq(streamer.configure_host_world(), OK)
	var spawn_position: Vector3 = Vector3(1.5, 0.0, 2.598076)
	streamer.update_streaming_for_positions([spawn_position])
	assert_eq(streamer.get_loaded_chunk_count(), 1)
	var generated_chunk: TerrainChunk = streamer.get_node("Chunk_0_0") as TerrainChunk
	var mesh_instance: MeshInstance3D = generated_chunk.get_node("MeshInstance3D") as MeshInstance3D
	var generated_mesh: ArrayMesh = mesh_instance.mesh as ArrayMesh
	var generated_vertices: PackedVector3Array = generated_mesh.surface_get_arrays(0)[
		Mesh.ARRAY_VERTEX
	]
	var maximum_vertex_height: float = 0.0
	for vertex: Vector3 in generated_vertices:
		maximum_vertex_height = maxf(maximum_vertex_height, vertex.y)
	assert_gt(maximum_vertex_height, 1.0)
	var collision_node: CollisionShape3D = (
		generated_chunk.get_node("CollisionShape3D") as CollisionShape3D
	)
	var generated_collision: ConcavePolygonShape3D = collision_node.shape as ConcavePolygonShape3D
	var collision_faces: PackedVector3Array = generated_collision.get_faces()
	assert_gt(collision_faces.size(), 0)
	var generated_normals: PackedVector3Array = generated_mesh.surface_get_arrays(0)[
		Mesh.ARRAY_NORMAL
	]
	assert_gt(generated_normals[0].y, 0.0)
	var terrain_generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	assert_eq(terrain_generator.configure(World.config, World.config.world_seed), OK)
	assert_gt(terrain_generator.sample_height(spawn_position.x, spawn_position.z), 20.0)
	var observer_scene: PackedScene = load("res://entities/player/observer.tscn") as PackedScene
	_active_observer = observer_scene.instantiate() as ObserverPlayer
	_active_observer.configure(2, "player_17320508_2", "Terrain Tester")
	assert_gt(_active_observer.position.y, World.config.disk_thickness_m * 0.5 + 1.0)
	autofree(_active_observer)
	add_child(_active_observer)
	await wait_physics_frames(1)
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(spawn_position.x, 350.0, spawn_position.z),
		Vector3(spawn_position.x, 200.0, spawn_position.z)
	)
	ray_query.exclude = [_active_observer.get_rid()]
	var space_state: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var ray_hit: Dictionary = space_state.intersect_ray(ray_query)
	assert_false(ray_hit.is_empty())
	var ray_position: Vector3 = ray_hit.get("position", Vector3.ZERO)
	assert_gt(ray_position.y, World.config.disk_thickness_m * 0.5 + 1.0)
	assert_true(ray_hit.get("collider") is TerrainChunk)
	var upward_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(spawn_position.x, 200.0, spawn_position.z),
		Vector3(spawn_position.x, 350.0, spawn_position.z)
	)
	upward_query.exclude = [_active_observer.get_rid()]
	var upward_hit: Dictionary = space_state.intersect_ray(upward_query)
	assert_true(upward_hit.is_empty())

	await wait_physics_frames(300)
	assert_true(_active_observer.is_on_floor())
	assert_gt(_active_observer.position.y, World.config.disk_thickness_m * 0.5 + 1.0)


func test_adjacent_chunk_collision_has_no_seam_gap() -> void:
	World.config.terrain_height_min_m = 24.0
	var disk: Node = DISK_SCENE.instantiate()
	autofree(disk)
	add_child(disk)
	var streamer: TerrainStreamer = TERRAIN_STREAMER_SCENE.instantiate() as TerrainStreamer
	autofree(streamer)
	add_child(streamer)
	assert_eq(streamer.configure_host_world(), OK)
	streamer.update_streaming_for_positions([Vector3(127.0, 0.0, 64.0), Vector3(128.0, 0.0, 64.0)])
	assert_true(streamer.get_loaded_chunk_coordinates().has(Vector2i(0, 0)))
	assert_true(streamer.get_loaded_chunk_coordinates().has(Vector2i(1, 0)))
	assert_eq(streamer.get_child_count(), 2)
	var first_chunk: TerrainChunk = streamer.get_child(0) as TerrainChunk
	var second_chunk: TerrainChunk = streamer.get_child(1) as TerrainChunk
	assert_not_null(first_chunk)
	assert_not_null(second_chunk)
	assert_gt(first_chunk.position.x, -0.001)
	assert_almost_eq(second_chunk.position.x, World.config.terrain_chunk_size_m, 0.001)
	var first_mesh_instance: MeshInstance3D = (
		first_chunk.get_node("MeshInstance3D") as MeshInstance3D
	)
	var second_mesh_instance: MeshInstance3D = (
		second_chunk.get_node("MeshInstance3D") as MeshInstance3D
	)
	var first_mesh: ArrayMesh = first_mesh_instance.mesh as ArrayMesh
	var second_mesh: ArrayMesh = second_mesh_instance.mesh as ArrayMesh
	assert_not_null(first_mesh)
	assert_not_null(second_mesh)
	var first_arrays: Array = first_mesh.surface_get_arrays(0)
	var second_arrays: Array = second_mesh.surface_get_arrays(0)
	var first_vertices: PackedVector3Array = first_arrays[Mesh.ARRAY_VERTEX]
	var second_vertices: PackedVector3Array = second_arrays[Mesh.ARRAY_VERTEX]
	var first_normals: PackedVector3Array = first_arrays[Mesh.ARRAY_NORMAL]
	var second_normals: PackedVector3Array = second_arrays[Mesh.ARRAY_NORMAL]
	var stride: int = World.config.terrain_cells_per_chunk + 1
	for z_index: int in range(stride):
		var first_edge_index: int = World.config.terrain_cells_per_chunk * stride + z_index
		assert_almost_eq(first_vertices[first_edge_index].y, second_vertices[z_index].y, 0.000001)
		assert_true(first_normals[first_edge_index].is_equal_approx(second_normals[z_index]))
	var first_collision: CollisionShape3D = (
		first_chunk.get_node("CollisionShape3D") as CollisionShape3D
	)
	var second_collision: CollisionShape3D = (
		second_chunk.get_node("CollisionShape3D") as CollisionShape3D
	)
	assert_gt((first_collision.shape as ConcavePolygonShape3D).get_faces().size(), 0)
	assert_gt((second_collision.shape as ConcavePolygonShape3D).get_faces().size(), 0)
