extends GutTest

const PROP_SCENE: PackedScene = preload("res://entities/props/physical_prop.tscn")
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _prop: PhysicalProp
var _player_1: ObserverPlayer
var _player_2: ObserverPlayer


func before_each() -> void:
	_prop = PROP_SCENE.instantiate() as PhysicalProp
	_prop.position = Vector3(0.0, 2.0, 0.0)
	add_child_autofree(_prop)

	_player_1 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_1.configure(1, "player_1_1", "HostPlayer")
	_player_1.position = Vector3(0.0, 0.0, 3.0)
	add_child_autofree(_player_1)

	_player_2 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_2.configure(2, "player_1_2", "ClientPlayer")
	_player_2.position = Vector3(3.0, 0.0, 0.0)
	add_child_autofree(_player_2)


func test_single_player_grab_and_release() -> void:
	var grab_success: bool = _prop.grab(1, _player_1, 2.5)
	assert_true(grab_success)
	assert_true(_prop.is_held_by(1))
	assert_true(_prop.is_held())
	assert_eq(_prop.get_holder_count(), 1)

	_prop.adjust_distance(1, 0.5)
	var holder_info: Dictionary = _prop._holders[1]
	assert_almost_eq(float(holder_info["distance"]), 3.0, 0.01)

	_prop.release(1)
	assert_false(_prop.is_held_by(1))
	assert_false(_prop.is_held())
	assert_eq(_prop.get_holder_count(), 0)


func test_two_player_coop_grab_and_tug_of_war() -> void:
	# Both players grab simultaneously
	var grab_1: bool = _prop.grab(1, _player_1, 2.0)
	var grab_2: bool = _prop.grab(2, _player_2, 2.0)

	assert_true(grab_1)
	assert_true(grab_2)
	assert_eq(_prop.get_holder_count(), 2)
	assert_true(_prop.is_held_by(1))
	assert_true(_prop.is_held_by(2))

	# A 3rd player attempts grab - should be rejected (max 2 players)
	var grab_3: bool = _prop.grab(3, _player_1, 2.0)
	assert_false(grab_3)
	assert_eq(_prop.get_holder_count(), 2)

	# Player 1 releases; Player 2 still holds
	_prop.release(1)
	assert_false(_prop.is_held_by(1))
	assert_true(_prop.is_held_by(2))
	assert_eq(_prop.get_holder_count(), 1)


func test_throw_applies_velocity_and_clears_holder() -> void:
	_prop.grab(1, _player_1, 2.0)
	assert_true(_prop.is_held_by(1))

	var aim_dir: Vector3 = Vector3(0.0, 0.2, -1.0).normalized()
	_prop.throw_prop(1, aim_dir, Vector3.ZERO)

	assert_false(_prop.is_held_by(1))
	assert_false(_prop.is_held())
	assert_eq(_prop.get_last_thrower_peer_id(), 1)
	assert_gt(_prop.linear_velocity.length(), 5.0)


func test_player_damage_and_death_releases_prop() -> void:
	_player_1.grab_prop_host(_prop)
	assert_true(_prop.is_held_by(1))

	# Player takes 40 damage
	_player_1.apply_damage(40.0, 2)
	assert_almost_eq(_player_1.health, 60.0, 0.01)
	assert_true(_player_1.is_alive)
	assert_true(_prop.is_held_by(1))

	# Player takes lethal 80 damage
	_player_1.apply_damage(80.0, 2)
	assert_almost_eq(_player_1.health, 0.0, 0.01)
	assert_false(_player_1.is_alive)

	# Prop must be automatically released on death
	assert_false(_prop.is_held_by(1))
	assert_false(_prop.is_held())
