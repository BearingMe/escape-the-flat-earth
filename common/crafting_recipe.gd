class_name CraftingRecipe
extends Resource

@export var recipe_id: String = ""
@export var display_name: String = ""
@export var station_required: String = ""
@export var ingredients: Dictionary = {}
@export var output_item_id: String = ""
@export var output_count: int = 1
@export var default_durability: float = 100.0


func validate() -> Error:
	var invalid_header: bool = (
		recipe_id.strip_edges().is_empty()
		or display_name.strip_edges().is_empty()
		or output_item_id.strip_edges().is_empty()
		or output_count <= 0
		or ingredients.is_empty()
	)
	if invalid_header:
		return ERR_INVALID_DATA

	for mat_id: Variant in ingredients:
		var count: Variant = ingredients[mat_id]
		var invalid_entry: bool = (
			not mat_id is String
			or str(mat_id).strip_edges().is_empty()
			or (typeof(count) != TYPE_INT and typeof(count) != TYPE_FLOAT)
			or int(count) <= 0
		)
		if invalid_entry:
			return ERR_INVALID_DATA

	return OK


func can_craft(inventory: InventoryContainer, current_station: String) -> bool:
	if inventory == null:
		return false
	if not station_required.is_empty() and station_required != current_station:
		return false
	for mat_id: String in ingredients:
		var needed: int = int(ingredients[mat_id])
		if not inventory.has_item(mat_id, needed):
			return false
	return true


func execute_craft(inventory: InventoryContainer, current_station: String) -> Dictionary:
	if not can_craft(inventory, current_station):
		return {"success": false, "error": "missing_prerequisites"}

	# 1. Deduct ingredients atomically
	for mat_id: String in ingredients:
		var needed: int = int(ingredients[mat_id])
		var removed: int = inventory.remove_item_by_id(mat_id, needed)
		if removed != needed:
			# Safety rollback in the impossible event of inventory mismatch
			return {"success": false, "error": "deduction_failed"}

	# 2. Add output to inventory
	var metadata: Dictionary = {}
	if default_durability > 0.0:
		metadata["durability"] = default_durability
		metadata["max_durability"] = default_durability

	var remainder: int = inventory.add_item(output_item_id, output_count, 50, 0.8, metadata)

	return {
		"success": true,
		"output_item_id": output_item_id,
		"output_count": output_count,
		"overflow_count": remainder,
		"metadata": metadata,
	}
