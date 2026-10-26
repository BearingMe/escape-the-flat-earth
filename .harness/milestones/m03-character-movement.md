# M3 — Character Movement

**Phase:** Foundation · **Depends on:** M1, M2 · **Status:** not started

## Goal
Implement reliable, multiplayer-compatible movement under arbitrary gravity vectors.

## Scope
- Walking, running, jumping, and falling using gravity-relative movement.
- Acceleration, stopping, air control, and grounded detection.
- Slopes, ledges, steps, and collision response.
- Character orientation aligned with local gravity.
- Host-authoritative movement state with practical interpolation or prediction.
- Spawn, reset, and recovery from invalid movement states.
- Debug movement telemetry and repeatable traversal test routes.

## Validation
- Movement works at disk center, near rim, and on underside.
- Jump trajectories change consistently with the local gravity field.
- Grounding and slopes remain stable across gravity changes.
- Two or more players can traverse simultaneously without major jitter or desynchronization.
- Simulated network delay does not cause persistent incorrect positions.
- Respawning does not duplicate actors or leave orphaned physics nodes.

## Arowana notes
- Gravity-relative movement means upside-down sprinting on the underside and sideways gait near the rim — the movement tech IS the bit.
- Jump-arc-under-local-gravity is also the first improvised-combat primitive (launching junk — and players — is born here).
- Host-authoritative state + interpolation/prediction; the simulated-delay check is load-bearing for a BR, not an edge case.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — movement, fall damage, shape-query headroom checks.
- `vantix` — Apache-2.0, free to port — lag compensation and reconciliation patterns.
- `modu_vehicle` — CC0, free to port — raycast ground-probe patterns (suspension math doubles as ground detection).
