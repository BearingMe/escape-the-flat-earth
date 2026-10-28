class_name CraftingStation
extends StaticBody3D

signal craft_completed(peer_id: int, recipe_id: String, success: bool)

@export var station_type: String = "workbench"
@export var station_name: String = "Expedition Workbench"


func execute_craft(player: ObserverPlayer, recipe_id: String) -> Dictionary:
	if player == null or player.inventory == null:
		return {"success": false, "error": "invalid_player"}

	var recipe: CraftingRecipe = CraftingCatalog.get_recipe(recipe_id)
	if recipe == null:
		return {"success": false, "error": "unknown_recipe"}

	if not recipe.can_craft(player.inventory, station_type):
		return {"success": false, "error": "prerequisites_not_met"}

	var result: Dictionary = recipe.execute_craft(player.inventory, station_type)
	craft_completed.emit(player.peer_id, recipe_id, result.get("success", false))
	return result
