class_name EnemyArchetypeDefinition
extends Resource

enum ArchetypeId {
	GEODETIC_DRONE,
	ICE_SENTINEL,
	VOID_SWARMER,
	PATROL_ROVER,
	MAGNETIC_ANOMALY,
}

@export_range(0, 4, 1) var archetype_id: int = ArchetypeId.GEODETIC_DRONE
@export var display_name: String = "Geodetic Drone"
@export_range(10.0, 1000.0, 5.0) var max_health: float = 80.0
@export_range(1.0, 25.0, 0.5) var movement_speed_m_s: float = 8.0
@export_range(5.0, 60.0, 1.0) var perception_radius_m: float = 24.0
@export_range(0.5, 30.0, 0.5) var attack_range_m: float = 3.0
@export_range(0.2, 10.0, 0.1) var attack_cooldown_sec: float = 1.5
@export_range(0.0, 100.0, 1.0) var damage: float = 15.0
@export var drop_item_id: String = "tech_components"
@export var drop_count: int = 2


func validate() -> Error:
	if display_name.strip_edges().is_empty() or drop_item_id.strip_edges().is_empty():
		return ERR_INVALID_DATA
	if max_health <= 0.0 or movement_speed_m_s <= 0.0 or perception_radius_m <= 0.0:
		return ERR_INVALID_PARAMETER
	if attack_range_m <= 0.0 or attack_cooldown_sec <= 0.0 or drop_count <= 0:
		return ERR_INVALID_PARAMETER
	return OK
