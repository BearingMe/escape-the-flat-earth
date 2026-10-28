extends SceneTree

const PROCESS_TIMEOUT_SEC: float = 35.0
const CLIENT_COUNT: int = 5
const SIMULATED_INTENT_DELAY_MSEC: int = 100
const HOST_WORLD_SEED: int = 8675309
const CLIENT_REQUESTED_SEED: int = 8675310

var _process_ids: Array[int] = []
var _run_directory: String = ""
var _host_process_id: int = 0
var _client_process_ids: Array[int] = []
var _failure_message: String = ""
var _client_count: int = CLIENT_COUNT
var _distant_exploration: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_distant_exploration = OS.get_cmdline_user_args().has("--e2e-distant-exploration")
	if _distant_exploration:
		_client_count = 1
	var project_path: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	var passed: bool = _prepare_run_directory()
	if passed:
		passed = await _start_host_stage(project_path)
	if passed:
		passed = await _run_client_stage(project_path)
	if passed:
		passed = _verify_results()
	if passed:
		print(
			(
				(
					"Distant exploration E2E passed: host + 1 client streamed a remote region, "
					+ "then disconnected cleanly."
				)
				if _distant_exploration
				else (
					"Multiplayer E2E passed: host + 5 clients, unique peer-keyed spawns, "
					+ "local camera ownership/look, 100 ms delayed host-resolved movement, "
					+ "client convergence, disconnect cleanup, and teardown."
				)
			)
		)
		quit(0)
	else:
		_fail(_failure_message)


func _prepare_run_directory() -> bool:
	_run_directory = OS.get_user_data_dir().path_join(
		"e2e/m01-multiplayer-%d-%d" % [OS.get_process_id(), Time.get_ticks_msec()]
	)
	var directory_result: Error = DirAccess.make_dir_recursive_absolute(_run_directory)
	if directory_result != OK and directory_result != ERR_ALREADY_EXISTS:
		_failure_message = "Unable to create E2E result directory: %s" % directory_result
		return false
	return true


func _start_host_stage(project_path: String) -> bool:
	var port: int = 30000 + (Time.get_ticks_msec() % 20000)
	_host_process_id = _start_child(
		project_path, "host", "", port, 0, false, false, _distant_exploration
	)
	if _host_process_id <= 0:
		_failure_message = "Could not start the host process"
		return false
	_process_ids.append(_host_process_id)
	if not await _wait_for_file("host.ready.json", _host_process_id):
		_failure_message = "Host did not become ready"
		return false
	return true


func _run_client_stage(project_path: String) -> bool:
	var port: int = _read_host_port()
	if port <= 0:
		_failure_message = "Host readiness file did not contain a valid port"
		return false
	if not await _launch_clients(project_path, port):
		return false
	if not await _wait_for_capacity_disconnect_and_host_result():
		return false
	if not await _wait_for_remaining_client_results():
		return false
	return await _wait_for_child_exits()


func _launch_clients(project_path: String, port: int) -> bool:
	for client_slot: int in range(1, _client_count + 1):
		var drop_after_connect: bool = client_slot == _client_count and not _distant_exploration
		var client_pid: int = _start_child(
			project_path,
			"client-%d" % client_slot,
			"127.0.0.1",
			port,
			client_slot,
			drop_after_connect,
			true,
			_distant_exploration
		)
		if client_pid <= 0:
			_failure_message = "Could not start client %d" % client_slot
			return false
		_client_process_ids.append(client_pid)
		_process_ids.append(client_pid)
		if not await _wait_for_file("client-%d.ready.json" % client_slot, client_pid):
			_failure_message = (
				"Client %d did not finish late-join terrain initialization" % client_slot
			)
			return false
	return true


func _wait_for_capacity_disconnect_and_host_result() -> bool:
	for client_slot: int in range(1, _client_count + 1):
		if not await _wait_for_file(
			"client-%d.ready.json" % client_slot, _client_process_ids[client_slot - 1]
		):
			_failure_message = "A client did not connect and spawn"
			return false
	if not await _wait_for_file("client-%d.drop.json" % _client_count, _client_process_ids.back()):
		_failure_message = "Disconnecting client did not complete its clean shutdown"
		return false
	if (
		_distant_exploration
		and not await _wait_for_file("client-1.explore.json", _client_process_ids[0])
	):
		_failure_message = "Client did not publish its distant exploration result"
		return false
	if not await _wait_for_file("host.result.json", _host_process_id):
		_failure_message = "Host did not verify capacity, movement, and disconnect cleanup"
		return false
	return true


func _wait_for_remaining_client_results() -> bool:
	for client_slot: int in range(1, _client_count):
		if not await _wait_for_file(
			"client-%d.result.json" % client_slot, _client_process_ids[client_slot - 1]
		):
			_failure_message = "A remaining client did not observe clean host teardown"
			return false
	return true


