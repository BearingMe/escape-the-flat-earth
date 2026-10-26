# M2 — Camera System

**Date:** 2026-10-26 · **Milestone:** M2 · **Status:** revision verified / pending commit

## Progress

- Confirmed M1 gravity reconciliation is committed: no gravity autoload or finite-disk field remains, and Godot project-wide 3D default gravity is `0.0`.
- Per the user's latest clarification, do not restore the removed gravity implementation. Gravity-relative orientation and transition acceptance are excluded from M2 and remain deferred.
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
- Gravity-relative transitions remain deferred. The development free-camera is intentionally non-colliding; normal movement camera clipping belongs to M3.

## Handoff

Commit the zero-gravity camera scope and E2E coverage. After that commit, mark M2 complete in a separate documentation commit; begin M3 with gravity still removed.
