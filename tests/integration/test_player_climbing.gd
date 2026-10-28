extends GutTest

const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _player: ObserverPlayer
var _wall: StaticBody3D


func before_each() -> void:
	_player = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player.configure(1, "player_1_1", "HostPlayer")
	_player.position = Vector3(0.0, 2.0, 0.0)
	add_child_autofree(_player)

	# Create a vertical wall 0.8m in front of the player (facing down -Z)
	_wall = StaticBody3D.new()
	_wall.position = Vector3(0.0, 2.0, -0.8)
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 10.0, 0.4)
	col.shape = box
	_wall.add_child(col)
	add_child_autofree(_wall)


func test_climbing_state_progression_and_stamina_depletion() -> void:
	_player.movement_state = PlayerTraversalState.State.CLIMBING
	_player.climb_stamina_sec = 1.0

	# Step 0.5 sec
	_player._simulate_authoritative_movement(0.5)
	assert_eq(_player.movement_state, PlayerTraversalState.State.CLIMBING)
	assert_almost_eq(_player.velocity.y, PlayerTraversalState.CLIMB_SPEED_M_S, 0.01)
	assert_almost_eq(_player.climb_stamina_sec, 0.5, 0.01)

	# Step another 0.6 sec -> stamina depletes
	_player._simulate_authoritative_movement(0.6)
	assert_eq(_player.movement_state, PlayerTraversalState.State.NORMAL)
