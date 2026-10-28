extends Node3D

const E2E_TIMEOUT_SEC: float = 18.0
const E2E_HOST_SETTLE_SEC: float = 0.75
const E2E_CAMERA_SETTLE_SEC: float = 1.0
const E2E_GROUND_SETTLE_SEC: float = 5.0
const E2E_DISTANT_EXPLORATION_X_M: float = 2048.0
const E2E_DISTANT_EXPLORATION_SETTLE_SEC: float = 0.75

var _e2e_role: String = ""
var _e2e_result_dir: String = ""
var _e2e_elapsed: float = 0.0
var _e2e_host_settle: float = -1.0
var _e2e_full_capacity_seen: bool = false
var _e2e_initial_positions: Dictionary = {}
var _e2e_client_slot: int = 0
var _e2e_drop_after_connect: bool = false
var _e2e_drop_client_slot: int = 0
var _e2e_drop_elapsed: float = 0.0
var _e2e_client_ready_written: bool = false
var _e2e_host_result: Dictionary = {}
var _e2e_host_result_seen: bool = false
var _e2e_local_peer_id: int = 0
var _e2e_position_converged: bool = false
var _e2e_camera_wait_elapsed: float = 0.0
var _e2e_ground_wait_elapsed: float = 0.0
var _e2e_grounded_at_spawn: bool = false
var _e2e_requested_seed: int = 0
var _e2e_distant_exploration: bool = false
var _e2e_drop_after_exploration: bool = false
var _e2e_distant_exploration_started: bool = false
var _e2e_distant_region_chunk_seen: bool = false
var _e2e_distant_exploration_ready: bool = false
var _e2e_distant_exploration_elapsed: float = 0.0

@onready var _players: Node3D = %Players
@onready var _spawner: MultiplayerSpawner = %Spawner
@onready var _terrain_streamer: TerrainStreamer = %TerrainStreamer


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_e2e_role = _read_string_argument(arguments, "--e2e-role", "")
	_e2e_result_dir = _read_string_argument(arguments, "--e2e-result-dir", "")
	_e2e_client_slot = _read_integer_argument(arguments, "--e2e-client-slot", 0)
	_e2e_drop_client_slot = _read_integer_argument(arguments, "--e2e-drop-client-slot", 0)
	_e2e_drop_after_connect = arguments.has("--e2e-drop-after-connect")
	_e2e_distant_exploration = arguments.has("--e2e-distant-exploration")
	_e2e_drop_after_exploration = arguments.has("--e2e-drop-after-exploration")
	var binding_result: Error = Net.bind_world(_players, _spawner)
	if binding_result != OK:
		Log.error("world.network_binding_failed", {"error": binding_result})
		return
	var port: int = _read_integer_argument(arguments, "--port", Net.DEFAULT_PORT)
	var max_players: int = _read_integer_argument(
		arguments, "--max-players", World.config.max_players
	)
	var seed_value: int = _read_integer_argument(arguments, "--seed", World.config.world_seed)
	_e2e_requested_seed = seed_value
	World.config.max_players = max_players
	World.set_seed(seed_value)
	var join_address: String = _read_string_argument(arguments, "--join", "")
	if join_address.is_empty():
		var terrain_result: Error = _terrain_streamer.configure_host_world()
		if terrain_result != OK:
			Log.error("world.terrain_configuration_failed", {"error": terrain_result})
			return
	var result: Error = (
		Net.join(join_address, port) if not join_address.is_empty() else Net.host(port, max_players)
	)
	if result != OK:
		Net.last_error = result
		if not _e2e_role.is_empty():
			_write_e2e_result(
				"%s.result.json" % _e2e_role,
				{"status": "failed", "stage": "session_start", "error": result}
			)
			get_tree().quit(1)
			return
		Log.warning(
			"network.session_start_failed",
			{"role": "client" if not join_address.is_empty() else "host", "error": result}
		)
	if _e2e_role == "host":
		_write_e2e_result(
			"host.ready.json",
			{
				"status": "ready",
				"port": port,
				"terrain_seed": World.config.world_seed,
				"world_config": World.config.to_dictionary(),
				"terrain_fingerprint": _terrain_streamer.get_chunk_fingerprint(Vector2i.ZERO),
				"biome_samples": _terrain_biome_snapshot(),
				"population_fingerprint":
				_terrain_streamer.get_population_fingerprint(Vector2i.ZERO),
				"population_count": _terrain_streamer.get_population_count(Vector2i.ZERO)
			}
		)


