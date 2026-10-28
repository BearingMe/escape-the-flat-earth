class_name ConstructionPartDefinition
extends Resource

@export var part_type_id: String = "wood_beam"
@export var display_name: String = "Wood Support Beam"
@export_range(1.0, 500.0, 1.0) var mass_kg: float = 20.0
@export_range(100.0, 5000.0, 50.0) var joint_breaking_force_n: float = 800.0
@export var dimensions: Vector3 = Vector3(2.0, 0.3, 0.3)
@export var sockets: Array[Vector3] = [
	Vector3(-1.0, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.0),
	Vector3(0.0, 0.0, 0.0),
]
@export var is_hinge: bool = false


func validate() -> Error:
	if part_type_id.strip_edges().is_empty() or display_name.strip_edges().is_empty():
		return ERR_INVALID_DATA
	if not is_finite(mass_kg) or mass_kg <= 0.0:
		return ERR_INVALID_PARAMETER
	if not is_finite(joint_breaking_force_n) or joint_breaking_force_n <= 0.0:
		return ERR_INVALID_PARAMETER
	if sockets.is_empty():
		return ERR_INVALID_DATA
	return OK
