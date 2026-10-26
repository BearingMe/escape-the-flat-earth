extends Node

signal record_logged(record: Dictionary)

enum Level { DEBUG, INFO, WARNING, ERROR }

const MAX_CONTEXT_DEPTH: int = 8
const MAX_CONTAINER_ITEMS: int = 64
const MAX_TOTAL_CONTEXT_ITEMS: int = 256
const MAX_TEXT_LENGTH: int = 2048
const SENSITIVE_KEY_PARTS: PackedStringArray = [
	"password",
	"passwd",
	"secret",
	"token",
	"authorization",
	"credential",
	"api_key",
	"private_key",
	"access_key"
]

var console_output_enabled: bool = true

var minimum_level: int:
	get:
		return _minimum_level

var history_capacity: int:
	get:
		return _history_capacity

var _minimum_level: int = Level.DEBUG
var _history_capacity: int = 512
var _next_sequence: int = 1
var _session_started_usec: int = 0
var _records: Array[Dictionary] = []
var _normalization_budget: int = MAX_TOTAL_CONTEXT_ITEMS


func _ready() -> void:
	_session_started_usec = Time.get_ticks_usec()


func set_minimum_level(level: int) -> Error:
	if level < Level.DEBUG or level > Level.ERROR:
		return ERR_INVALID_PARAMETER
	_minimum_level = level
	return OK


func set_history_capacity(capacity: int) -> Error:
	if capacity < 0:
		return ERR_INVALID_PARAMETER
	_history_capacity = capacity
	while _records.size() > _history_capacity:
		_records.pop_front()
	return OK


func debug(event: String, context: Dictionary = {}) -> Error:
	return write_log(Level.DEBUG, event, context)


func info(event: String, context: Dictionary = {}) -> Error:
	return write_log(Level.INFO, event, context)


func warning(event: String, context: Dictionary = {}) -> Error:
	return write_log(Level.WARNING, event, context)


func error(event: String, context: Dictionary = {}) -> Error:
	return write_log(Level.ERROR, event, context)


func write_log(level: int, event: String, context: Dictionary = {}) -> Error:
	if not Thread.is_main_thread():
		return ERR_UNAVAILABLE
	if level < Level.DEBUG or level > Level.ERROR:
		return ERR_INVALID_PARAMETER
	var clean_event: String = event.strip_edges()
	if clean_event.is_empty():
		return ERR_INVALID_PARAMETER
	if level < _minimum_level:
		return OK

	var now_usec: int = Time.get_ticks_usec()
	_normalization_budget = MAX_TOTAL_CONTEXT_ITEMS
	var record: Dictionary = {
		"sequence": _next_sequence,
		"timestamp_utc": Time.get_datetime_string_from_system(true),
		"elapsed_usec": maxi(0, now_usec - _session_started_usec),
		"level": _level_name(level),
		"event": _truncate_text(clean_event),
		"context": _normalize_dictionary(context, 0)
	}
	_next_sequence += 1

	if _history_capacity > 0:
		_records.append(record.duplicate(true))
		while _records.size() > _history_capacity:
			_records.pop_front()

	record_logged.emit(record.duplicate(true))
	if level == Level.ERROR:
		push_error(JSON.stringify(record))
	elif console_output_enabled:
		print(JSON.stringify(record))
	return OK


