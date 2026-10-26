extends Node3D

const E2E_TIMEOUT_SEC: float = 18.0
const E2E_HOST_SETTLE_SEC: float = 0.75

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

@onready var _players: Node3D = %Players
@onready var _spawner: MultiplayerSpawner = %Spawner


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_e2e_role = _read_string_argument(arguments, "--e2e-role", "")
	_e2e_result_dir = _read_string_argument(arguments, "--e2e-result-dir", "")
	_e2e_client_slot = _read_integer_argument(arguments, "--e2e-client-slot", 0)
	_e2e_drop_client_slot = _read_integer_argument(arguments, "--e2e-drop-client-slot", 0)
	_e2e_drop_after_connect = arguments.has("--e2e-drop-after-connect")
	var binding_result: Error = Net.bind_world(_players, _spawner)
	if binding_result != OK:
		Log.error("world.network_binding_failed", {"error": binding_result})
		return
	var port: int = _read_integer_argument(arguments, "--port", Net.DEFAULT_PORT)
	var max_players: int = _read_integer_argument(
		arguments, "--max-players", World.config.max_players
	)
	var seed_value: int = _read_integer_argument(arguments, "--seed", World.config.world_seed)
	World.set_seed(seed_value)
	var join_address: String = _read_string_argument(arguments, "--join", "")
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
		_write_e2e_result("host.ready.json", {"status": "ready", "port": port})


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


func _process_e2e_host(delta: float) -> void:
	if _e2e_host_settle >= 0.0:
		_e2e_host_settle -= delta
		if _e2e_host_settle <= 0.0:
			Net.end_session()
			get_tree().quit(0)
		return
	if Net.player_count() >= World.config.max_players and not _e2e_full_capacity_seen:
		if not _camera_ownership_is_valid(1):
			_finish_e2e_failure("camera_ownership")
		else:
			_e2e_full_capacity_seen = true
			for child: Node in _players.get_children():
				if child is ObserverPlayer and child.peer_id != 1:
					_e2e_initial_positions[child.peer_id] = child.global_position
	if not _e2e_full_capacity_seen or Net.player_count() != World.config.max_players - 1:
		return
	var drop_result_path: String = _e2e_result_dir.path_join(
		"client-%d.drop.json" % _e2e_drop_client_slot
	)
	if not FileAccess.file_exists(drop_result_path):
		return
	var drop_result: Variant = JSON.parse_string(FileAccess.get_file_as_string(drop_result_path))
	if not drop_result is Dictionary:
		return
	var dropped_peer_value: Variant = drop_result.get("peer_id", -1)
	if typeof(dropped_peer_value) != TYPE_INT and typeof(dropped_peer_value) != TYPE_FLOAT:
		return
	var dropped_peer_id: int = int(dropped_peer_value)
	if (
		_players.has_node("Player_%d" % dropped_peer_id)
		or not _remaining_players_moved(dropped_peer_id)
	):
		return
	_write_e2e_result(
		"host.result.json",
		{
			"status": "passed",
			"connected_total": World.config.max_players,
			"remaining_total": Net.player_count(),
			"dropped_peer_removed": true,
			"dropped_peer_id": dropped_peer_id,
			"remaining_clients_moved": true,
			"camera_ownership_valid": true
		}
	)
	_e2e_host_settle = E2E_HOST_SETTLE_SEC


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


func _process_e2e_client(delta: float) -> void:
	if Net.session_status == "connected" and not _e2e_client_ready_written:
		var local_observer: ObserverPlayer = _find_local_observer()
		if local_observer != null:
			_e2e_local_peer_id = local_observer.peer_id
			var camera_ownership_valid: bool = _camera_ownership_is_valid(_e2e_local_peer_id)
			_e2e_client_ready_written = _write_e2e_result(
				"client-%d.ready.json" % _e2e_client_slot,
				{
					"status": "ready" if camera_ownership_valid else "failed",
					"peer_id": local_observer.peer_id,
					"camera_ownership_valid": camera_ownership_valid
				}
			)
			if not camera_ownership_valid:
				_finish_e2e_failure("camera_ownership")
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
	if (
		_e2e_host_result_seen
		and Net.session_status == "server_disconnected"
		and Net.player_count() == 0
	):
		var status: String = "passed" if _e2e_host_result.get("status") == "passed" else "failed"
		_write_e2e_result(
			"client-%d.result.json" % _e2e_client_slot,
			{
				"status": status,
				"disconnected_cleanly": true,
				"host_status": _e2e_host_result.get("status")
			}
		)
		get_tree().quit(0 if status == "passed" else 1)


func _find_local_observer() -> ObserverPlayer:
	if multiplayer.multiplayer_peer == null:
		return null
	for child: Node in _players.get_children():
		if child is ObserverPlayer and child.peer_id == multiplayer.get_unique_id():
			return child
	return null


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
	for child: Node in _players.get_children():
		if child is ObserverPlayer:
			player_ids.append(child.peer_id)
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
			"movement_distances": movement_distances
		}
	)
	Net.end_session()
	get_tree().quit(1)
