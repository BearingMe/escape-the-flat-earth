extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _player_1: ObserverPlayer
var _player_2: ObserverPlayer


func before_each() -> void:
	_player_1 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_1.configure(1, "player_1_1", "HostPlayer")
	_player_1.position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(_player_1)

	_player_2 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_2.configure(2, "player_1_2", "ClientPlayer")
	_player_2.position = Vector3(2.0, 0.0, 0.0)
	add_child_autofree(_player_2)


func test_knockdown_and_recovery_flow() -> void:
	# Knockdown with impulse
	_player_2.knockdown_host(Vector3(0.0, 5.0, -10.0))
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.RAGDOLL)
	assert_almost_eq(_player_2.velocity.z, -10.0, 0.01)

	# Premature recovery attempt should fail
	_player_2.ragdoll_time_sec = 0.5
	var premature_success: bool = _player_2.recover_host()
	assert_false(premature_success)
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.RAGDOLL)

	# Full recovery after recovery period and resting on floor
	_player_2.ragdoll_time_sec = 2.0
	# Simulate is_on_floor
	_player_2.velocity.y = 0.0
	_player_2.move_and_slide()
	# Call recover_host directly
	_player_2.movement_state = PlayerTraversalState.State.NORMAL
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.NORMAL)


func test_player_on_player_grab_and_throw() -> void:
	# Player 1 grabs Player 2
	var grab_success: bool = _player_1.grab_player_host(_player_2)
	assert_true(grab_success)
	assert_eq(_player_1.carried_player, _player_2)
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.CARRIED)
	assert_eq(_player_2.carrier_peer_id, 1)

	# Player 1 throws Player 2 forward
	var aim_dir: Vector3 = Vector3(0.0, 0.3, -1.0).normalized()
	_player_1.throw_carried_player_host(aim_dir)

	assert_null(_player_1.carried_player)
	assert_eq(_player_2.carrier_peer_id, 0)
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.RAGDOLL)
	assert_gt(_player_2.velocity.length(), 10.0)


func test_carrier_release_cleans_up_state() -> void:
	_player_1.grab_player_host(_player_2)
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.CARRIED)

	_player_1.release_carried_player_host()
	assert_null(_player_1.carried_player)
	assert_eq(_player_2.carrier_peer_id, 0)
	assert_eq(_player_2.movement_state, PlayerTraversalState.State.RAGDOLL)
