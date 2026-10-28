class_name ItemDefinition
extends Resource

@export var item_id: String = "generic_scrap"
@export var display_name: String = "Scrap Piece"
@export_range(1, 999, 1) var max_stack: int = 50
@export_range(0.01, 50.0, 0.05) var unit_weight_kg: float = 0.5
@export var category: String = "material"
@export_range(1, 5, 1) var rarity_tier: int = 1


func validate() -> Error:
	if item_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		return ERR_INVALID_DATA
	if max_stack <= 0 or not is_finite(unit_weight_kg) or unit_weight_kg <= 0.0:
		return ERR_INVALID_PARAMETER
	return OK
