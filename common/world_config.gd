class_name WorldConfig
extends Resource

@export_range(1.0, 100000.0, 1.0, "or_greater") var disk_radius_m: float = 5000.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var disk_thickness_m: float = 500.0
@export var world_seed: int = 17320508
@export_range(2, 6, 1) var max_players: int = 6
@export_range(32.0, 512.0, 1.0) var terrain_chunk_size_m: float = 128.0
@export_range(2, 128, 1) var terrain_cells_per_chunk: int = 16
@export_range(0.0, 500.0, 1.0) var terrain_height_min_m: float = 0.0
@export_range(0.1, 500.0, 1.0) var terrain_height_max_m: float = 65.0
@export_range(0.00001, 0.1, 0.00001) var terrain_noise_frequency: float = 0.0015
@export_range(0, 4, 1) var terrain_view_radius_chunks: int = 1
@export_range(1.0, 2000.0, 1.0) var terrain_edge_falloff_m: float = 256.0


func validate() -> Error:
	if (
		not is_finite(disk_radius_m)
		or disk_radius_m <= 0.0
		or not is_finite(disk_thickness_m)
		or disk_thickness_m <= 0.0
		or not is_finite(terrain_chunk_size_m)
		or terrain_chunk_size_m < 32.0
		or terrain_chunk_size_m > 512.0
		or terrain_cells_per_chunk < 2
		or terrain_cells_per_chunk > 128
		or not is_finite(terrain_height_min_m)
		or terrain_height_min_m < 0.0
		or not is_finite(terrain_height_max_m)
		or terrain_height_max_m <= terrain_height_min_m
		or not is_finite(terrain_noise_frequency)
		or terrain_noise_frequency <= 0.0
		or terrain_view_radius_chunks < 0
		or terrain_view_radius_chunks > 4
		or not is_finite(terrain_edge_falloff_m)
		or terrain_edge_falloff_m <= 0.0
		or max_players < 2
		or max_players > 6
	):
		return ERR_INVALID_PARAMETER
	return OK


func to_dictionary() -> Dictionary:
	return {
		"disk_radius_m": disk_radius_m,
		"disk_thickness_m": disk_thickness_m,
		"world_seed": world_seed,
		"max_players": max_players,
		"terrain_chunk_size_m": terrain_chunk_size_m,
		"terrain_cells_per_chunk": terrain_cells_per_chunk,
		"terrain_height_min_m": terrain_height_min_m,
		"terrain_height_max_m": terrain_height_max_m,
		"terrain_noise_frequency": terrain_noise_frequency,
		"terrain_view_radius_chunks": terrain_view_radius_chunks,
		"terrain_edge_falloff_m": terrain_edge_falloff_m
	}


static func from_dictionary(values: Dictionary) -> WorldConfig:
	var integer_keys: PackedStringArray = PackedStringArray(
		["world_seed", "max_players", "terrain_cells_per_chunk", "terrain_view_radius_chunks"]
	)
	var float_keys: PackedStringArray = PackedStringArray(
		[
			"disk_radius_m",
			"disk_thickness_m",
			"terrain_chunk_size_m",
			"terrain_height_min_m",
			"terrain_height_max_m",
			"terrain_noise_frequency",
			"terrain_edge_falloff_m"
		]
	)
	for key: String in integer_keys:
		if not values.has(key) or typeof(values[key]) != TYPE_INT:
			return null
	for key: String in float_keys:
		var value_type: int = typeof(values.get(key))
		if not values.has(key) or (value_type != TYPE_INT and value_type != TYPE_FLOAT):
			return null
	var config: WorldConfig = WorldConfig.new()
	config.disk_radius_m = float(values["disk_radius_m"])
	config.disk_thickness_m = float(values["disk_thickness_m"])
	config.world_seed = int(values["world_seed"])
	config.max_players = int(values["max_players"])
	config.terrain_chunk_size_m = float(values["terrain_chunk_size_m"])
	config.terrain_cells_per_chunk = int(values["terrain_cells_per_chunk"])
	config.terrain_height_min_m = float(values["terrain_height_min_m"])
	config.terrain_height_max_m = float(values["terrain_height_max_m"])
	config.terrain_noise_frequency = float(values["terrain_noise_frequency"])
	config.terrain_view_radius_chunks = int(values["terrain_view_radius_chunks"])
	config.terrain_edge_falloff_m = float(values["terrain_edge_falloff_m"])
	if config.validate() != OK:
		return null
	return config
