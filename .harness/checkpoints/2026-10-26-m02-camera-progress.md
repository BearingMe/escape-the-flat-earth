# M2 — Camera System

**Date:** 2026-10-26 · **Milestone:** M2 · **Status:** complete

## Progress

- Confirmed M1 has no gravity autoload or finite-disk field. The user later clarified that the project must use standard 9.8 m/s² global-down gravity, with no horizontal or center-push force.
- Camera orientation stays aligned to global up; M2 does not add a disk-relative gravity query or field.
- Added configurable mouse and controller look sensitivity, screen-relative mouse input, a remapped controller deadzone, and local-only controller polling.
- Hid the local observer mesh/name label from its own first-person view; remote observers retain their presentation, and only the local observer activates its camera.
- Added unit coverage for controller look shaping, yaw wrapping/pitch clamping, and configurable sensitivity.
- Enforced local camera ownership while the observer is active and extended the separate-process multiplayer E2E to exercise the mouse-look path on host and clients, in addition to exclusive camera ownership.

## Verification

- `gdformat .` and `gdlint .`: passed.
- `Godot Console.exe --headless --path . --import`: passed.
- `Godot Console.exe --headless --path . --script res://tests/run_gut.gd`: 26 tests, 160 assertions, 0 failures. Logger `push_error` entries are expected and asserted by GUT.
- Boot smoke and default world scene: passed.
- Multiplayer E2E: passed with host + 5 clients, exclusive local cameras, local look input, movement replication, disconnect cleanup, and clean teardown logs.
- The development free-camera is intentionally non-colliding; normal movement camera clipping belongs to M3.

## Handoff

The camera and E2E work were committed as `64deacc` (`test: verify multiplayer camera look ownership`). M2 remains camera-only: global-down gravity is configured in M1, and M3 implements movement under that convention.