func _process(delta: float) -> void:
	if _e2e_role.is_empty():
		return
	_e2e_elapsed += delta
	if _e2e_elapsed > E2E_TIMEOUT_SEC:
		_finish_e2e_failure("scenario_timeout")
		return
	if _e2e_role == "host":
		_process_e2e_host(delta)
	else:
		_process_e2e_client(delta)


func _read_integer_argument(arguments: PackedStringArray, key: String, fallback: int) -> int:
	var prefix: String = key + "="
	for argument: String in arguments:
		if argument.begins_with(prefix):
			var raw_value: String = argument.trim_prefix(prefix)
			if raw_value.is_valid_int():
				return raw_value.to_int()
	return fallback


func _read_string_argument(arguments: PackedStringArray, key: String, fallback: String) -> String:
	var prefix: String = key + "="
	for argument: String in arguments:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix).strip_edges()
	return fallback


func _terrain_biome_snapshot() -> Dictionary:
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	if generator.configure(World.config, World.config.world_seed) != OK:
		return {}
	var normalized_points: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(0.25, 0.0),
		Vector2(-0.25, 0.25),
		Vector2(0.0, 0.5),
		Vector2(0.5, 0.0),
		Vector2(0.0, 0.75),
		Vector2(0.96, 0.0),
		Vector2(-0.96, 0.0),
		Vector2(0.0, -0.96)
	]
	var samples: Dictionary = {}
	for normalized_point: Vector2 in normalized_points:
		var world_point: Vector2 = normalized_point * World.config.disk_radius_m
		var key: String = "%.2f,%.2f" % [normalized_point.x, normalized_point.y]
		samples[key] = generator.sample_biome_id(world_point.x, world_point.y)
	return samples


func _process_e2e_host(delta: float) -> void:
	if (
		_e2e_distant_exploration_started
		and _terrain_streamer.get_loaded_chunk_coordinates().has(Vector2i(16, 0))
	):
		_e2e_distant_region_chunk_seen = true
	if _e2e_host_settle >= 0.0:
		_e2e_host_settle -= delta
		if _e2e_host_settle <= 0.0:
			Net.end_session()
			get_tree().quit(0)
		return
	if Net.player_count() >= World.config.max_players and not _e2e_full_capacity_seen:
		var host_observer: ObserverPlayer = _players.get_node_or_null("Player_1") as ObserverPlayer
		if (
			not _camera_ownership_is_valid(1)
			or host_observer == null
			or not host_observer.has_applied_e2e_camera_look()
		):
			_e2e_camera_wait_elapsed += delta
			if _e2e_camera_wait_elapsed >= E2E_CAMERA_SETTLE_SEC:
				_finish_e2e_failure("camera_ownership")
			return
		if not _all_players_grounded():
			_e2e_ground_wait_elapsed += delta
			if _e2e_ground_wait_elapsed >= E2E_GROUND_SETTLE_SEC:
				_finish_e2e_failure("gravity_grounding")
			return
		_e2e_grounded_at_spawn = true
		_e2e_full_capacity_seen = true
		for child: Node in _players.get_children():
			if child is ObserverPlayer and child.peer_id != 1:
				_e2e_initial_positions[child.peer_id] = child.global_position
		if _e2e_distant_exploration:
			_begin_e2e_distant_exploration()
	if not _e2e_full_capacity_seen or Net.player_count() != World.config.max_players - 1:
		return
	var dropped_peer_id: int = _read_dropped_peer_id()
	if dropped_peer_id < 1:
		return
	if (
		_players.has_node("Player_%d" % dropped_peer_id)
		or not _remaining_players_moved(dropped_peer_id)
	):
		return
	_stop_e2e_player_movement()
	_write_e2e_result(
		"host.result.json",
		{
			"status": "passed",
			"connected_total": World.config.max_players,
			"remaining_total": Net.player_count(),
			"dropped_peer_removed": true,
			"dropped_peer_id": dropped_peer_id,
			"remaining_clients_moved": true,
			"camera_ownership_valid": true,
			"camera_look_applied": true,
			"grounded_at_spawn": _e2e_grounded_at_spawn,
			"remaining_players_grounded": _all_players_grounded(),
			"host_resolved_movement": true,
			"terrain_seed": World.config.world_seed,
			"terrain_fingerprint": _terrain_streamer.get_chunk_fingerprint(Vector2i.ZERO),
			"loaded_chunk_count": _terrain_streamer.get_loaded_chunk_count(),
			"active_static_prop_count": World.get_active_static_prop_count(),
			"distant_region_chunk_loaded": _e2e_distant_region_chunk_seen,
			"player_positions": _snapshot_player_positions()
		}
	)
	_e2e_host_settle = E2E_HOST_SETTLE_SEC


