extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://entities/npcs/enemy_entity.tscn")
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _enemy: EnemyEntity
var _player: ObserverPlayer


func before_each() -> void:
	_enemy = ENEMY_SCENE.instantiate() as EnemyEntity
	_enemy.position = Vector3(10.0, 0.0, 0.0)
	add_child_autofree(_enemy)

	_player = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player.configure(1, "player_1_1", "TargetPlayer")
	_player.position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(_player)


func test_enemy_detects_player_and_enters_chase() -> void:
	assert_eq(_enemy.current_state, EnemyEntity.State.IDLE)

	_enemy._physics_process(0.1)

	assert_eq(_enemy.target_player, _player)
	assert_eq(_enemy.current_state, EnemyEntity.State.CHASE)
	# Moves towards player at origin (-X direction)
	assert_lt(_enemy.velocity.x, 0.0)


func test_enemy_attacks_when_in_range() -> void:
	# Place player directly in attack range (1.5m)
	_enemy.position = Vector3(1.5, 0.0, 0.0)

	var initial_health: float = _player.health
	_enemy._physics_process(0.1)

	assert_eq(_enemy.current_state, EnemyEntity.State.ATTACK)
	assert_lt(_player.health, initial_health)


func test_enemy_defeat_and_cleanup() -> void:
	assert_gt(_enemy.health, 0.0)

	# Deal lethal 150 damage
	_enemy.apply_damage(150.0, 1)

	assert_almost_eq(_enemy.health, 0.0, 0.01)
	assert_eq(_enemy.current_state, EnemyEntity.State.DEFEATED)
