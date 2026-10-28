extends GutTest


func test_recipe_validation() -> void:
	var r: CraftingRecipe = CraftingRecipe.new()
	assert_eq(r.validate(), ERR_INVALID_DATA)

	r.recipe_id = "test_recipe"
	r.display_name = "Test Recipe"
	r.output_item_id = "test_output"
	r.output_count = 1
	r.ingredients = {"scrap_metal": 3}
	assert_eq(r.validate(), OK)


func test_can_craft_checks_station_and_materials() -> void:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "bench_item"
	r.display_name = "Bench Item"
	r.station_required = "workbench"
	r.output_item_id = "bench_output"
	r.ingredients = {"wood_lumber": 4}

	var inv: InventoryContainer = InventoryContainer.new(4, 50.0)

	# Fails: wrong station
	assert_false(r.can_craft(inv, ""))

	# Fails: missing materials
	assert_false(r.can_craft(inv, "workbench"))

	# Add materials -> passes
	inv.add_item("wood_lumber", 4, 50, 0.8)
	assert_true(r.can_craft(inv, "workbench"))


func test_execute_craft_deducts_and_creates_output() -> void:
	var r: CraftingRecipe = CraftingRecipe.new()
	r.recipe_id = "med_craft"
	r.display_name = "Med Craft"
	r.station_required = ""
	r.output_item_id = "medical_kit"
	r.output_count = 1
	r.ingredients = {"scrap_metal": 2, "wood_lumber": 2}
	r.default_durability = 80.0

	var inv: InventoryContainer = InventoryContainer.new(4, 50.0)
	inv.add_item("scrap_metal", 5, 50, 1.2)
	inv.add_item("wood_lumber", 5, 50, 0.8)

	var res: Dictionary = r.execute_craft(inv, "")
	assert_true(res["success"])
	assert_eq(inv.get_item_count("scrap_metal"), 3)
	assert_eq(inv.get_item_count("wood_lumber"), 3)
	assert_eq(inv.get_item_count("medical_kit"), 1)

	var slot: Dictionary = inv.get_slot(2)
	assert_eq(slot["item_id"], "medical_kit")
	assert_almost_eq(float(slot["metadata"].get("durability", 0.0)), 80.0, 0.01)
