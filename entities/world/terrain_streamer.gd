class_name TerrainStreamer
extends Node3D

const TERRAIN_CHUNK_SCENE: PackedScene = preload("res://entities/world/terrain_chunk.tscn")
const MAX_CHUNK_CREATIONS_PER_FRAME: int = 2
const STREAM_REFRESH_INTERVAL_SEC: float = 0.2

var _generator: DiskTerrainGenerator
var _population_generator: TerrainPopulationGenerator
var _config_signature: String = ""
var _loaded_chunks: Dictionary = {}
var _empty_chunks: Dictionary = {}
var _pending_chunk_coordinates: Array[Vector2i] = []
var _refresh_elapsed: float = 0.0


func _process(delta: float) -> void:
	if not _ensure_generator():
		return
	_refresh_elapsed -= delta
	if _refresh_elapsed <= 0.0:
		_refresh_elapsed = STREAM_REFRESH_INTERVAL_SEC
		_refresh_from_network_players()
	_load_pending_chunks()


func _exit_tree() -> void:
	for coordinate: Vector2i in get_loaded_chunk_coordinates():
		_unregister_static_prop_chunk(coordinate)
	_loaded_chunks.clear()


func configure_host_world() -> Error:
	if World.config == null or World.config.validate() != OK:
		return ERR_INVALID_PARAMETER
	return OK if _ensure_generator() else ERR_CANT_CREATE


func update_streaming_for_positions(world_positions: Array[Vector3]) -> void:
	if not _ensure_generator():
		return
	var desired_chunks: Array[Vector2i] = desired_chunk_coordinates(world_positions, World.config)
	_reconcile_chunks(desired_chunks)
	_load_pending_chunks()


func get_loaded_chunk_coordinates() -> Array[Vector2i]:
	var coordinates: Array[Vector2i] = []
	for key: Variant in _loaded_chunks.keys():
		coordinates.append(key as Vector2i)
	coordinates.sort_custom(_chunk_coordinate_less)
	return coordinates


func get_loaded_chunk_count() -> int:
	return _loaded_chunks.size()


func get_world_config_signature() -> String:
	return JSON.stringify(World.config.to_dictionary()) if World.config != null else ""


func get_chunk_fingerprint(chunk_coordinate: Vector2i) -> int:
	return _generator.chunk_fingerprint(chunk_coordinate) if _ensure_generator() else 0


func get_population_fingerprint(chunk_coordinate: Vector2i) -> int:
	if not _ensure_generator():
		return 0
	return _population_generator.build_chunk_population(chunk_coordinate).fingerprint


func get_population_count(chunk_coordinate: Vector2i) -> int:
	if not _ensure_generator():
		return 0
	return _population_generator.build_chunk_population(chunk_coordinate).size()


func is_world_configured() -> bool:
	return _ensure_generator()


static func desired_chunk_coordinates(
	world_positions: Array[Vector3], config: WorldConfig
) -> Array[Vector2i]:
	var desired: Dictionary = {}
	if config == null or config.validate() != OK:
		return []
	for world_position: Vector3 in world_positions:
		if not world_position.is_finite():
			continue
		var center: Vector2i = Vector2i(
			floori(world_position.x / config.terrain_chunk_size_m),
			floori(world_position.z / config.terrain_chunk_size_m)
		)
		for x_offset: int in range(
			-config.terrain_view_radius_chunks, config.terrain_view_radius_chunks + 1
		):
			for z_offset: int in range(
				-config.terrain_view_radius_chunks, config.terrain_view_radius_chunks + 1
			):
				var coordinate: Vector2i = center + Vector2i(x_offset, z_offset)
				if DiskTerrainGenerator.chunk_intersects_disk(coordinate, config):
					desired[coordinate] = true
	var coordinates: Array[Vector2i] = []
	for key: Variant in desired.keys():
		coordinates.append(key as Vector2i)
	coordinates.sort_custom(_chunk_coordinate_less)
	return coordinates


static func _chunk_coordinate_less(left: Vector2i, right: Vector2i) -> bool:
	return left.x < right.x or (left.x == right.x and left.y < right.y)


