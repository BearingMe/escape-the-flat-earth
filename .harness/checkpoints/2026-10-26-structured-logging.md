# Structured Logging Baseline

**Date:** 2026-10-26 · **Milestone:** M1–M21 foundation

## Progress

- Added `Log` as a project autoload with structured JSON records, severity filtering, UTC and monotonic timestamps, a bounded 512-record history, deep-copy queries, and a `record_logged` signal.
- Added context normalization for JSON, built-in and packed arrays, objects, non-finite floats, total/depth/item/string limits, and common secret-key redaction.
- Routed `Log.error()` through Godot `push_error()` so unexpected application errors appear in engine/headless logs and fail GUT unless explicitly asserted. Invalid log requests return typed errors without emitting engine errors.
- Added `LogTestHarness` and extensive GUT coverage for record fields, levels/filtering, bounded/redacted contexts, history behavior, isolation, invalid input, worker-thread rejection, and capture-helper lifecycle.
- Enabled stdout flushing for headless/server collection and documented use, privacy, error semantics, and the built-in rotating Godot log file.

## Verification

- Godot 4.7.2 `--headless --import`: passed.
- Headless boot-smoke scene: passed.
- GUT suite: 19 tests / 130 assertions passed.
- A temporary negative probe confirmed that an unasserted `Log.error()` fails GUT with exit code 1; the probe was removed.
- `gdformat --check .`, `gdlint .`, and `git diff --check`: passed.

## Limitations

This is a main-thread application logger, not an engine-wide custom `Logger` interceptor. Worker-thread calls to `write_log()` return `ERR_UNAVAILABLE`; worker jobs should marshal safe diagnostic data to the main thread. There are still no gameplay or multiplayer flows to instrument.
