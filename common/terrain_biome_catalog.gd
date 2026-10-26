class_name TerrainBiomeCatalog
extends RefCounted

const PLAINS: TerrainBiomeDefinition = preload("res://common/data/biomes/plains.tres")
const FOREST: TerrainBiomeDefinition = preload("res://common/data/biomes/forest.tres")
const MOUNTAINS: TerrainBiomeDefinition = preload("res://common/data/biomes/mountains.tres")
const TUNDRA: TerrainBiomeDefinition = preload("res://common/data/biomes/tundra.tres")
const ICE_WALL: TerrainBiomeDefinition = preload("res://common/data/biomes/ice_wall.tres")


static func all_biomes() -> Array[TerrainBiomeDefinition]:
	return [PLAINS, FOREST, MOUNTAINS, TUNDRA, ICE_WALL]


static func core_biomes() -> Array[TerrainBiomeDefinition]:
	return [PLAINS, FOREST, MOUNTAINS]


static func get_biome(biome_id: int) -> TerrainBiomeDefinition:
	match biome_id:
		TerrainBiomeDefinition.Id.PLAINS:
			return PLAINS
		TerrainBiomeDefinition.Id.FOREST:
			return FOREST
		TerrainBiomeDefinition.Id.MOUNTAINS:
			return MOUNTAINS
		TerrainBiomeDefinition.Id.TUNDRA:
			return TUNDRA
		TerrainBiomeDefinition.Id.ICE_WALL:
			return ICE_WALL
	return null


static func validate() -> Error:
	var definitions: Array[TerrainBiomeDefinition] = all_biomes()
	if definitions.size() != TerrainBiomeDefinition.Id.size():
		return ERR_INVALID_DATA
	var seen_ids: Dictionary = {}
	for definition: TerrainBiomeDefinition in definitions:
		if definition == null or definition.validate() != OK or seen_ids.has(definition.biome_id):
			return ERR_INVALID_DATA
		seen_ids[definition.biome_id] = true
	return OK
