extends GutTest

const LOOT_CONTAINER_SCENE: PackedScene = preload("res://entities/props/loot_container.tscn")
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _container: LootContainer
var _player_1: ObserverPlayer
var _player_2: ObserverPlayer


func before_each() -> void:
	_container = LOOT_CONTAINER_SCENE.instantiate() as LootContainer
	add_child_autofree(_container)

	_player_1 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_1.configure(1, "player_1_1", "Looter1")
	add_child_autofree(_player_1)

	_player_2 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_2.configure(2, "player_1_2", "Looter2")
	add_child_autofree(_player_2)


func test_transfer_to_and_from_player() -> void:
	_container.inventory.add_item("scrap_metal", 20, 50, 1.2)
	assert_eq(_container.inventory.get_item_count("scrap_metal"), 20)
	assert_eq(_player_1.inventory.get_item_count("scrap_metal"), 0)

	# Player takes 15 scrap from container
	var moved_to_player: bool = _container.transfer_to_player(0, _player_1, 15)
	assert_true(moved_to_player)
	assert_eq(_container.inventory.get_item_count("scrap_metal"), 5)
	assert_eq(_player_1.inventory.get_item_count("scrap_metal"), 15)

	# Player stores 10 scrap back into container
	var moved_to_container: bool = _container.transfer_from_player(0, _player_1, 10)
	assert_true(moved_to_container)
	assert_eq(_container.inventory.get_item_count("scrap_metal"), 15)
	assert_eq(_player_1.inventory.get_item_count("scrap_metal"), 5)


func test_concurrent_access_no_duplication() -> void:
	# Single item in container slot 0
	_container.inventory.add_item("void_obsidian", 1, 10, 2.0)
	assert_eq(_container.inventory.get_item_count("void_obsidian"), 1)

	# Player 1 takes it
	var p1_success: bool = _container.transfer_to_player(0, _player_1, 1)
	assert_true(p1_success)

	# Player 2 attempts to take the same item from empty slot 0
	var p2_success: bool = _container.transfer_to_player(0, _player_2, 1)
	assert_false(p2_success)

	# Exactly 1 player received the item, 0 duplication
	assert_eq(_player_1.inventory.get_item_count("void_obsidian"), 1)
	assert_eq(_player_2.inventory.get_item_count("void_obsidian"), 0)
	assert_eq(_container.inventory.get_item_count("void_obsidian"), 0)
