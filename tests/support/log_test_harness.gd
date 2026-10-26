class_name LogTestHarness
extends RefCounted

const LOG_SIGNAL: StringName = &"record_logged"

var records: Array[Dictionary] = []
var _logger: Node


func attach(logger: Node) -> Error:
	if logger == null or not is_instance_valid(logger):
		return ERR_INVALID_PARAMETER
	if _logger != null:
		return ERR_ALREADY_IN_USE
	if not logger.has_signal(LOG_SIGNAL):
		return ERR_UNAVAILABLE
	var connect_error: Error = logger.connect(LOG_SIGNAL, Callable(self, "_on_record_logged"))
	if connect_error != OK:
		return connect_error
	_logger = logger
	return OK


func detach() -> void:
	if _logger != null and is_instance_valid(_logger):
		if _logger.is_connected(LOG_SIGNAL, Callable(self, "_on_record_logged")):
			_logger.disconnect(LOG_SIGNAL, Callable(self, "_on_record_logged"))
	_logger = null


func clear() -> void:
	records.clear()


func count(level: String = "", event: String = "") -> int:
	var matches: int = 0
	for record: Dictionary in records:
		if not level.is_empty() and record.get("level", "") != level:
			continue
		if not event.is_empty() and record.get("event", "") != event:
			continue
		matches += 1
	return matches


func find(event: String, level: String = "") -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in records:
		if record.get("event", "") != event:
			continue
		if not level.is_empty() and record.get("level", "") != level:
			continue
		matches.append(record.duplicate(true))
	return matches


func last_record() -> Dictionary:
	if records.is_empty():
		return {}
	return records.back().duplicate(true)


func _on_record_logged(record: Dictionary) -> void:
	records.append(record.duplicate(true))
