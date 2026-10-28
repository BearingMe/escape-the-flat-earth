class_name CraftingCatalog
extends RefCounted


static func all_recipes() -> Array[CraftingRecipe]:
	return [
		create_bandage_kit_recipe(),
		create_climbing_grapple_recipe(),
		create_thermal_insulation_recipe(),
		create_steam_megaphone_recipe(),
		create_firmament_sensor_recipe(),
	]


static func get_recipe(recipe_id: String) -> CraftingRecipe:
	for r: CraftingRecipe in all_recipes():
		if r.recipe_id == recipe_id:
			return r
	return null


static func get_available_recipes(
	inventory: InventoryContainer, station_type: String
) -> Array[CraftingRecipe]:
	var available: Array[CraftingRecipe] = []
	for r: CraftingRecipe in all_recipes():
		if r.can_craft(inventory, station_type):
			available.append(r)
	return available


static func create_bandage_kit_recipe() -> CraftingRecipe:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "craft_medical_kit"
	r.display_name = "Improvised Medical Kit"
	r.station_required = ""
	r.ingredients = {
		SalvageDistribution.ITEM_SCRAP: 2,
		SalvageDistribution.ITEM_WOOD: 2,
	}
	r.output_item_id = "medical_kit"
	r.output_count = 1
	r.default_durability = 0.0
	return r


static func create_climbing_grapple_recipe() -> CraftingRecipe:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "craft_climbing_grapple"
	r.display_name = "Reinforced Climbing Grapple"
	r.station_required = "workbench"
	r.ingredients = {
		SalvageDistribution.ITEM_SCRAP: 4,
		SalvageDistribution.ITEM_WOOD: 3,
		SalvageDistribution.ITEM_TECH: 1,
	}
	r.output_item_id = "climbing_grapple"
	r.output_count = 1
	r.default_durability = 100.0
	return r


static func create_thermal_insulation_recipe() -> CraftingRecipe:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "craft_thermal_insulation"
	r.display_name = "Perimeter Thermal Wrap"
	r.station_required = "workbench"
	r.ingredients = {
		SalvageDistribution.ITEM_SCRAP: 2,
		SalvageDistribution.ITEM_WOOD: 3,
		SalvageDistribution.ITEM_ICE_CRYSTAL: 1,
	}
	r.output_item_id = "thermal_insulation"
	r.output_count = 1
	r.default_durability = 100.0
	return r


static func create_steam_megaphone_recipe() -> CraftingRecipe:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "craft_steam_megaphone"
	r.display_name = "Steam-Powered Sonic Megaphone"
	r.station_required = "workbench"
	r.ingredients = {
		SalvageDistribution.ITEM_SCRAP: 5,
		SalvageDistribution.ITEM_TECH: 2,
	}
	r.output_item_id = "steam_megaphone"
	r.output_count = 1
	r.default_durability = 100.0
	return r


static func create_firmament_sensor_recipe() -> CraftingRecipe:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "craft_firmament_sensor"
	r.display_name = "Firmament Geodetic Sensor"
	r.station_required = "workbench"
	r.ingredients = {
		SalvageDistribution.ITEM_TECH: 2,
		SalvageDistribution.ITEM_ICE_CRYSTAL: 1,
		SalvageDistribution.ITEM_VOID_OBSIDIAN: 1,
	}
	r.output_item_id = "firmament_sensor"
	r.output_count = 1
	r.default_durability = 100.0
	return r
