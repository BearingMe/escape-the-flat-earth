extends GutTest

var _harness: LogTestHarness
var _previous_minimum_level: int
var _previous_history_capacity: int
var _previous_console_output_enabled: bool


func before_each() -> void:
	_previous_minimum_level = Log.minimum_level
	_previous_history_capacity = Log.history_capacity
	_previous_console_output_enabled = Log.console_output_enabled
	Log.console_output_enabled = false
	Log.set_minimum_level(Log.Level.DEBUG)
	Log.set_history_capacity(512)
	Log.clear_history()
	_harness = LogTestHarness.new()
	assert_eq(_harness.attach(Log), OK)


func after_each() -> void:
	_harness.detach()
	Log.clear_history()
	Log.set_minimum_level(_previous_minimum_level)
	Log.set_history_capacity(_previous_history_capacity)
	Log.console_output_enabled = _previous_console_output_enabled


func test_each_severity_emits_a_structured_record() -> void:
	assert_eq(Log.debug("physics.step", {"tick": 1}), OK)
	assert_eq(Log.info("match.started"), OK)
	assert_eq(Log.warning("peer.slow"), OK)
	assert_eq(
		Log.error("save.failed", {"path": "user://save.json", "access_token": "do-not-log"}), OK
	)
	assert_push_error("save.failed")

	assert_eq(_harness.records.size(), 4)
	assert_eq(_harness.count("DEBUG"), 1)
	assert_eq(_harness.count("INFO"), 1)
	assert_eq(_harness.count("WARNING"), 1)
	assert_eq(_harness.count("ERROR"), 1)
	var record: Dictionary = _harness.find("save.failed", "ERROR")[0]
	assert_true(record.has("sequence"))
	assert_true(record.has("timestamp_utc"))
	assert_true(record.has("elapsed_usec"))
	assert_eq(record["context"]["path"], "user://save.json")
	assert_eq(record["context"]["access_token"], "[REDACTED]")
	assert_false(JSON.stringify(record).contains("do-not-log"))


func test_records_are_json_safe_and_sensitive_context_is_redacted() -> void:
	var context: Dictionary = {
		"password": "do-not-log",
		"nested": {"access_token": "also-do-not-log", "count": 3},
		"position": Vector3(1.0, 2.0, 3.0),
		"identifier": &"player",
		"node_path": NodePath("World/Player"),
		"apiKey": "also-do-not-log",
		"not_finite": INF,
		"large_array": range(70),
		"packed_array": PackedByteArray(range(70))
	}
	assert_eq(Log.info("player.connected", context), OK)

	var record: Dictionary = _harness.last_record()
	var sanitized: Dictionary = record["context"]
	assert_eq(sanitized["password"], "[REDACTED]")
	assert_eq(sanitized["nested"]["access_token"], "[REDACTED]")
	assert_eq(sanitized["nested"]["count"], 3)
	assert_true(sanitized["position"] is String)
	assert_eq(sanitized["identifier"], "player")
	assert_eq(sanitized["node_path"], "World/Player")
	assert_eq(sanitized["apiKey"], "[REDACTED]")
	assert_eq(sanitized["not_finite"], "inf")
	assert_eq(sanitized["large_array"].size(), 65)
	assert_true(str(sanitized["large_array"].back()).begins_with("[TRUNCATED:"))
	assert_eq(sanitized["packed_array"].size(), 65)
	assert_true(str(sanitized["packed_array"].back()).begins_with("[TRUNCATED:"))
	assert_true(JSON.parse_string(JSON.stringify(record)) is Dictionary)


func test_dictionary_depth_item_and_text_limits_are_bounded() -> void:
	var large_dictionary: Dictionary = {}
	for index: int in range(70):
		large_dictionary["key_%d" % index] = index

	var deeply_nested: Dictionary = {"depth": 0}
	var cursor: Dictionary = deeply_nested
	for depth: int in range(12):
		var child: Dictionary = {"depth": depth + 1}
		cursor["child"] = child
		cursor = child
	var long_text: String = "x".repeat(2100)
	assert_eq(
		Log.info(
			"context.bounds", {"large": large_dictionary, "deep": deeply_nested, "long": long_text}
		),
		OK
	)

	var context: Dictionary = _harness.last_record()["context"]
	assert_eq(context["large"].size(), 65)
	assert_eq(context["large"]["_truncated"], "max_items")
	assert_true(context["long"].ends_with("…[TRUNCATED]"))
	assert_true(context["long"].length() < long_text.length())
	var deepest: Variant = context["deep"]
	while deepest is Dictionary and deepest.has("child"):
		deepest = deepest["child"]
	assert_true(deepest is Dictionary)
	assert_eq(deepest.get("_truncated"), "max_depth")


func test_total_context_budget_bounds_wide_nested_values() -> void:
	var wide_context: Array = []
	for outer_index: int in range(64):
		wide_context.append(range(64))
	assert_eq(Log.info("context.total_budget", {"wide": wide_context}), OK)

	var record: Dictionary = _harness.last_record()
	assert_true(JSON.stringify(record).length() < 10000)
	assert_true(str(JSON.stringify(record)).contains("MAX_TOTAL_ITEMS"))


func test_recursive_context_is_truncated_without_recursing_forever() -> void:
	var recursive_context: Dictionary = {}
	recursive_context["self"] = recursive_context
	assert_eq(Log.info("context.recursive", {"cycle": recursive_context}), OK)
	var record: Dictionary = _harness.last_record()
	assert_true(JSON.parse_string(JSON.stringify(record)) is Dictionary)
	var current: Variant = record["context"]["cycle"]
	while current is Dictionary and current.has("self"):
		current = current["self"]
	assert_eq(current.get("_truncated"), "max_depth")


