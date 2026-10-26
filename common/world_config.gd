class_name WorldConfig
extends Resource

@export_range(1.0, 100000.0, 1.0, "or_greater") var disk_radius_m: float = 5000.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var disk_thickness_m: float = 500.0
@export_range(0.01, 100.0, 0.01, "or_greater") var central_surface_gravity_m_s2: float = 9.81
@export var world_seed: int = 17320508
@export_range(2, 6, 1) var max_players: int = 6


func validate() -> Error:
	if (
		not is_finite(disk_radius_m)
		or disk_radius_m <= 0.0
		or not is_finite(disk_thickness_m)
		or disk_thickness_m <= 0.0
		or not is_finite(central_surface_gravity_m_s2)
		or central_surface_gravity_m_s2 <= 0.0
		or max_players < 2
		or max_players > 6
	):
		return ERR_INVALID_PARAMETER
	return OK
