extends GutTest

const STATION_SCENE: PackedScene = preload("res://entities/props/crafting_station.tscn")
const OBSERVER_SCENE: PackedScene = preload("res://entities/player/observer.tscn")

var _station: CraftingStation
var _player_1: ObserverPlayer
var _player_2: ObserverPlayer


func before_each() -> void:
	_station = STATION_SCENE.instantiate() as CraftingStation
	add_child_autofree(_station)

	_player_1 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_1.configure(1, "player_1_1", "Crafter1")
	add_child_autofree(_player_1)

	_player_2 = OBSERVER_SCENE.instantiate() as ObserverPlayer
	_player_2.configure(2, "player_1_2", "Crafter2")
	add_child_autofree(_player_2)


func test_workbench_craft_execution() -> void:
	# Add materials for steam megaphone (5 scrap, 2 tech)
	_player_1.inventory.add_item(SalvageDistribution.ITEM_SCRAP, 5, 50, 1.2)
	_player_1.inventory.add_item(SalvageDistribution.ITEM_TECH, 2, 40, 0.4)

	var res: Dictionary = _station.execute_craft(_player_1, "craft_steam_megaphone")
	assert_true(res.get("success", false))

	# Ingredients consumed
	assert_eq(_player_1.inventory.get_item_count(SalvageDistribution.ITEM_SCRAP), 0)
	assert_eq(_player_1.inventory.get_item_count(SalvageDistribution.ITEM_TECH), 0)
	# Crafted output added
	assert_eq(_player_1.inventory.get_item_count("steam_megaphone"), 1)


func test_craft_rejected_on_missing_materials() -> void:
	# Player 2 has no materials
	var res: Dictionary = _station.execute_craft(_player_2, "craft_climbing_grapple")
	assert_false(res.get("success", true))
	assert_eq(res.get("error", ""), "prerequisites_not_met")
