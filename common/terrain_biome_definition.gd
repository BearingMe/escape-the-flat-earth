class_name TerrainBiomeDefinition
extends Resource

enum Id { PLAINS, FOREST, MOUNTAINS, TUNDRA, ICE_WALL }

@export_range(0, 4, 1) var biome_id: int = Id.PLAINS
@export var display_name: String = "Plains"
@export var terrain_color: Color = Color.WHITE
@export_range(-1.0, 1.0, 0.01) var temperature_preference: float = 0.0
@export_range(-1.0, 1.0, 0.01) var moisture_preference: float = 0.0
@export_range(0.0, 1.0, 0.01) var ruggedness_preference: float = 0.0
@export_range(0.0, 1.0, 0.01) var elevation_min_ratio: float = 0.0
@export_range(0.0, 1.0, 0.01) var elevation_max_ratio: float = 1.0
@export_range(0.4, 2.5, 0.01) var elevation_curve: float = 1.0
@export_range(0.0, 1.0, 0.01) var detail_strength: float = 0.1


func validate() -> Error:
	if (
		biome_id < Id.PLAINS
		or biome_id > Id.ICE_WALL
		or display_name.strip_edges().is_empty()
		or not is_finite(temperature_preference)
		or temperature_preference < -1.0
		or temperature_preference > 1.0
		or not is_finite(moisture_preference)
		or moisture_preference < -1.0
		or moisture_preference > 1.0
		or not is_finite(ruggedness_preference)
		or ruggedness_preference < 0.0
		or ruggedness_preference > 1.0
		or not is_finite(elevation_min_ratio)
		or not is_finite(elevation_max_ratio)
		or elevation_min_ratio < 0.0
		or elevation_min_ratio > 1.0
		or elevation_max_ratio < 0.0
		or elevation_max_ratio > 1.0
		or elevation_max_ratio <= elevation_min_ratio
		or not is_finite(elevation_curve)
		or elevation_curve < 0.4
		or elevation_curve > 2.5
		or not is_finite(detail_strength)
		or detail_strength < 0.0
		or detail_strength > 1.0
		or not is_finite(terrain_color.r)
		or terrain_color.r < 0.0
		or terrain_color.r > 1.0
		or not is_finite(terrain_color.g)
		or terrain_color.g < 0.0
		or terrain_color.g > 1.0
		or not is_finite(terrain_color.b)
		or terrain_color.b < 0.0
		or terrain_color.b > 1.0
		or not is_finite(terrain_color.a)
		or terrain_color.a < 0.0
		or terrain_color.a > 1.0
	):
		return ERR_INVALID_DATA
	return OK
