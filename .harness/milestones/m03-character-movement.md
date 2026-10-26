# M3 — Character Movement

**Phase:** Foundation · **Depends on:** M1, M2 · **Status:** in progress (standard gravity scope)

## Goal
Implement reliable, multiplayer-compatible first-person movement under standard Earth gravity (9.8 m/s² along global downward Y).

## Scope
- Walking, sprinting, jumping, and falling using global-down gravity; no horizontal, radial, or center-push gravity.
- Acceleration, stopping, air control, and grounded detection.
- Slopes, ledges, steps, and collision response.
- Character orientation upright relative to global +Y.
- Host-authoritative movement state with client intent validation, periodic state replication, and client-side position smoothing.
- Stable host-assigned spawn placement and recovery from invalid movement states; death/respawn lifecycle remains a later match-state feature.
- Debug movement telemetry and repeatable traversal test routes.

## Validation
- Movement and grounding work on the disk's upper surface and traversable slopes under 9.8 m/s² downward gravity.
- Jump trajectories use the same global-down 9.8 m/s² acceleration everywhere.
- Acceleration and braking are bounded, and vertical gravity does not accelerate horizontal movement.
- The underside and vertical rim do not attract or support the player; no horizontal/radial gravity is introduced.
- Two or more players can traverse simultaneously without major jitter or desynchronization.
- Simulated network delay does not cause persistent incorrect positions.
- Spawned actors land on the disk, and invalid/stale intents cannot produce persistent movement.

## Arowana notes
- Gravity is a constant global-down vector, not a finite-disk field. Do not align movement or character up to the disk center.
- Jump arcs use ordinary Earth gravity; launching junk and players remains a later physics interaction.
- Host-authoritative state + interpolation/prediction; the simulated-delay check is load-bearing for a BR, not an edge case.

## Handoff
- **Demo:** host and client spawn on the upper surface; WASD moves, Shift sprints, Space jumps, and gravity pulls downward at 9.8 m/s².
- **Tests:** GUT movement/validation unit tests and collision integration tests; separate-process multiplayer E2E verifies grounding, client intent movement resolved by the host, replication, and disconnect cleanup.
- **Authority:** clients send bounded horizontal input, sprint/jump requests, and view angles only. The host applies gravity, collision, movement, and canonical transforms; clients smooth toward replicated server positions.
- **Dependencies:** M1 disk collision and 9.8 m/s² downward project gravity; M2 camera yaw/pitch and local ownership; Godot `CharacterBody3D` and `MultiplayerSynchronizer`.
- **Performance:** movement resolves once per physics tick per player; transform targets replicate at 20 Hz and render position is smoothed client-side.
- **Known limitations:** gravity is global downward only; the disk underside and vertical rim are not walkable. Death/respawn lifecycle belongs to later match-state work. No finite-disk, radial, horizontal, or center-push field is modeled.
- **Failure modes:** malformed or excessive movement intents are ignored; missing remote intents are neutralized after a bounded timeout; the host never accepts client positions.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — movement, fall damage, shape-query headroom checks.
- `vantix` — Apache-2.0, free to port — lag compensation and reconciliation patterns.
- `modu_vehicle` — CC0, free to port — raycast ground-probe patterns (suspension math doubles as ground detection).
