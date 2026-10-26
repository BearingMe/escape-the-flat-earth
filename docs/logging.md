# Logging

Use the `Log` autoload for application diagnostics. It produces one structured JSON record per event, keeps a bounded in-memory history, and emits a `record_logged` signal for diagnostics and tests.

```gdscript
Log.debug("physics.contact", {"body": body.name, "speed": impact_speed})
Log.info("match.started", {"match_id": match_id, "seed": seed})
Log.warning("loot.table_fallback", {"table": table_path})
Log.error("save.write_failed", {"path": save_path, "error": error_code})
```

## Contract

- Events are stable, non-empty identifiers in `feature.action` form. Put changing details in the context dictionary.
- Levels are `Log.Level.DEBUG`, `INFO`, `WARNING`, and `ERROR`. `Log.set_minimum_level(level)` filters lower-level entries; filtered calls return `OK` but do not create, buffer, print, or emit a record.
- Every record contains `sequence`, UTC `timestamp_utc`, process-relative `elapsed_usec`, `level`, `event`, and normalized `context` fields.
- Logging methods return `OK` when the logger accepted the record, or a typed `Error` when the logging request itself was invalid. This return value is not the result of the game operation being logged.
- The in-memory history is a 512-record ring buffer by default. `Log.get_records(minimum_level, event)` returns deep copies; `Log.clear_history()` clears the buffer. `Log.set_history_capacity(0)` disables retention but still emits and reports records.
- Invalid levels, blank event names, and negative capacities return `ERR_INVALID_PARAMETER`; they do not call `push_error()`.
- `Log.error()` is reserved for unexpected failures that need debugger/headless visibility. It emits the structured record to Godot through `push_error()`, so unexpected error-level logs fail GUT by default. Tests for intentional errors must call the operation and then consume the expected error with `assert_push_error()`; they must also assert the failure/recovery behavior. Do not use `Log.error()` for expected validation failures or routine disconnects.
- `Log.warning()` is a diagnostic record, not an engine warning. It does not trigger GUT error tracking. Use it sparingly for recoverable fallbacks.
- `console_output_enabled` controls JSON stdout output for debug/info/warning records. Error records are always sent through Godot's error stream.
- Godot writes its normal logs to rotating `user://logs/godot.log` files on desktop. This project enables stdout flushing on each print so headless/server log collectors receive records promptly.

See the [Godot logging guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/logging.html) for the engine's file-rotation and output settings.

## Context safety

Contexts are recursively normalized for JSON and bounded (8 levels, 64 entries/items per container, 256 total values, 2,048 characters per text value). This includes Godot packed arrays. Godot-specific values are represented as strings; objects are represented by class name, not serialized internals. Non-finite floats are converted to strings. Common secret-bearing keys (`password`, `secret`, `token`, `authorization`, `credential`, and key variants) are replaced with `[REDACTED]`, including nested dictionaries.

This is defense in depth, not permission to log private data. Never put credentials, personal data, or an entire untrusted payload in an event or context. Log safe identifiers, validation outcomes, and bounded summaries instead.

The logger is main-thread-only because it emits a Node signal and calls Godot's logging API. `write_log()` rejects worker-thread calls with `ERR_UNAVAILABLE`. Worker-thread tasks should return or queue diagnostic data and log it from the main thread; do not call `Log` from a worker thread.

## Test harness

`tests/support/log_test_harness.gd` (`LogTestHarness`) attaches to `record_logged` and provides capture, count, find, and last-record helpers. Each test must detach it in teardown and restore global logger settings. The logger unit suite covers every severity, record schema, JSON-safe normalization, secret redaction, level filtering, ring-buffer behavior, copy isolation, invalid inputs, and harness lifecycle.

Expected `Log.error()` entries must be asserted using GUT's `assert_push_error()` after the log call; the logger's error message includes the structured event identifier. A test that forgets to assert an error-level log fails rather than quietly passing.
