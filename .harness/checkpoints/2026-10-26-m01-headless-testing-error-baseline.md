# Headless Testing and Error-Handling Baseline

**Date:** 2026-10-26 · **Milestone:** M1–M21 foundation

## Progress

- Pinned GUT 9.7.1, the release matched to Godot 4.7, under `addons/gut/` and enabled its editor plugin.
- Added `.gutconfig.json` for headless unit/integration discovery and `tests/run_gut.gd`, which fails if GUT discovers no tests (GUT's empty run otherwise exits successfully).
- Added GUT contract tests for configured discovery paths, error tracking, and the pinned/enabled GUT version. These validate the harness, not gameplay.
- Added a minimal runtime boot-smoke scene and a test layout for unit, integration, E2E, fixtures, and shared support.
- Added testing and error-handling guidance. E2E scenarios are specified as separate headless host/client processes, but the runner is deferred until game/network lifecycle code exists.
- Added gdformat/gdlint configuration to exclude vendored addons and generated/local reference directories.

## Verification

- Godot 4.7.2 `--headless --import`: passed.
- Headless boot-smoke scene: passed.
- GUT 9.7.1 harness contract suite: 3 tests / 14 assertions passed headlessly.
- Error tracking was also validated with temporary tests: an explicitly asserted `push_error` passed, while an unexpected `push_error` failed the suite. Temporary tests were removed.
- Empty GUT suite: wrapper correctly exits nonzero instead of reporting a false green.
- `gdformat --check .` and `gdlint .`: passed.

## Limitations

There are no gameplay scripts or network scenarios yet, so this establishes the test/error-handling harness rather than gameplay coverage. The first feature milestone must add meaningful unit/integration tests; headless multiplayer E2E starts when host/client lifecycle behavior exists.