func get_records(minimum_record_level: int = Level.DEBUG, event: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if minimum_record_level < Level.DEBUG or minimum_record_level > Level.ERROR:
		return result
	for record: Dictionary in _records:
		if _level_value(str(record.get("level", ""))) < minimum_record_level:
			continue
		if not event.is_empty() and record.get("event", "") != event:
			continue
		result.append(record.duplicate(true))
	return result


func clear_history() -> void:
	_records.clear()


func _level_name(level: int) -> String:
	match level:
		Level.DEBUG:
			return "DEBUG"
		Level.INFO:
			return "INFO"
		Level.WARNING:
			return "WARNING"
		Level.ERROR:
			return "ERROR"
	return "UNKNOWN"


func _level_value(level_name: String) -> int:
	match level_name:
		"DEBUG":
			return Level.DEBUG
		"INFO":
			return Level.INFO
		"WARNING":
			return Level.WARNING
		"ERROR":
			return Level.ERROR
	return Level.ERROR


func _normalize_dictionary(values: Dictionary, depth: int) -> Dictionary:
	var normalized: Dictionary = {}
	if _normalization_budget <= 0:
		normalized["_truncated"] = "max_total_items"
		return normalized
	if depth >= MAX_CONTEXT_DEPTH:
		normalized["_truncated"] = "max_depth"
		return normalized

	var item_count: int = 0
	for key: Variant in values:
		if _normalization_budget <= 0:
			normalized["_truncated"] = "max_total_items"
			break
		if item_count >= MAX_CONTAINER_ITEMS:
			normalized["_truncated"] = "max_items"
			break
		var key_text: String = _truncate_text(str(key))
		_normalization_budget -= 1
		if _is_sensitive_key(key_text):
			normalized[key_text] = "[REDACTED]"
		else:
			normalized[key_text] = _normalize_value(values[key], depth + 1)
		item_count += 1
	return normalized


func _normalize_value(value: Variant, depth: int) -> Variant:
	if depth >= MAX_CONTEXT_DEPTH:
		return "[MAX_DEPTH]"
	var normalized: Variant = null
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			normalized = value
		TYPE_FLOAT:
			if not is_finite(value):
				normalized = str(value)
			else:
				normalized = value
		TYPE_STRING:
			normalized = _truncate_text(value)
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			normalized = _truncate_text(str(value))
		TYPE_ARRAY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			normalized = _normalize_array(value, depth + 1)
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			normalized = _normalize_array(value, depth + 1)
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
			normalized = _normalize_array(value, depth + 1)
		TYPE_PACKED_COLOR_ARRAY:
			normalized = _normalize_array(value, depth + 1)
		TYPE_DICTIONARY:
			normalized = _normalize_dictionary(value, depth + 1)
		TYPE_OBJECT:
			if value == null:
				normalized = null
			elif not is_instance_valid(value):
				normalized = "[Object:freed]"
			else:
				normalized = "[Object:%s]" % value.get_class()
		_:
			normalized = _truncate_text(str(value))
	return normalized


func _normalize_array(values: Variant, depth: int) -> Array:
	var normalized: Array = []
	if _normalization_budget <= 0:
		normalized.append("[TRUNCATED:MAX_TOTAL_ITEMS]")
		return normalized
	if depth >= MAX_CONTEXT_DEPTH:
		normalized.append("[MAX_DEPTH]")
		return normalized

	var limit: int = mini(values.size(), MAX_CONTAINER_ITEMS)
	for index: int in range(limit):
		if _normalization_budget <= 0:
			normalized.append("[TRUNCATED:MAX_TOTAL_ITEMS]")
			break
		_normalization_budget -= 1
		normalized.append(_normalize_value(values[index], depth + 1))
	if values.size() > MAX_CONTAINER_ITEMS:
		normalized.append("[TRUNCATED:%d]" % (values.size() - MAX_CONTAINER_ITEMS))
	return normalized


func _is_sensitive_key(key: String) -> bool:
	var normalized_key: String = key.to_lower().replace("-", "_").replace(" ", "_")
	var compact_key: String = normalized_key.replace("_", "")
	for sensitive_part: String in SENSITIVE_KEY_PARTS:
		if (
			normalized_key.contains(sensitive_part)
			or compact_key.contains(sensitive_part.replace("_", ""))
		):
			return true
	return false


func _truncate_text(value: String) -> String:
	if value.length() <= MAX_TEXT_LENGTH:
		return value
	return value.substr(0, MAX_TEXT_LENGTH) + "…[TRUNCATED]"
