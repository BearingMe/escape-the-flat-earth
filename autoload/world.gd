extends Node

const DEFAULT_CONFIG: WorldConfig = preload("res://common/data/world_default.tres")

var config: WorldConfig = DEFAULT_CONFIG.duplicate(true)
var _entity_sequence: int = 1
var _static_prop_ids_by_chunk: Dictionary = {}
var _active_static_props: Dictionary = {}


func _ready() -> void:
	var validation: Error = config.validate()
	if validation != OK:
		Log.error("world.config_invalid", {"error": validation})


func set_seed(seed_value: int) -> void:
	config.world_seed = seed_value
	_entity_sequence = 1
	_static_prop_ids_by_chunk.clear()
	_active_static_props.clear()


func has_host_authority() -> bool:
	return Net.session_role == "host"


func register_static_prop_chunk(
	chunk_coordinate: Vector2i, population: TerrainChunkPopulation
) -> Error:
	if not has_host_authority():
		return ERR_UNAUTHORIZED
	if (
		population == null
		or population.stable_ids.size() != population.size()
		or population.positions.size() != population.size()
		or population.surface_normals.size() != population.size()
		or population.biome_ids.size() != population.size()
		or population.scales.size() != population.size()
		or population.yaws.size() != population.size()
	):
		return ERR_INVALID_PARAMETER
	if _static_prop_ids_by_chunk.has(chunk_coordinate):
		return ERR_ALREADY_EXISTS
	var seen_ids: Dictionary = {}
	for prop_index: int in range(population.size()):
		var stable_id: String = population.stable_ids[prop_index]
		if stable_id.is_empty() or seen_ids.has(stable_id) or _active_static_props.has(stable_id):
			return ERR_INVALID_DATA
		seen_ids[stable_id] = true
	var chunk_prop_ids: Array[String] = population.stable_ids.duplicate()
	_static_prop_ids_by_chunk[chunk_coordinate] = chunk_prop_ids
	for prop_index: int in range(population.size()):
		var stable_id: String = population.stable_ids[prop_index]
		_active_static_props[stable_id] = {
			"chunk": chunk_coordinate,
			"kind": population.prop_kinds[prop_index],
			"biome_id": population.biome_ids[prop_index],
			"position": population.positions[prop_index],
			"surface_normal": population.surface_normals[prop_index],
			"scale": population.scales[prop_index],
			"yaw": population.yaws[prop_index],
			"state": "static"
		}
	return OK


func unregister_static_prop_chunk(chunk_coordinate: Vector2i) -> Error:
	if not has_host_authority():
		return ERR_UNAUTHORIZED
	if not _static_prop_ids_by_chunk.has(chunk_coordinate):
		return OK
	var chunk_prop_ids: Array = _static_prop_ids_by_chunk[chunk_coordinate]
	for stable_id: String in chunk_prop_ids:
		var prop_record: Dictionary = _active_static_props.get(stable_id, {})
		if prop_record.get("state", "static") == "static":
			_active_static_props.erase(stable_id)
	_static_prop_ids_by_chunk.erase(chunk_coordinate)
	return OK


func get_active_static_prop_count() -> int:
	return _active_static_props.size() if has_host_authority() else 0


func get_active_static_prop_record(stable_id: String) -> Dictionary:
	if not has_host_authority():
		return {}
	var record: Variant = _active_static_props.get(stable_id)
	return record.duplicate(true) if record is Dictionary else {}


func clear_static_prop_registry() -> Error:
	if not has_host_authority():
		return ERR_UNAUTHORIZED
	_static_prop_ids_by_chunk.clear()
	_active_static_props.clear()
	return OK


func allocate_stable_id(kind: String) -> String:
	var normalized_kind: String = kind.strip_edges().to_lower().replace(" ", "_")
	if normalized_kind.is_empty() or not has_host_authority():
		return ""
	var stable_id: String = "%s_%d_%d" % [normalized_kind, config.world_seed, _entity_sequence]
	_entity_sequence += 1
	return stable_id
