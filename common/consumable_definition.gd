class_name ConsumableDefinition
extends Resource

@export var item_id: String = "canned_beans"
@export var display_name: String = "Canned Beans"
@export_range(0.0, 100.0, 1.0) var nutrition_value: float = 35.0
@export_range(0.0, 100.0, 1.0) var hydration_value: float = 10.0
@export_range(0.0, 100.0, 1.0) var health_value: float = 5.0
@export_range(-10.0, 10.0, 0.5) var thermal_modifier_c: float = 0.5


func validate() -> Error:
	if item_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		return ERR_INVALID_DATA
	if (
		not is_finite(nutrition_value)
		or not is_finite(hydration_value)
		or not is_finite(health_value)
	):
		return ERR_INVALID_PARAMETER
	return OK
