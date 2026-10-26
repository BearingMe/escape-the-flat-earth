# M2 — Camera System

**Date:** 2026-10-26 · **Milestone:** M2 · **Status:** implementing / gravity-dependent acceptance pending

## Progress

- Confirmed M1 gravity reconciliation is committed: no gravity autoload or finite-disk field remains, and Godot project-wide 3D default gravity is `0.0`.
- Kept M2's gravity-relative orientation, rim/underside transition, and no-flip acceptance pending; do not infer or restore a gravity source in the camera.
- Added configurable mouse and controller look sensitivity, screen-relative mouse input, a remapped controller deadzone, and local-only controller polling.
- Hid the local observer mesh/name label from its own first-person view; remote observers retain their presentation, and only the local observer activates its camera.
- Added unit coverage for controller look shaping, yaw wrapping/pitch clamping, and configurable sensitivity.
- Extended the separate-process multiplayer E2E to verify each host/client process has exactly one active camera and that it belongs to that process's local peer; all six peers passed and teardown logs were clean.

## Verification

- `gdformat .` and `gdlint .`: passed.
- `Godot Console.exe --headless --path . --import`: passed.
- `Godot Console.exe --headless --path . --script res://tests/run_gut.gd`: 25 tests, 154 assertions, 0 failures. Logger `push_error` entries are expected and asserted by GUT.
- Boot smoke and default world scene: passed.
- Multiplayer E2E: passed with host + 5 clients, exclusive local camera ownership on each process, movement replication, disconnect cleanup, and clean teardown logs.
- Gravity-dependent camera acceptance is intentionally not part of this checkpoint's pass criteria.

## Handoff

Continue M2 camera work that does not require a gravity subsystem. Do not mark M2 complete until gravity scope is reopened and pending orientation/collision/multiplayer acceptance is resolved.