func _wait_for_child_exits() -> bool:
	if not await _wait_for_exit(_host_process_id):
		_failure_message = "Host process did not exit after scenario completion"
		return false
	for client_index: int in range(_client_count):
		if not await _wait_for_exit(_client_process_ids[client_index]):
			_failure_message = "Client process did not exit after scenario completion"
			return false
	return true


func _verify_results() -> bool:
	if not _result_passed("host.result.json"):
		_failure_message = "Host scenario result was not passing"
		return false
	if not _verify_camera_results():
		return false
	if not _verify_world_results():
		return false
	if not _verify_movement_results():
		return false
	if not _verify_disconnect_results():
		return false
	return _verify_distant_exploration_results() if _distant_exploration else true


func _verify_distant_exploration_results() -> bool:
	var client_result: Variant = _read_result("client-1.explore.json")
	var host_result: Variant = _read_result("host.result.json")
	var target_chunk: Variant = (
		client_result.get("target_chunk") if client_result is Dictionary else null
	)
	if (
		not client_result is Dictionary
		or client_result.get("status") != "passed"
		or int(client_result.get("position_x", 0.0)) < 2016
		or not target_chunk is Array
		or target_chunk.size() != 2
		or int(target_chunk[0]) != 16
		or int(target_chunk[1]) != 0
		or int(client_result.get("loaded_chunk_count", 0)) <= 0
		or not host_result is Dictionary
		or host_result.get("distant_region_chunk_loaded") != true
	):
		_failure_message = "Host and client did not both stream the distant region"
		return false
	return true


func _verify_disconnect_results() -> bool:
	if not _result_passed("client-%d.drop.json" % _client_count):
		_failure_message = "Disconnecting client result was not passing"
		return false
	for client_slot: int in range(1, _client_count):
		if not _result_passed("client-%d.result.json" % client_slot):
			_failure_message = "Client %d did not report clean disconnect" % client_slot
			return false
		if not _result_has_true(
			"client-%d.result.json" % client_slot, "replicated_position_converged"
		):
			_failure_message = (
				"Client %d did not converge to the host movement snapshot" % client_slot
			)
			return false
	return true


func _verify_movement_results() -> bool:
	if not _result_has_true("host.result.json", "grounded_at_spawn"):
		_failure_message = "Host did not ground all spawned characters under standard gravity"
		return false
	if not _result_has_true("host.result.json", "remaining_players_grounded"):
		_failure_message = "Remaining players were not grounded after movement and disconnect"
		return false
	if not _result_has_true("host.result.json", "host_resolved_movement"):
		_failure_message = "Host did not resolve remote movement intents"
		return false
	for client_slot: int in range(1, _client_count):
		if not _result_has_number(
			"client-%d.ready.json" % client_slot,
			"movement_intent_delay_msec",
			SIMULATED_INTENT_DELAY_MSEC
		):
			_failure_message = "Client %d did not exercise delayed movement intents" % client_slot
			return false
	return true


func _verify_world_results() -> bool:
	var host_ready: Variant = _read_result("host.ready.json")
	if not host_ready is Dictionary:
		_failure_message = "Host did not publish its authoritative terrain configuration"
		return false
	if not _verify_host_population(host_ready):
		return false
	var host_biome_samples: Variant = host_ready.get("biome_samples")
	var host_population_fingerprint: int = int(host_ready.get("population_fingerprint", 0))
	for client_slot: int in range(1, _client_count + 1):
		var client_ready: Variant = _read_result("client-%d.ready.json" % client_slot)
		if not client_ready is Dictionary:
			_failure_message = (
				"Client %d did not publish terrain synchronization results" % client_slot
			)
			return false
		if (
			client_ready.get("terrain_seed") != host_ready.get("terrain_seed")
			or client_ready.get("world_config") != host_ready.get("world_config")
			or client_ready.get("terrain_fingerprint") != host_ready.get("terrain_fingerprint")
			or client_ready.get("biome_samples") != host_biome_samples
			or int(client_ready.get("population_fingerprint", 0)) != host_population_fingerprint
			or (
				int(client_ready.get("population_count", 0))
				!= int(host_ready.get("population_count", 0))
			)
			or int(client_ready.get("local_static_prop_registry_count", -1)) != 0
			or int(client_ready.get("loaded_chunk_count", 0)) <= 0
		):
			_failure_message = (
				"Client %d generated terrain that differs from the host" % client_slot
			)
			return false
		if (
			int(client_ready.get("requested_seed", host_ready["terrain_seed"]))
			== int(host_ready["terrain_seed"])
		):
			_failure_message = (
				"Client %d did not test host-overridden terrain seed synchronization" % client_slot
			)
			return false
	return true


func _verify_host_population(host_ready: Dictionary) -> bool:
	var host_biome_samples: Variant = host_ready.get("biome_samples")
	if not host_biome_samples is Dictionary or host_biome_samples.size() < 5:
		_failure_message = "Host did not publish deterministic biome samples"
		return false
	if (
		int(host_ready.get("population_fingerprint", 0)) <= 0
		or int(host_ready.get("population_count", 0)) <= 0
	):
		_failure_message = "Host did not generate a deterministic chunk prop population"
		return false
	var host_result: Variant = _read_result("host.result.json")
	if not host_result is Dictionary or int(host_result.get("active_static_prop_count", 0)) <= 0:
		_failure_message = "Host did not retain authority over streamed static prop identities"
		return false
	return true


