# M2 — Camera System

**Phase:** Foundation · **Depends on:** M1 · **Status:** not started

## Goal
Create a playable first-person view that remains usable anywhere on the disk.

## Scope
- First-person camera with mouse/controller look and configurable sensitivity.
- Gravity-relative up/down orientation and stable view rotation.
- View behavior for rim traversal and underside exploration.
- Camera collision and clipping protections where needed.
- Local-player camera ownership; remote players must not control one another's cameras.
- Optional temporary free-camera debugging mode.

## Validation
- Camera responds consistently at center, rim, and underside.
- No sudden orientation flips when local gravity direction changes.
- Local inputs affect only the local player's view.
- Camera cannot accidentally clip through solid disk geometry during ordinary operation.
- Host and client each have independent, working views.

## Arowana notes
- The rim/underside orientation flip is the signature shot of the entire game — treat "no sudden orientation flips" as a feature test, not a corner case.
- Free-cam stays a dev/test tool only; in a BR it must never ship as gameplay (it is a wallhack and an escape cheat in one).
- Camera ownership is per-peer — guard with `is_multiplayer_authority()` (AGENTS.md).

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — OrbitCameraController rig patterns: orientation bases, occlusion handling.
- `physics_arsenal` — MIT, free to port — first-person interaction/feel patterns.
