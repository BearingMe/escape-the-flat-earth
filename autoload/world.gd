extends Node

const DEFAULT_CONFIG: WorldConfig = preload("res://common/data/world_default.tres")

var config: WorldConfig = DEFAULT_CONFIG.duplicate(true)
var _entity_sequence: int = 1


func _ready() -> void:
	var validation: Error = config.validate()
	if validation != OK:
		Log.error("world.config_invalid", {"error": validation})


func set_seed(seed_value: int) -> void:
	config.world_seed = seed_value
	_entity_sequence = 1
	if is_instance_valid(Gravity):
		Gravity.configure(config)


func allocate_stable_id(kind: String) -> String:
	var normalized_kind: String = kind.strip_edges().to_lower().replace(" ", "_")
	if normalized_kind.is_empty() or not multiplayer.is_server():
		return ""
	var stable_id: String = "%s_%d_%d" % [normalized_kind, config.world_seed, _entity_sequence]
	_entity_sequence += 1
	return stable_id
