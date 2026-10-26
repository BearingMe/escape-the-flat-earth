# M2 — Camera System

**Phase:** Foundation · **Depends on:** M1 · **Status:** in progress (gravity-dependent acceptance pending)

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
- Camera responds consistently at center, rim, and underside. **Pending:** gravity-relative orientation cannot be validated while gravity implementation is deferred.
- No sudden orientation flips when local gravity direction changes. **Pending:** gravity implementation is deferred.
- Local inputs affect only the local player's view. **Camera ownership verified** in separate host/client processes; exercising actual mouse/controller input independently remains pending.
- Camera cannot accidentally clip through solid disk geometry during ordinary operation. **Pending:** the current observer is free-flight; collision belongs with the movement/collision work.
- Host and client each have independent, working views. **Pending:** separate-process camera-input coverage remains to be added.

## Arowana notes
- The rim/underside orientation flip is the signature shot of the entire game — treat "no sudden orientation flips" as a feature test, not a corner case.
- Free-cam stays a dev/test tool only; in a BR it must never ship as gameplay (it is a wallhack and an escape cheat in one).
- Camera ownership is per-peer — guard with `is_multiplayer_authority()` (AGENTS.md).
- Per explicit user direction on 2026-10-26, gravity implementation remains deferred. Do not add a gravity autoload or query; keep up-vector alignment, rim/underside orientation, and gravity-transition acceptance pending. Mouse/controller look and local camera ownership can proceed independently.

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — OrbitCameraController rig patterns: orientation bases, occlusion handling.
- `physics_arsenal` — MIT, free to port — first-person interaction/feel patterns.