func _read_result(file_name: String) -> Variant:
	var path: String = _run_directory.path_join(file_name)
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _verify_camera_results() -> bool:
	if not _result_has_true("host.result.json", "camera_ownership_valid"):
		_failure_message = "Host did not retain exclusive ownership of its local camera"
		return false
	if not _result_has_true("host.result.json", "camera_look_applied"):
		_failure_message = "Host camera did not process local look input"
		return false
	for client_slot: int in range(1, _client_count + 1):
		if not _result_has_true("client-%d.ready.json" % client_slot, "camera_ownership_valid"):
			_failure_message = (
				"Client %d did not retain exclusive ownership of its local camera" % client_slot
			)
			return false
		if not _result_has_true("client-%d.ready.json" % client_slot, "camera_look_applied"):
			_failure_message = "Client %d camera did not process local look input" % client_slot
			return false
	return true


func _read_host_port() -> int:
	var host_ready_path: String = _run_directory.path_join("host.ready.json")
	if not FileAccess.file_exists(host_ready_path):
		return -1
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(host_ready_path))
	if not parsed is Dictionary:
		return -1
	var port_value: Variant = parsed.get("port", -1)
	if typeof(port_value) != TYPE_INT and typeof(port_value) != TYPE_FLOAT:
		return -1
	return int(port_value)


func _start_child(
	project_path: String,
	role: String,
	address: String,
	port: int,
	client_slot: int,
	drop_after_connect: bool,
	drive: bool,
	distant_exploration: bool
) -> int:
	var log_path: String = _run_directory.path_join("%s.log" % role)
	var arguments: PackedStringArray = PackedStringArray(
		["--headless", "--path", project_path, "--log-file", log_path, "--"]
	)
	if role != "host":
		arguments.append("--join=%s" % address)
	if role == "host":
		arguments.append("--e2e-drop-client-slot=%d" % _client_count)
	if client_slot > 0:
		arguments.append("--e2e-client-slot=%d" % client_slot)
	if drop_after_connect:
		arguments.append("--e2e-drop-after-connect")
	if distant_exploration:
		arguments.append("--e2e-distant-exploration")
		if role != "host":
			arguments.append("--e2e-drop-after-exploration")
	if drive:
		arguments.append("--e2e-drive")
		arguments.append("--e2e-intent-delay-ms=%d" % SIMULATED_INTENT_DELAY_MSEC)
	arguments.append("--e2e-camera-look")
	arguments.append("--e2e-role=%s" % ("host" if role == "host" else "client"))
	arguments.append("--e2e-result-dir=%s" % _run_directory)
	arguments.append("--port=%d" % port)
	arguments.append("--max-players=%d" % (2 if distant_exploration else 6))
	arguments.append("--seed=%d" % (HOST_WORLD_SEED if role == "host" else CLIENT_REQUESTED_SEED))
	return OS.create_process(OS.get_executable_path(), arguments, false)


func _wait_for_file(file_name: String, process_id: int) -> bool:
	var path: String = _run_directory.path_join(file_name)
	var deadline_usec: int = Time.get_ticks_usec() + int(PROCESS_TIMEOUT_SEC * 1000000.0)
	while Time.get_ticks_usec() < deadline_usec:
		if FileAccess.file_exists(path):
			return true
		if not OS.is_process_running(process_id):
			return false
		await create_timer(0.05).timeout
	return false


func _wait_for_exit(process_id: int) -> bool:
	var deadline_usec: int = Time.get_ticks_usec() + int(PROCESS_TIMEOUT_SEC * 1000000.0)
	while Time.get_ticks_usec() < deadline_usec:
		if not OS.is_process_running(process_id):
			return OS.get_process_exit_code(process_id) == 0
		await create_timer(0.05).timeout
	return false


func _result_passed(file_name: String) -> bool:
	var path: String = _run_directory.path_join(file_name)
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed is Dictionary and parsed.get("status") == "passed"


func _result_has_true(file_name: String, key: String) -> bool:
	var path: String = _run_directory.path_join(file_name)
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed is Dictionary and parsed.get(key) == true


func _result_has_number(file_name: String, key: String, expected: int) -> bool:
	var path: String = _run_directory.path_join(file_name)
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	var value: Variant = parsed.get(key)
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and int(value) == expected


func _fail(message: String) -> void:
	for process_id: int in _process_ids:
		if OS.is_process_running(process_id):
			OS.kill(process_id)
	var diagnostics: String = ""
	if not _run_directory.is_empty():
		diagnostics = "\nLogs/results retained at %s" % _run_directory
	push_error("M1 multiplayer E2E failed: %s%s" % [message, diagnostics])
	quit(1)