func _read_dropped_peer_id() -> int:
	var drop_result_path: String = _e2e_result_dir.path_join(
		"client-%d.drop.json" % _e2e_drop_client_slot
	)
	if not FileAccess.file_exists(drop_result_path):
		return -1
	var drop_result: Variant = JSON.parse_string(FileAccess.get_file_as_string(drop_result_path))
	if not drop_result is Dictionary:
		return -1
	var dropped_peer_value: Variant = drop_result.get("peer_id", -1)
	if typeof(dropped_peer_value) != TYPE_INT and typeof(dropped_peer_value) != TYPE_FLOAT:
		return -1
	return int(dropped_peer_value)


func _remaining_players_moved(dropped_peer_id: int) -> bool:
	var remaining_clients: int = 0
	for child: Node in _players.get_children():
		if not child is ObserverPlayer or child.peer_id == 1:
			continue
		if child.peer_id == dropped_peer_id:
			return false
		remaining_clients += 1
		var initial_position: Variant = _e2e_initial_positions.get(child.peer_id)
		if not initial_position is Vector3:
			return false
		if child.global_position.distance_to(initial_position) < 1.0:
			return false
	return remaining_clients == World.config.max_players - 2


func _all_players_grounded() -> bool:
	var observer_count: int = 0
	for child: Node in _players.get_children():
		if not child is ObserverPlayer:
			continue
		observer_count += 1
		if not child.is_on_floor():
			return false
	return observer_count == Net.player_count() and observer_count > 0


func _stop_e2e_player_movement() -> void:
	for child: Node in _players.get_children():
		if child is ObserverPlayer:
			child.set_movement_enabled(false)


func _snapshot_player_positions() -> Dictionary:
	var positions: Dictionary = {}
	for child: Node in _players.get_children():
		if child is ObserverPlayer:
			positions[str(child.peer_id)] = [child.position.x, child.position.y, child.position.z]
	return positions


func _begin_e2e_distant_exploration() -> void:
	var distant_observer: ObserverPlayer
	for child: Node in _players.get_children():
		if child is ObserverPlayer and child.peer_id != 1:
			distant_observer = child
			break
	if distant_observer == null:
		_finish_e2e_failure("distant_exploration_missing_client")
		return
	var generator: DiskTerrainGenerator = DiskTerrainGenerator.new()
	if generator.configure(World.config, World.config.world_seed) != OK:
		_finish_e2e_failure("distant_exploration_generator")
		return
	var distant_position: Vector3 = Vector3(
		E2E_DISTANT_EXPLORATION_X_M,
		(
			World.config.disk_thickness_m * 0.5
			+ generator.sample_mesh_cell_max_height(E2E_DISTANT_EXPLORATION_X_M, 0.0)
			+ 0.1
		),
		0.0
	)
	distant_observer.global_position = distant_position
	distant_observer.replicated_position = distant_position
	distant_observer.velocity = Vector3.ZERO
	_e2e_distant_exploration_started = true