func _ensure_generator() -> bool:
	if World.config == null or World.config.validate() != OK:
		return false
	var next_signature: String = JSON.stringify(World.config.to_dictionary())
	if _generator != null and _config_signature == next_signature:
		return true
	_clear_loaded_chunks()
	_generator = DiskTerrainGenerator.new()
	if _generator.configure(World.config, World.config.world_seed) != OK:
		_generator = null
		_population_generator = null
		_config_signature = ""
		return false
	_population_generator = TerrainPopulationGenerator.new()
	if _population_generator.configure(World.config, _generator, World.config.world_seed) != OK:
		_generator = null
		_population_generator = null
		_config_signature = ""
		return false
	_config_signature = next_signature
	_empty_chunks.clear()
	return true


func _refresh_from_network_players() -> void:
	var positions: Array[Vector3] = []
	if multiplayer.multiplayer_peer == null:
		return
	var server_authority: bool = multiplayer.is_server()
	for player_node: Node in get_tree().get_nodes_in_group("network_players"):
		if not player_node is ObserverPlayer:
			continue
		if server_authority or player_node.peer_id == multiplayer.get_unique_id():
			positions.append(player_node.global_position)
	var desired_chunks: Array[Vector2i] = desired_chunk_coordinates(positions, World.config)
	_reconcile_chunks(desired_chunks)


func _reconcile_chunks(desired_chunks: Array[Vector2i]) -> void:
	var desired: Dictionary = {}
	for coordinate: Vector2i in desired_chunks:
		desired[coordinate] = true
	for coordinate: Vector2i in get_loaded_chunk_coordinates():
		if desired.has(coordinate):
			continue
		var chunk: TerrainChunk = _loaded_chunks[coordinate] as TerrainChunk
		_loaded_chunks.erase(coordinate)
		_unregister_static_prop_chunk(coordinate)
		if is_instance_valid(chunk):
			chunk.queue_free()
	for empty_coordinate: Vector2i in _empty_chunks.keys():
		if not desired.has(empty_coordinate):
			_empty_chunks.erase(empty_coordinate)
	_pending_chunk_coordinates.clear()
	for coordinate: Vector2i in desired_chunks:
		if not _loaded_chunks.has(coordinate) and not _empty_chunks.has(coordinate):
			_pending_chunk_coordinates.append(coordinate)


func _load_pending_chunks() -> void:
	var creations: int = 0
	while not _pending_chunk_coordinates.is_empty() and creations < MAX_CHUNK_CREATIONS_PER_FRAME:
		var coordinate: Vector2i = _pending_chunk_coordinates.pop_front()
		if (
			_loaded_chunks.has(coordinate)
			or not DiskTerrainGenerator.chunk_intersects_disk(coordinate, World.config)
		):
			continue
		var chunk: TerrainChunk = TERRAIN_CHUNK_SCENE.instantiate() as TerrainChunk
		if chunk == null:
			Log.error("world.terrain_chunk_instantiation_failed", {"coordinate": coordinate})
			continue
		var result: Error = chunk.configure(coordinate, _generator, _population_generator)
		if result == ERR_DOES_NOT_EXIST:
			_empty_chunks[coordinate] = true
			chunk.free()
			continue
		if result != OK:
			Log.error(
				"world.terrain_chunk_configuration_failed",
				{"coordinate": coordinate, "error": result}
			)
			chunk.free()
			continue
		if World.has_host_authority():
			var registration_result: Error = World.register_static_prop_chunk(
				coordinate, chunk.get_population_data()
			)
			if registration_result != OK:
				Log.error(
					"world.static_prop_registration_failed",
					{"coordinate": coordinate, "error": registration_result}
				)
				chunk.free()
				continue
		chunk.name = "Chunk_%d_%d" % [coordinate.x, coordinate.y]
		add_child(chunk)
		_loaded_chunks[coordinate] = chunk
		creations += 1


func _clear_loaded_chunks() -> void:
	for coordinate: Vector2i in get_loaded_chunk_coordinates():
		var chunk_value: Variant = _loaded_chunks[coordinate]
		var chunk: TerrainChunk = chunk_value as TerrainChunk
		_unregister_static_prop_chunk(coordinate)
		if is_instance_valid(chunk):
			chunk.queue_free()
	_loaded_chunks.clear()
	_pending_chunk_coordinates.clear()


func _unregister_static_prop_chunk(chunk_coordinate: Vector2i) -> void:
	if not World.has_host_authority():
		return
	var result: Error = World.unregister_static_prop_chunk(chunk_coordinate)
	if result != OK:
		Log.error(
			"world.static_prop_unregistration_failed",
			{"coordinate": chunk_coordinate, "error": result}
		)
