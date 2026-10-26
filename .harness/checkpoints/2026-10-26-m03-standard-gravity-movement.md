# M3 — Character Movement

**Date:** 2026-10-26 · **Milestone:** M3 · **Status:** complete

## Progress

- Applied the user's correction: normal Earth gravity is 9.8 m/s² along global downward Y only; no horizontal, radial, or center-push gravity.
- Replaced the free-flight observer with a host-simulated `CharacterBody3D` capsule and deterministic stable-ID spawn slots arranged on the disk's upper surface.
- Added ground/air acceleration, braking, sprint, jump, bounded fall speed, slope snapping, and collision against the disk and other static geometry.
- Clients send bounded planar input, sprint/jump requests, and view angles; the host owns all movement, gravity, collision, and canonical positions. Malformed intents are rejected and stale input is neutralized.
- Replicated host positions at 20 Hz and added client-side position smoothing with a snap threshold for large corrections.
- Extended the multiplayer E2E with 100 ms delayed client intent streams, spawn grounding, host-resolved movement, client convergence to host snapshots, and the existing six-peer disconnect/teardown checks.
- Added unit coverage for movement bounds, acceleration/braking, and spawn spacing; integration coverage for falling, landing, jumping, wall collision, slope traversal, and falling off the disk edge.

## Verification

- Godot 4.7.2 `--headless --path . --import`: passed.
- Boot-smoke scene and default world scene: passed.
- GUT: 34 tests, 188 assertions, 0 failures. Logger `push_error` output is expected and asserted.
- Six-process multiplayer E2E: passed with five clients, 100 ms delayed movement intents, host-side grounding/movement, replicated-position convergence, one clean disconnect, and orderly teardown.
- `gdformat --check .`, `gdlint .`, and `git diff --check`: passed.
- No gravity autoload, radial field, or horizontal gravity was reintroduced.

## Handoff

M3 was committed as `4c963fb` (`feat: add host-authoritative character movement`). Begin M4. Keep the project gravity magnitude at 9.8 m/s² with direction `(0, -1, 0)`; terrain work must not add horizontal or disk-center gravity.
