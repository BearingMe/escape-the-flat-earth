extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _tracker: EscapeTracker
var _player: ObserverPlayer


func before_each() -> void:
	_tracker = EscapeTracker.new()
	_tracker.configure(5000.0)

	_player = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player.configure(1, "player_1_1", "Runner")
	add_child_autofree(_player)


func test_boundary_calculation() -> void:
	# Inside disk (r = 4990m)
	assert_false(EscapeTracker.is_past_disk_boundary(Vector3(4990.0, 0.0, 0.0), 5000.0))

	# Just past disk boundary (r = 5003m > 5000 + 2m margin)
	assert_true(EscapeTracker.is_past_disk_boundary(Vector3(5003.0, 0.0, 0.0), 5000.0))


func test_foot_vault_escape_detection() -> void:
	_player.position = Vector3(5005.0, 200.0, 0.0)

	var escaped: bool = _tracker.check_player_escape(_player, 120.0)
	assert_true(escaped)
	assert_true(_tracker.is_match_concluded)
	assert_eq(_tracker.winner_peer_id, 1)
	assert_eq(_tracker.victory_reason, "ESCAPE")
	assert_eq(_tracker.escape_strategy, "FOOT_VAULT")


func test_climbing_escape_detection() -> void:
	_player.position = Vector3(5005.0, 260.0, 0.0)
	_player.movement_state = PlayerTraversalState.State.CLIMBING

	var escaped: bool = _tracker.check_player_escape(_player, 150.0)
	assert_true(escaped)
	assert_eq(_tracker.escape_strategy, "ENDURANCE_CLIMB")


func test_vehicular_launch_escape_detection() -> void:
	_player.position = Vector3(5010.0, 150.0, 0.0)
	_player.carrier_peer_id = 99  # Inside vehicle

	var escaped: bool = _tracker.check_player_escape(_player, 85.0)
	assert_true(escaped)
	assert_eq(_tracker.escape_strategy, "VEHICULAR_LAUNCH")


func test_last_one_standing_fallback() -> void:
	var living: Array[ObserverPlayer] = [_player]
	var initial_players: int = 3

	var won: bool = _tracker.check_last_man_standing(living, initial_players)
	assert_true(won)
	assert_true(_tracker.is_match_concluded)
	assert_eq(_tracker.winner_peer_id, 1)
	assert_eq(_tracker.victory_reason, "LAST_ONE_STANDING")
