# M2 — Camera System

**Phase:** Foundation · **Depends on:** M1 · **Status:** complete (zero-gravity scope)

## Goal
Create a playable first-person view that remains usable anywhere on the disk.

## Scope
- First-person camera with mouse/controller look and configurable sensitivity.
- Stable world-up view rotation for the current zero-gravity prototype; this is a camera convention, not a gravity model.
- Manual view control for inspecting the disc center, rim, and underside in free flight.
- Camera collision for normal movement is coupled to M3 actor collision; the development free-camera may pass through geometry.
- Local-player camera ownership; remote players must not control one another's cameras.
- Optional temporary free-camera debugging mode.

## Validation
- Mouse-look behavior is independent of the observer's location on the disk; unit coverage exercises look shaping and the separate-process E2E exercises local look input.
- Gravity-relative up alignment and no-flip transitions remain deferred; no gravity source is added to satisfy this milestone.
- Local inputs affect only the local player's view; host and five clients each verify exclusive camera ownership and local look input in separate processes.
- The development free-camera intentionally passes through geometry. Collision-backed camera clipping is validated with M3 movement, not this free-flight tool.
- Host and client each have independent, working views.

## Arowana notes
- Gravity-driven rim/underside orientation is deferred with gravity; do not add a gravity query or field to M2.
- Free-cam stays a dev/test tool only; in a BR it must never ship as gameplay (it is a wallhack and an escape cheat in one).
- Camera ownership is per-peer. Local view input is peer-gated; the host remains authoritative for replicated observer state.
- The user confirmed on 2026-10-26 that the removed center-push gravity is not to be restored. M2 uses world-up only as a zero-gravity camera convention, never as a gameplay down-vector.

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — OrbitCameraController rig patterns: orientation bases, occlusion handling.
- `physics_arsenal` — MIT, free to port — first-person interaction/feel patterns.