func _process_e2e_client(delta: float) -> void:
	if Net.session_status == "connected" and not _e2e_client_ready_written:
		var local_observer: ObserverPlayer = _find_local_observer()
		if (
			local_observer != null
			and local_observer.has_applied_e2e_camera_look()
			and _terrain_streamer.is_world_configured()
			and _terrain_streamer.get_loaded_chunk_count() > 0
		):
			_e2e_local_peer_id = local_observer.peer_id
			var camera_ownership_valid: bool = _camera_ownership_is_valid(_e2e_local_peer_id)
			if not camera_ownership_valid:
				_e2e_camera_wait_elapsed += delta
				if _e2e_camera_wait_elapsed >= E2E_CAMERA_SETTLE_SEC:
					_finish_e2e_failure("camera_ownership")
				return
			_e2e_client_ready_written = _write_e2e_result(
				"client-%d.ready.json" % _e2e_client_slot,
				{
					"status": "ready" if camera_ownership_valid else "failed",
					"peer_id": local_observer.peer_id,
					"camera_ownership_valid": camera_ownership_valid,
					"camera_look_applied": true,
					"movement_intent_delay_msec": local_observer.e2e_intent_delay_msec(),
					"terrain_seed": World.config.world_seed,
					"requested_seed": _e2e_requested_seed,
					"world_config": World.config.to_dictionary(),
					"terrain_fingerprint": _terrain_streamer.get_chunk_fingerprint(Vector2i.ZERO),
					"biome_samples": _terrain_biome_snapshot(),
					"population_fingerprint":
					_terrain_streamer.get_population_fingerprint(Vector2i.ZERO),
					"population_count": _terrain_streamer.get_population_count(Vector2i.ZERO),
					"local_static_prop_registry_count": World.get_active_static_prop_count(),
					"loaded_chunk_count": _terrain_streamer.get_loaded_chunk_count()
				}
			)
	if _e2e_distant_exploration and _process_e2e_distant_exploration(delta):
		return
	if _e2e_drop_after_connect and _e2e_client_ready_written:
		_e2e_drop_elapsed += delta
		if _e2e_drop_elapsed >= 2.0:
			_write_e2e_result(
				"client-%d.drop.json" % _e2e_client_slot,
				{"status": "passed", "peer_id": _e2e_local_peer_id}
			)
			Net.end_session()
			get_tree().quit(0)
			return
	var host_result_path: String = _e2e_result_dir.path_join("host.result.json")
	if not _e2e_host_result_seen and FileAccess.file_exists(host_result_path):
		var parsed_result: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(host_result_path)
		)
		if parsed_result is Dictionary:
			_e2e_host_result = parsed_result
			_e2e_host_result_seen = true
	if _e2e_host_result_seen and not _e2e_position_converged:
		_e2e_position_converged = _local_position_matches_host_snapshot()
	if (
		_e2e_host_result_seen
		and Net.session_status == "server_disconnected"
		and Net.player_count() == 0
	):
		var status: String = (
			"passed"
			if _e2e_host_result.get("status") == "passed" and _e2e_position_converged
			else "failed"
		)
		_write_e2e_result(
			"client-%d.result.json" % _e2e_client_slot,
			{
				"status": status,
				"disconnected_cleanly": true,
				"host_status": _e2e_host_result.get("status"),
				"replicated_position_converged": _e2e_position_converged
			}
		)
		get_tree().quit(0 if status == "passed" else 1)


