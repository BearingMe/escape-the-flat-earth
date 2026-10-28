extends Node

const TERRAIN_STREAMER_SCENE: PackedScene = preload("res://entities/world/terrain_streamer.tscn")
const PROFILE_SEED: int = 8675309
const PROFILE_POSITIONS: Array[Vector3] = [Vector3(64.0, 0.0, 64.0), Vector3(2112.0, 0.0, 64.0)]
const MAX_STREAM_FRAMES: int = 100


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	World.config = World.config.duplicate(true) as WorldConfig
	World.set_seed(PROFILE_SEED)
	Net.session_role = "host"
	var report: Dictionary = {
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"headless": DisplayServer.get_name() == "headless",
		"seed": PROFILE_SEED,
		"config": World.config.to_dictionary()
	}
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	var started_usec: int = Time.get_ticks_usec()
	var configure_result: Error = generator.configure(World.config, PROFILE_SEED)
	report["generator_config_usec"] = Time.get_ticks_usec() - started_usec
	if configure_result != OK:
		_fail("generator_config", report)
		return
	var population_generator: TerrainPopulationGenerator = TerrainPopulationGenerator.new()
	started_usec = Time.get_ticks_usec()
	var population_configure_result: Error = population_generator.configure(
		World.config, generator, PROFILE_SEED
	)
	report["population_config_usec"] = Time.get_ticks_usec() - started_usec
	if population_configure_result != OK:
		_fail("population_config", report)
		return

	if not _profile_individual_chunks(generator, population_generator, report):
		return

	var streamer: TerrainStreamer = TERRAIN_STREAMER_SCENE.instantiate() as TerrainStreamer
	if streamer == null:
		_fail("streamer_instantiation", report)
		return
	get_tree().root.add_child(streamer)
	streamer.set_process(false)
	var desired_chunks: Array[Vector2i] = TerrainStreamer.desired_chunk_coordinates(
		PROFILE_POSITIONS, World.config
	)
	report["desired_chunk_count"] = desired_chunks.size()
	var static_memory_baseline_bytes: int = Performance.get_monitor(Performance.MEMORY_STATIC)
	report["static_memory_baseline_bytes"] = static_memory_baseline_bytes
	if not await _profile_streamer_passes(streamer, desired_chunks, report):
		return
	streamer.free()
	World.clear_static_prop_registry()
	await get_tree().process_frame
	await get_tree().process_frame
	report["static_memory_after_second_cleanup_bytes"] = Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	report["second_cleanup_growth_bytes"] = (
		int(report["static_memory_after_second_cleanup_bytes"])
		- int(report["static_memory_after_first_cleanup_bytes"])
	)
	print("PROFILE_RESULT %s" % JSON.stringify(report))
	get_tree().quit(0)


func _profile_individual_chunks(
	generator: DiskTerrainGenerator,
	population_generator: TerrainPopulationGenerator,
	report: Dictionary
) -> bool:
	var generation_profiles: Array[Dictionary] = []
	for coordinate: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(16, 0)]:
		var generation_profile: Dictionary = {"coordinate": [coordinate.x, coordinate.y]}
		var started_usec: int = Time.get_ticks_usec()
		var mesh: ArrayMesh = generator.build_chunk_mesh(coordinate)
		generation_profile["mesh_usec"] = Time.get_ticks_usec() - started_usec
		if mesh == null:
			_fail("profile_mesh_missing_%d_%d" % [coordinate.x, coordinate.y], report)
			return false
		started_usec = Time.get_ticks_usec()
		var collision: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		generation_profile["collision_usec"] = Time.get_ticks_usec() - started_usec
		if collision == null:
			_fail("profile_collision_missing_%d_%d" % [coordinate.x, coordinate.y], report)
			return false
		started_usec = Time.get_ticks_usec()
		var population: TerrainChunkPopulation = population_generator.build_chunk_population(
			coordinate
		)
		generation_profile["population_usec"] = Time.get_ticks_usec() - started_usec
		generation_profile["population_count"] = population.size()
		generation_profile["triangle_count"] = collision.get_faces().size() / 3
		generation_profiles.append(generation_profile)
	report["chunk_generation"] = generation_profiles
	return true


