extends GutTest


func test_interior_loot_table_composition() -> void:
	# Center basin (ratio = 0.2, surface)
	var table: Array[Dictionary] = SalvageDistribution.get_zone_loot_table(0.2, false)
	assert_gt(table.size(), 0)

	var has_wood: bool = false
	var has_scrap: bool = false
	for entry: Dictionary in table:
		if entry["item_id"] == SalvageDistribution.ITEM_WOOD:
			has_wood = true
		if entry["item_id"] == SalvageDistribution.ITEM_SCRAP:
			has_scrap = true

	assert_true(has_wood)
	assert_true(has_scrap)


func test_rim_loot_table_drops_ice_crystal() -> void:
	# Rim ice wall (ratio = 0.95, surface)
	var table: Array[Dictionary] = SalvageDistribution.get_zone_loot_table(0.95, false)

	var has_ice_crystal: bool = false
	for entry: Dictionary in table:
		if entry["item_id"] == SalvageDistribution.ITEM_ICE_CRYSTAL:
			has_ice_crystal = true
	assert_true(has_ice_crystal)


func test_underside_loot_table_drops_void_obsidian() -> void:
	# Underside
	var table: Array[Dictionary] = SalvageDistribution.get_zone_loot_table(0.4, true)

	var has_void_obsidian: bool = false
	for entry: Dictionary in table:
		if entry["item_id"] == SalvageDistribution.ITEM_VOID_OBSIDIAN:
			has_void_obsidian = true
	assert_true(has_void_obsidian)


func test_sampling_determinism() -> void:
	var pos: Vector3 = Vector3(4800.0, 250.0, 0.0)
	var drop1: Dictionary = SalvageDistribution.sample_loot_at(pos, 5000.0, 0.1)
	var drop2: Dictionary = SalvageDistribution.sample_loot_at(pos, 5000.0, 0.1)

	assert_eq(drop1["item_id"], drop2["item_id"])
	assert_eq(drop1["item_id"], SalvageDistribution.ITEM_ICE_CRYSTAL)
