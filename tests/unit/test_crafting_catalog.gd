extends GutTest


func test_all_catalog_recipes_valid() -> void:
	var recipes: Array[CraftingRecipe] = CraftingCatalog.all_recipes()
	assert_gt(recipes.size(), 3)
	for r: CraftingRecipe in recipes:
		assert_eq(r.validate(), OK, "Recipe %s should be valid" % r.recipe_id)


func test_recipe_query_by_id() -> void:
	var grapple: CraftingRecipe = CraftingCatalog.get_recipe("craft_climbing_grapple")
	assert_not_null(grapple)
	assert_eq(grapple.output_item_id, "climbing_grapple")
	assert_eq(grapple.station_required, "workbench")


func test_available_recipes_filtering() -> void:
	var inv: InventoryContainer = InventoryContainer.new(4, 50.0)
	inv.add_item(SalvageDistribution.ITEM_SCRAP, 2, 50, 1.2)
	inv.add_item(SalvageDistribution.ITEM_WOOD, 2, 50, 0.8)

	var hand_recipes: Array[CraftingRecipe] = CraftingCatalog.get_available_recipes(inv, "")
	assert_eq(hand_recipes.size(), 1)
	assert_eq(hand_recipes[0].recipe_id, "craft_medical_kit")
