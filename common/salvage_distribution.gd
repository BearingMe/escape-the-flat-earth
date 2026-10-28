class_name SalvageDistribution
extends RefCounted

const ITEM_WOOD: String = "wood_lumber"
const ITEM_SCRAP: String = "scrap_metal"
const ITEM_TECH: String = "tech_components"
const ITEM_ICE_CRYSTAL: String = "ice_crystal"
const ITEM_VOID_OBSIDIAN: String = "void_obsidian"


static func get_zone_loot_table(radial_ratio: float, is_underside: bool) -> Array[Dictionary]:
	if is_underside:
		return [
			{"item_id": ITEM_VOID_OBSIDIAN, "weight": 0.45, "min": 1, "max": 3},
			{"item_id": ITEM_TECH, "weight": 0.35, "min": 2, "max": 5},
			{"item_id": ITEM_SCRAP, "weight": 0.20, "min": 3, "max": 8},
		]
	if radial_ratio >= 0.90:
		return [
			{"item_id": ITEM_ICE_CRYSTAL, "weight": 0.45, "min": 2, "max": 4},
			{"item_id": ITEM_TECH, "weight": 0.30, "min": 2, "max": 4},
			{"item_id": ITEM_SCRAP, "weight": 0.25, "min": 3, "max": 6},
		]
	if radial_ratio >= 0.66:
		return [
			{"item_id": ITEM_TECH, "weight": 0.30, "min": 1, "max": 3},
			{"item_id": ITEM_WOOD, "weight": 0.35, "min": 2, "max": 5},
			{"item_id": ITEM_SCRAP, "weight": 0.35, "min": 2, "max": 6},
		]
	return [
		{"item_id": ITEM_SCRAP, "weight": 0.50, "min": 1, "max": 4},
		{"item_id": ITEM_WOOD, "weight": 0.45, "min": 2, "max": 6},
		{"item_id": ITEM_TECH, "weight": 0.05, "min": 1, "max": 2},
	]


static func sample_loot_at(world_pos: Vector3, disk_radius_m: float, roll: float) -> Dictionary:
	var r_ratio: float = Vector2(world_pos.x, world_pos.z).length() / maxf(disk_radius_m, 1.0)
	var is_underside: bool = world_pos.y < -250.0
	var table: Array[Dictionary] = get_zone_loot_table(r_ratio, is_underside)

	var clamped_roll: float = clampf(roll, 0.0, 0.9999)
	var accum: float = 0.0
	for entry: Dictionary in table:
		accum += float(entry["weight"])
		if clamped_roll < accum:
			var min_count: int = int(entry["min"])
			var max_count: int = int(entry["max"])
			return {
				"item_id": entry["item_id"],
				"count": min_count if min_count == max_count else randi_range(min_count, max_count),
			}

	return {
		"item_id": ITEM_SCRAP,
		"count": 1,
	}
