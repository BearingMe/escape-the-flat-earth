extends CanvasLayer

const UPDATE_INTERVAL_SEC: float = 0.25

var _time_until_update: float = 0.0

@onready var _label: Label = %DebugLabel


func _process(delta: float) -> void:
	_time_until_update -= delta
	if _time_until_update > 0.0:
		return
	_time_until_update = UPDATE_INTERVAL_SEC
	var local_player: ObserverPlayer = _find_local_player()
	var gravity_vector: Vector3 = Vector3.ZERO
	var position_text: String = "spectator unavailable"
	if local_player != null:
		gravity_vector = Gravity.gravity_at(local_player.global_position)
		position_text = "position: %s" % local_player.global_position
	var role_text: String = "offline"
	if Net.session_role == "host":
		role_text = "host"
	elif Net.session_role == "client":
		role_text = "client"
	_label.text = (
		"Arowana — Disk & Multiplayer Foundation\n"
		+ (
			"role: %s | session: %s | players: %d/%d\n"
			% [role_text, Net.session_status, Net.player_count(), World.config.max_players]
		)
	)
	_label.text += "gravity: %s m/s²\n" % gravity_vector
	_label.text += (
		"%s\nWASD move · Space/Ctrl rise/fall · mouse look · Esc release mouse" % position_text
	)


func _find_local_player() -> ObserverPlayer:
	if multiplayer.multiplayer_peer == null:
		return null
	for child: Node in get_tree().get_nodes_in_group("network_players"):
		if child is ObserverPlayer and child.peer_id == multiplayer.get_unique_id():
			return child
	return null
