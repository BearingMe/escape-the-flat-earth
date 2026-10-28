class_name EscapeTracker
extends RefCounted

signal match_concluded(winner_peer_id: int, victory_reason: String, escape_strategy: String)

const BOUNDARY_MARGIN_M: float = 2.0

var disk_radius_m: float = 5000.0
var is_match_concluded: bool = false
var winner_peer_id: int = 0
var victory_reason: String = ""
var escape_strategy: String = ""
var escape_time_sec: float = 0.0


func configure(radius_m: float) -> void:
	disk_radius_m = maxf(radius_m, 100.0)
	is_match_concluded = false
	winner_peer_id = 0
	victory_reason = ""
	escape_strategy = ""
	escape_time_sec = 0.0


static func is_past_disk_boundary(world_pos: Vector3, disk_radius: float) -> bool:
	if not world_pos.is_finite():
		return false
	var r_sq: float = world_pos.x * world_pos.x + world_pos.z * world_pos.z
	var threshold: float = disk_radius + BOUNDARY_MARGIN_M
	return r_sq > (threshold * threshold)


func check_player_escape(player: ObserverPlayer, current_match_time: float) -> bool:
	if is_match_concluded or player == null or not player.is_alive:
		return false

	if is_past_disk_boundary(player.global_position, disk_radius_m):
		is_match_concluded = true
		winner_peer_id = player.peer_id
		victory_reason = "ESCAPE"
		escape_time_sec = current_match_time

		# Identify escape strategy
		if player.carrier_peer_id > 0:
			escape_strategy = "VEHICULAR_LAUNCH"
		elif player.movement_state == PlayerTraversalState.State.CLIMBING:
			escape_strategy = "ENDURANCE_CLIMB"
		else:
			escape_strategy = "FOOT_VAULT"

		match_concluded.emit(winner_peer_id, victory_reason, escape_strategy)
		return true

	return false


func check_last_man_standing(
	living_players: Array[ObserverPlayer], initial_player_count: int
) -> bool:
	if is_match_concluded or initial_player_count < 2:
		return false

	if living_players.size() == 1:
		var last_player: ObserverPlayer = living_players[0]
		if last_player != null and last_player.is_alive:
			is_match_concluded = true
			winner_peer_id = last_player.peer_id
			victory_reason = "LAST_ONE_STANDING"
			escape_strategy = "SURVIVAL_ATTRITION"
			match_concluded.emit(winner_peer_id, victory_reason, escape_strategy)
			return true

	return false


func reset() -> void:
	is_match_concluded = false
	winner_peer_id = 0
	victory_reason = ""
	escape_strategy = ""
	escape_time_sec = 0.0