func _profile_streamer_passes(
	streamer: TerrainStreamer, desired_chunks: Array[Vector2i], report: Dictionary
) -> bool:
	var stream_frame_usec: Array[int] = []
	var stream_started_usec: int = Time.get_ticks_usec()
	var started_usec: int = Time.get_ticks_usec()
	streamer.update_streaming_for_positions(PROFILE_POSITIONS)
	stream_frame_usec.append(Time.get_ticks_usec() - started_usec)
	report["loaded_after_stream_request"] = streamer.get_loaded_chunk_count()
	report["pending_after_stream_request"] = streamer._pending_chunk_coordinates.size()
	var frames: int = 0
	while streamer.get_loaded_chunk_count() < desired_chunks.size() and frames < MAX_STREAM_FRAMES:
		streamer._load_pending_chunks()
		started_usec = Time.get_ticks_usec()
		await get_tree().process_frame
		stream_frame_usec.append(Time.get_ticks_usec() - started_usec)
		frames += 1
	if streamer.get_loaded_chunk_count() != desired_chunks.size():
		_fail("streaming_timeout", report)
		streamer.free()
		return false
	await get_tree().process_frame
	report["stream_load_usec"] = Time.get_ticks_usec() - stream_started_usec
	report["stream_frames"] = frames
	report["loaded_chunk_count"] = streamer.get_loaded_chunk_count()
	report["stream_frame_mean_usec"] = _mean(stream_frame_usec)
	report["stream_frame_max_usec"] = _maximum(stream_frame_usec)
	report["active_static_prop_count"] = World.get_active_static_prop_count()
	report["runtime_monitors"] = _runtime_monitors()
	report["static_memory_after_stream_bytes"] = Performance.get_monitor(Performance.MEMORY_STATIC)
	report["object_count_after_stream"] = Performance.get_monitor(Performance.OBJECT_COUNT)
	report["node_count_after_stream"] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	report["active_physics_objects_after_stream"] = Performance.get_monitor(
		Performance.PHYSICS_3D_ACTIVE_OBJECTS
	)
	streamer.update_streaming_for_positions([])
	await get_tree().process_frame
	await get_tree().process_frame
	report["static_memory_after_first_cleanup_bytes"] = Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	var second_pass_frame_usec: Array[int] = []
	var second_pass_started_usec: int = Time.get_ticks_usec()
	started_usec = Time.get_ticks_usec()
	streamer.update_streaming_for_positions(PROFILE_POSITIONS)
	second_pass_frame_usec.append(Time.get_ticks_usec() - started_usec)
	frames = 0
	while streamer.get_loaded_chunk_count() < desired_chunks.size() and frames < MAX_STREAM_FRAMES:
		streamer._load_pending_chunks()
		started_usec = Time.get_ticks_usec()
		await get_tree().process_frame
		second_pass_frame_usec.append(Time.get_ticks_usec() - started_usec)
		frames += 1
	if streamer.get_loaded_chunk_count() != desired_chunks.size():
		_fail("second_streaming_timeout", report)
		streamer.free()
		return false
	report["second_stream_load_usec"] = Time.get_ticks_usec() - second_pass_started_usec
	report["second_stream_frame_mean_usec"] = _mean(second_pass_frame_usec)
	report["second_stream_frame_max_usec"] = _maximum(second_pass_frame_usec)
	return true


func _runtime_monitors() -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_sec": Performance.get_monitor(Performance.TIME_PROCESS),
		"physics_process_sec": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"render_objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"render_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"render_draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"texture_memory_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"render_buffer_memory_bytes": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)
	}


func _mean(samples: Array[int]) -> float:
	if samples.is_empty():
		return 0.0
	var total_usec: int = 0
	for sample: int in samples:
		total_usec += sample
	return float(total_usec) / float(samples.size())


func _maximum(samples: Array[int]) -> int:
	var maximum_usec: int = 0
	for sample: int in samples:
		maximum_usec = maxi(maximum_usec, sample)
	return maximum_usec


func _fail(stage: String, report: Dictionary) -> void:
	report["status"] = "failed"
	report["stage"] = stage
	push_error("World profile failed: %s" % stage)
	print("PROFILE_RESULT %s" % JSON.stringify(report))
	get_tree().quit(1)
