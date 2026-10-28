class_name PhysicalPropDefinition
extends Resource

@export var prop_id: String = "generic_prop"
@export var display_name: String = "Physical Prop"
@export_range(0.5, 500.0, 0.5) var mass_kg: float = 15.0
@export_range(1.0, 6.0, 0.1) var max_grab_distance_m: float = 3.5
@export_range(2.0, 30.0, 0.5) var base_throw_impulse: float = 16.0
@export_range(0.01, 1.0, 0.01) var damage_multiplier: float = 0.06
@export var is_two_handed: bool = false
@export_range(0.0, 1.0, 0.05) var friction: float = 0.5
@export_range(0.0, 1.0, 0.05) var bounce: float = 0.2


func validate() -> Error:
	if prop_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		return ERR_INVALID_DATA
	if not is_finite(mass_kg) or mass_kg <= 0.0:
		return ERR_INVALID_PARAMETER
	if not is_finite(max_grab_distance_m) or max_grab_distance_m <= 0.0:
		return ERR_INVALID_PARAMETER
	if not is_finite(base_throw_impulse) or base_throw_impulse < 0.0:
		return ERR_INVALID_PARAMETER
	if not is_finite(damage_multiplier) or damage_multiplier <= 0.0:
		return ERR_INVALID_PARAMETER
	return OK
