extends GutTest


func test_inventory_initialization() -> void:
	var inv: InventoryContainer = InventoryContainer.new(8, 50.0)
	assert_eq(inv.slot_count, 8)
	assert_almost_eq(inv.max_weight_kg, 50.0, 0.01)
	assert_almost_eq(inv.get_total_weight(), 0.0, 0.01)
	for i: int in range(8):
		assert_true(inv.is_slot_empty(i))


func test_add_item_stacking_and_overflow() -> void:
	var inv: InventoryContainer = InventoryContainer.new(3, 40.0)
	# Add 75 wood with max stack 50
	var remainder: int = inv.add_item("wood_lumber", 75, 50, 0.8)
	assert_eq(remainder, 0)

	var slot_0: Dictionary = inv.get_slot(0)
	var slot_1: Dictionary = inv.get_slot(1)
	var slot_2: Dictionary = inv.get_slot(2)

	assert_eq(slot_0["item_id"], "wood_lumber")
	assert_eq(slot_0["count"], 50)
	assert_eq(slot_1["item_id"], "wood_lumber")
	assert_eq(slot_1["count"], 25)
	assert_true(inv.is_slot_empty(2))

	assert_eq(inv.get_item_count("wood_lumber"), 75)
	assert_true(inv.has_item("wood_lumber", 70))
	assert_false(inv.has_item("wood_lumber", 80))


func test_inventory_capacity_remainder() -> void:
	var inv: InventoryContainer = InventoryContainer.new(1, 20.0)
	# Max stack is 10, adding 15
	var remainder: int = inv.add_item("scrap_metal", 15, 10, 1.2)
	assert_eq(remainder, 5)
	assert_eq(inv.get_slot(0)["count"], 10)


func test_remove_item() -> void:
	var inv: InventoryContainer = InventoryContainer.new(4, 30.0)
	inv.add_item("tech_components", 20, 50, 0.4)

	var removed: int = inv.remove_item_by_id("tech_components", 8)
	assert_eq(removed, 8)
	assert_eq(inv.get_item_count("tech_components"), 12)

	# Remove remaining
	inv.remove_item_by_id("tech_components", 20)
	assert_eq(inv.get_item_count("tech_components"), 0)
	assert_true(inv.is_slot_empty(0))


func test_transfer_between_containers() -> void:
	var src_inv: InventoryContainer = InventoryContainer.new(4, 50.0)
	var dst_inv: InventoryContainer = InventoryContainer.new(4, 50.0)

	src_inv.add_item("ice_crystal", 10, 20, 1.5)
	assert_eq(src_inv.get_item_count("ice_crystal"), 10)
	assert_eq(dst_inv.get_item_count("ice_crystal"), 0)

	var moved: bool = src_inv.transfer_slot_to(0, dst_inv, 4)
	assert_true(moved)
	assert_eq(src_inv.get_item_count("ice_crystal"), 6)
	assert_eq(dst_inv.get_item_count("ice_crystal"), 4)


func test_swap_slots() -> void:
	var inv: InventoryContainer = InventoryContainer.new(3, 40.0)
	inv.add_item("wood_lumber", 10, 50, 0.8)
	inv.add_item("scrap_metal", 5, 50, 1.2)

	assert_eq(inv.get_slot(0)["item_id"], "wood_lumber")
	assert_eq(inv.get_slot(1)["item_id"], "scrap_metal")

	inv.swap_slots(0, 1)

	assert_eq(inv.get_slot(0)["item_id"], "scrap_metal")
	assert_eq(inv.get_slot(1)["item_id"], "wood_lumber")


func test_serialization_roundtrip() -> void:
	var inv1: InventoryContainer = InventoryContainer.new(4, 45.0)
	inv1.add_item("void_obsidian", 5, 20, 2.0)
	inv1.add_item("tech_components", 12, 40, 0.4)

	var saved_dict: Dictionary = inv1.to_dictionary()

	var inv2: InventoryContainer = InventoryContainer.new(4, 45.0)
	inv2.from_dictionary(saved_dict)

	assert_eq(inv2.get_item_count("void_obsidian"), 5)
	assert_eq(inv2.get_item_count("tech_components"), 12)
	assert_almost_eq(inv2.get_total_weight(), inv1.get_total_weight(), 0.01)