func _process_e2e_distant_exploration(delta: float) -> bool:
	if _e2e_client_slot != 1 or not _e2e_client_ready_written:
		return false
	var local_observer: ObserverPlayer = _find_local_observer()
	if local_observer == null:
		return false
	var distant_chunk: Vector2i = Vector2i(
		floori(E2E_DISTANT_EXPLORATION_X_M / World.config.terrain_chunk_size_m), 0
	)
	if (
		not _e2e_distant_exploration_ready
		and local_observer.global_position.x >= E2E_DISTANT_EXPLORATION_X_M - 32.0
		and _terrain_streamer.get_loaded_chunk_coordinates().has(distant_chunk)
	):
		_e2e_distant_exploration_ready = _write_e2e_result(
			"client-%d.explore.json" % _e2e_client_slot,
			{
				"status": "passed",
				"position_x": local_observer.global_position.x,
				"target_chunk": [distant_chunk.x, distant_chunk.y],
				"loaded_chunk_count": _terrain_streamer.get_loaded_chunk_count()
			}
		)
	if not _e2e_drop_after_exploration or not _e2e_distant_exploration_ready:
		return false
	_e2e_distant_exploration_elapsed += delta
	if _e2e_distant_exploration_elapsed < E2E_DISTANT_EXPLORATION_SETTLE_SEC:
		return false
	_write_e2e_result(
		"client-%d.drop.json" % _e2e_client_slot,
		{"status": "passed", "peer_id": _e2e_local_peer_id}
	)
	Net.end_session()
	get_tree().quit(0)
	return true


func _find_local_observer() -> ObserverPlayer:
	if multiplayer.multiplayer_peer == null:
		return null
	for child: Node in _players.get_children():
		if child is ObserverPlayer and child.peer_id == multiplayer.get_unique_id():
			return child
	return null


func _local_position_matches_host_snapshot() -> bool:
	var position_map: Variant = _e2e_host_result.get("player_positions", {})
	if not position_map is Dictionary:
		return false
	var raw_position: Variant = position_map.get(str(_e2e_local_peer_id))
	if not raw_position is Array or raw_position.size() != 3:
		return false
	var local_observer: ObserverPlayer = _find_local_observer()
	if local_observer == null:
		return false
	var expected_position: Vector3 = Vector3(
		float(raw_position[0]), float(raw_position[1]), float(raw_position[2])
	)
	return local_observer.position.distance_to(expected_position) <= 1.0


func _camera_ownership_is_valid(local_peer_id: int) -> bool:
	var active_camera_count: int = 0
	var local_camera_is_active: bool = false
	for child: Node in _players.get_children():
		if not child is ObserverPlayer:
			continue
		if child.is_camera_current():
			active_camera_count += 1
			if child.peer_id == local_peer_id:
				local_camera_is_active = true
	return local_camera_is_active and active_camera_count == 1


func _write_e2e_result(file_name: String, result: Dictionary) -> bool:
	if _e2e_result_dir.is_empty():
		return false
	var directory_result: Error = DirAccess.make_dir_recursive_absolute(_e2e_result_dir)
	if directory_result != OK and directory_result != ERR_ALREADY_EXISTS:
		return false
	var file: FileAccess = FileAccess.open(_e2e_result_dir.path_join(file_name), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(result))
	file.close()
	return true


func _finish_e2e_failure(stage: String) -> void:
	var player_ids: Array[int] = []
	var movement_distances: Dictionary = {}
	var player_states: Dictionary = {}
	for child: Node in _players.get_children():
		if child is ObserverPlayer:
			player_ids.append(child.peer_id)
			player_states[str(child.peer_id)] = {
				"position":
				[child.global_position.x, child.global_position.y, child.global_position.z],
				"velocity": [child.velocity.x, child.velocity.y, child.velocity.z],
				"grounded": child.is_on_floor()
			}
			if _e2e_initial_positions.has(child.peer_id):
				movement_distances[child.peer_id] = child.global_position.distance_to(
					_e2e_initial_positions[child.peer_id]
				)
	_write_e2e_result(
		"%s.result.json" % _e2e_role,
		{
			"status": "failed",
			"stage": stage,
			"session_status": Net.session_status,
			"player_count": Net.player_count(),
			"full_capacity_seen": _e2e_full_capacity_seen,
			"peer_ids": player_ids,
			"movement_distances": movement_distances,
			"player_states": player_states,
			"loaded_chunk_coordinates": _terrain_streamer.get_loaded_chunk_coordinates()
		}
	)
	Net.end_session()
	get_tree().quit(1)
