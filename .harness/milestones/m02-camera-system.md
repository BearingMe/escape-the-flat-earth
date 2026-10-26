# M2 — Camera System

**Phase:** Foundation · **Depends on:** M1 · **Status:** complete (standard downward gravity)

## Goal
Create a playable first-person view that remains usable anywhere on the disk.

## Scope
- First-person camera with mouse/controller look and configurable sensitivity.
- Stable world-up view rotation consistent with global downward gravity; camera orientation does not introduce a separate gravity model.
- Manual view control for inspecting the disk in the development free-camera.
- Camera collision for normal movement is coupled to M3 actor collision; the development free-camera may pass through geometry.
- Local-player camera ownership; remote players must not control one another's cameras.
- Optional temporary free-camera debugging mode.

## Validation
- Mouse-look behavior is independent of the observer's location on the disk; unit coverage exercises look shaping and the separate-process E2E exercises local look input.
- Camera up remains global +Y; no horizontal, radial, or center-push gravity is added.
- Local inputs affect only the local player's view; host and five clients each verify exclusive camera ownership and local look input in separate processes.
- The development free-camera intentionally passes through geometry. Collision-backed camera clipping is validated with M3 movement, not this free-flight tool.
- Host and client each have independent, working views.

## Arowana notes
- The camera follows the global-down gravity convention; do not add a camera-driven gravity query or disk-center field to M2.
- Free-cam stays a dev/test tool only; in a BR it must never ship as gameplay (it is a wallhack and an escape cheat in one).
- Camera ownership is per-peer. Local view input is peer-gated; the host remains authoritative for replicated observer state.
- The user clarified on 2026-10-26 that normal Earth gravity (9.8 m/s²) acts along global downward Y only. M2's world-up camera convention matches that direction; it does not provide horizontal or center-push gravity.

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — OrbitCameraController rig patterns: orientation bases, occlusion handling.
- `physics_arsenal` — MIT, free to port — first-person interaction/feel patterns.
