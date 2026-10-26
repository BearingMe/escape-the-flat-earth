extends Node

signal player_count_changed(count: int)
signal session_status_changed(status: String)

const DEFAULT_PORT: int = 24567
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var session_role: String = "offline"
var session_status: String = "offline"
var last_error: Error = OK

var _spawn_root: Node3D
var _spawner: MultiplayerSpawner
var _max_players: int = 6


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func bind_world(spawn_root: Node3D, spawner: MultiplayerSpawner) -> Error:
	if spawn_root == null or spawner == null or not is_instance_valid(spawn_root):
		return ERR_INVALID_PARAMETER
	if _spawn_root != null and is_instance_valid(_spawn_root):
		return ERR_ALREADY_IN_USE
	_spawn_root = spawn_root
	_spawner = spawner
	_spawner.spawn_path = NodePath("..")
	_spawner.spawn_function = Callable(self, "_create_observer")
	_spawner.add_spawnable_scene("res://entities/player/observer.tscn")
	return OK


func host(port: int = DEFAULT_PORT, maximum_players: int = -1) -> Error:
	if not _can_start_session():
		return ERR_ALREADY_IN_USE
	if port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	var total_player_limit: int = (
		World.config.max_players if maximum_players < 0 else maximum_players
	)
	if total_player_limit < 2 or total_player_limit > 6:
		return ERR_INVALID_PARAMETER
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_server(port, total_player_limit - 1)
	if result != OK:
		last_error = result
		return result
	_max_players = total_player_limit
	multiplayer.multiplayer_peer = peer
	session_role = "host"
	last_error = OK
	_set_status("hosting")
	if not _spawn_player(1):
		end_session()
		return ERR_CANT_CREATE
	_emit_player_count()
	return OK


func join(address: String, port: int = DEFAULT_PORT) -> Error:
	if not _can_start_session():
		return ERR_ALREADY_IN_USE
	var target_address: String = address.strip_edges()
	if target_address.is_empty() or port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_client(target_address, port)
	if result != OK:
		last_error = result
		return result
	multiplayer.multiplayer_peer = peer
	session_role = "client"
	last_error = OK
	_set_status("connecting")
	return OK


func end_session() -> void:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		peer.close()
	multiplayer.multiplayer_peer = null
	_clear_spawned_players()
	session_role = "offline"
	last_error = OK
	_set_status("offline")
	_emit_player_count()


func player_count() -> int:
	if _spawn_root == null or not is_instance_valid(_spawn_root):
		return 0
	var count: int = 0
	for child: Node in _spawn_root.get_children():
		if child is ObserverPlayer:
			count += 1
	return count


func is_session_active() -> bool:
	return session_role != "offline"


func _can_start_session() -> bool:
	return (
		not is_session_active()
		and _spawn_root != null
		and is_instance_valid(_spawn_root)
		and _spawner != null
		and is_instance_valid(_spawner)
	)


func _spawn_player(peer_id: int) -> bool:
	if not multiplayer.is_server() or peer_id < 1:
		return false
	if _spawn_root.has_node("Player_%d" % peer_id):
		return true
	var player_name: String = "Observer %d" % peer_id
	var stable_id: String = World.allocate_stable_id("player")
	if stable_id.is_empty():
		return false
	var spawned: Node = _spawner.spawn(
		{
			"peer_id": peer_id,
			"display_name": player_name,
			"stable_id": stable_id,
			"world_config": World.config.to_dictionary()
		}
	)
	return spawned is ObserverPlayer


func _create_observer(data: Variant) -> Node:
	if not data is Dictionary:
		return null
	var peer_id: int = int(data.get("peer_id", 0))
	var display_name: String = str(data.get("display_name", ""))
	var stable_id: String = str(data.get("stable_id", ""))
	var world_config_data: Variant = data.get("world_config")
	if (
		peer_id < 1
		or display_name.is_empty()
		or stable_id.is_empty()
		or not world_config_data is Dictionary
	):
		return null
	var synced_config: WorldConfig = WorldConfig.from_dictionary(world_config_data)
	if synced_config == null:
		Log.error("network.invalid_world_config_spawn", {"peer_id": peer_id})
		return null
	World.config = synced_config
	for disk_node: Node in get_tree().get_nodes_in_group("world_disks"):
		var disk_result: Error = disk_node.call("configure", synced_config)
		if disk_result != OK:
			Log.error("network.world_disk_resync_failed", {"error": disk_result})
			return null
	var observer: ObserverPlayer = OBSERVER_SCENE.instantiate() as ObserverPlayer
	if observer == null:
		return null
	observer.name = "Player_%d" % peer_id
	observer.configure(peer_id, stable_id, display_name)
	observer.set_multiplayer_authority(1, true)
	return observer


func _despawn_player(peer_id: int) -> void:
	if _spawn_root == null or not is_instance_valid(_spawn_root):
		return
	var observer: Node = _spawn_root.get_node_or_null("Player_%d" % peer_id)
	if observer != null:
		observer.queue_free()
		_emit_player_count(player_count() - 1)


func _clear_spawned_players() -> void:
	if _spawn_root == null or not is_instance_valid(_spawn_root):
		return
	for child: Node in _spawn_root.get_children():
		if child != _spawner:
			child.queue_free()


func _emit_player_count(forced_count: int = -1) -> void:
	player_count_changed.emit(
		maxi(0, player_count()) if forced_count < 0 else maxi(0, forced_count)
	)


func _set_status(status: String) -> void:
	session_status = status
	session_status_changed.emit(status)


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if player_count() >= _max_players:
		return
	if _spawn_player(peer_id):
		_emit_player_count()
	else:
		Log.error("network.player_spawn_failed", {"peer_id": peer_id})


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		_despawn_player(peer_id)


func _on_connected_to_server() -> void:
	last_error = OK
	_set_status("connected")


func _on_connection_failed() -> void:
	last_error = ERR_CANT_CONNECT
	end_session()
	last_error = ERR_CANT_CONNECT
	_set_status("connection_failed")


func _on_server_disconnected() -> void:
	end_session()
	_set_status("server_disconnected")
