extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _player_1: ObserverPlayer
var _player_2: ObserverPlayer


func before_each() -> void:
	World.set_seed(17320508)
	World.escape_tracker.configure(5000.0)

	_player_1 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_1.configure(1, "player_1_1", "Escaper1")
	_player_1.position = Vector3(0.0, 250.0, 0.0)
	add_child_autofree(_player_1)

	_player_2 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_2.configure(2, "player_1_2", "Escaper2")
	_player_2.position = Vector3(100.0, 250.0, 0.0)
	add_child_autofree(_player_2)


func test_foot_vault_escape_route_triggers_victory() -> void:
	# Player 1 sprints and vaults over the edge into the abyss
	_player_1.position = Vector3(5006.0, 240.0, 0.0)
	_player_1.velocity = Vector3(10.0, -5.0, 0.0)

	World.escape_tracker.check_player_escape(_player_1, 95.0)

	assert_true(World.escape_tracker.is_match_concluded)
	assert_eq(World.escape_tracker.winner_peer_id, 1)
	assert_eq(World.escape_tracker.victory_reason, "ESCAPE")
	assert_eq(World.escape_tracker.escape_strategy, "FOOT_VAULT")


func test_last_man_standing_when_rival_eliminated() -> void:
	# Player 2 eliminated
	_player_2.is_alive = false

	var living: Array[ObserverPlayer] = [_player_1]
	World.escape_tracker.check_last_man_standing(living, 2)

	assert_true(World.escape_tracker.is_match_concluded)
	assert_eq(World.escape_tracker.winner_peer_id, 1)
	assert_eq(World.escape_tracker.victory_reason, "LAST_ONE_STANDING")