func test_object_context_is_summarized_without_serializing_object_state() -> void:
	var node: Node = Node.new()
	assert_eq(Log.info("context.object", {"node": node}), OK)
	node.free()
	assert_eq(_harness.last_record()["context"]["node"], "[Object:Node]")
	assert_eq(Log.info("context.freed_object", {"node": node}), OK)
	assert_eq(_harness.last_record()["context"]["node"], null)


func test_level_threshold_filters_emission_and_record_queries() -> void:
	assert_eq(Log.set_minimum_level(Log.Level.WARNING), OK)
	assert_eq(Log.debug("filtered.debug"), OK)
	assert_eq(Log.info("filtered.info"), OK)
	assert_eq(Log.warning("visible.warning"), OK)
	assert_eq(Log.error("visible.error"), OK)
	assert_push_error("visible.error")

	assert_eq(_harness.records.size(), 2)
	assert_eq(Log.get_records().size(), 2)
	assert_eq(Log.get_records(Log.Level.ERROR).size(), 1)
	assert_eq(Log.get_records(Log.Level.WARNING, "visible.warning").size(), 1)


func test_history_capacity_keeps_newest_records_without_losing_signal_capture() -> void:
	assert_eq(Log.set_history_capacity(2), OK)
	Log.info("first")
	Log.info("second")
	Log.info("third")

	var history: Array[Dictionary] = Log.get_records()
	assert_eq(history.size(), 2)
	assert_eq(history[0]["event"], "second")
	assert_eq(history[1]["event"], "third")
	assert_eq(_harness.records.size(), 3)
	assert_eq(Log.set_history_capacity(1), OK)
	assert_eq(Log.get_records().size(), 1)
	assert_eq(Log.get_records()[0]["event"], "third")


func test_zero_capacity_disables_history_but_still_emits_records() -> void:
	assert_eq(Log.set_history_capacity(0), OK)
	assert_eq(Log.info("not.retained"), OK)
	assert_true(Log.get_records().is_empty())
	assert_eq(_harness.count("INFO", "not.retained"), 1)


func test_invalid_levels_and_empty_events_are_rejected_without_emission() -> void:
	assert_eq(Log.write_log(-1, "invalid.level"), ERR_INVALID_PARAMETER)
	assert_eq(Log.write_log(Log.Level.ERROR + 1, "invalid.level"), ERR_INVALID_PARAMETER)
	assert_eq(Log.info("   "), ERR_INVALID_PARAMETER)
	assert_eq(Log.set_minimum_level(-1), ERR_INVALID_PARAMETER)
	assert_eq(Log.set_minimum_level(Log.Level.ERROR + 1), ERR_INVALID_PARAMETER)
	assert_eq(Log.set_history_capacity(-1), ERR_INVALID_PARAMETER)
	assert_true(Log.get_records(Log.Level.ERROR + 1).is_empty())
	assert_true(_harness.records.is_empty())
	assert_true(Log.minimum_level == Log.Level.DEBUG)
	assert_eq(Log.history_capacity, 512)


func test_sequences_increase_monotonically_and_events_are_bounded() -> void:
	Log.info("sequence.one")
	Log.info("sequence.two")
	var first: Dictionary = _harness.records[0]
	var second: Dictionary = _harness.records[1]
	assert_eq(second["sequence"], first["sequence"] + 1)
	assert_true(first["elapsed_usec"] >= 0)

	var long_event: String = "e".repeat(2100)
	Log.info(long_event)
	var bounded_event: String = str(_harness.last_record()["event"])
	assert_true(bounded_event.ends_with("…[TRUNCATED]"))
	assert_true(bounded_event.length() < long_event.length())


func test_returned_records_cannot_mutate_logger_history() -> void:
	Log.info("snapshot.test", {"nested": {"value": "original"}})
	var returned_records: Array[Dictionary] = Log.get_records()
	returned_records[0]["context"]["nested"]["value"] = "mutated"
	var emitted_record: Dictionary = _harness.last_record()
	emitted_record["context"]["nested"]["value"] = "also_mutated"

	assert_eq(Log.get_records()[0]["context"]["nested"]["value"], "original")


func test_harness_queries_and_clear_are_independent_of_logger_history() -> void:
	Log.info("query.one")
	Log.warning("query.two")
	assert_eq(_harness.count("INFO", "query.one"), 1)
	assert_eq(_harness.find("missing").size(), 0)
	assert_eq(_harness.last_record()["event"], "query.two")
	var found_records: Array[Dictionary] = _harness.find("query.one")
	found_records[0]["event"] = "mutated.copy"
	assert_eq(_harness.find("query.one").size(), 1)
	_harness.clear()
	assert_true(_harness.records.is_empty())
	assert_true(_harness.last_record().is_empty())
	assert_eq(Log.get_records().size(), 2)


func test_harness_detach_stops_capture_and_attach_validates_signal_contract() -> void:
	var invalid_source: Node = Node.new()
	var second_harness: LogTestHarness = LogTestHarness.new()
	assert_eq(second_harness.attach(null), ERR_INVALID_PARAMETER)
	assert_eq(second_harness.attach(invalid_source), ERR_UNAVAILABLE)
	second_harness.detach()
	assert_eq(_harness.attach(Log), ERR_ALREADY_IN_USE)
	invalid_source.free()

	_harness.detach()
	Log.info("after.detach")
	assert_true(_harness.records.is_empty())


func test_worker_thread_calls_are_rejected_without_emitting() -> void:
	var worker: Thread = Thread.new()
	assert_eq(worker.start(Callable(self, "_write_log_from_worker")), OK)
	var result: int = worker.wait_to_finish()
	assert_eq(result, ERR_UNAVAILABLE)
	assert_true(_harness.records.is_empty())


func _write_log_from_worker() -> int:
	return Log.info("thread.not_supported")
