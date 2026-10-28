# M19 — Escape Mechanics

**Phase:** Endgame · **Depends on:** M15, M16, M17, M18 · **Status:** complete

## Goal
Convert "reach the rim" into an actual engineering and traversal endgame.

## Scope
- Define escape as host-confirmed travel beyond the disk's outer boundary, not leaving a custom gravity field.
- Support multiple plausible attempts rather than a single scripted key/door.
- Integrate vehicles, machines, climbing, weather, supplies, and standard global-down gravity into escape attempts.
- Provide buildable or discoverable endgame equipment and sufficient resources.
- Make rim/ice wall traversal a meaningful final obstacle.
- Detect meaningful success/failure from authoritative world state.
- Recover or restart after failed attempts without corrupting persistent progression.

## Validation
- At least two materially different escape strategies can succeed in test scenarios.
- Global-down gravity and physics remain consistent during attempts; no arbitrary edge teleport.
- The game detects an authentic escape without a fragile single trigger volume.
- Escaping works with multiple players, including passengers and separated teammates.
- Failed attempts leave the world in a valid, playable state.
- Endgame materials and goals are reachable from a fresh game.

## Demo
- Execute two distinct escape strategies across the finite disk boundary:
  1. *Endurance Climb & Vault*: scale the outer Ice Wall crest on foot with thermal wraps and grapple, vaulting over the rim into free-fall.
  2. *Vehicular Ramp Launch*: build a modular scaffold ramp with M15 parts and launch an M16 recon sled at terminal speed over the edge.
- Automated tests verifying radial boundary breach detection, vehicle passenger escapes, last-one-standing fallback, and session restart: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_escape_tracker.gd`: validates continuous boundary math (radial distance > 5000m, altitude criteria, vehicle passenger inheritance, and last-man-standing fallback).
- `tests/integration/test_escape_routes.gd`: validates both traversal strategies (foot vault vs vehicular ramp launch), host win-condition evaluation, and match conclusion signaling.

## Authority
- Host strictly owns canonical escape confirmation, match timer, victor designation, and match termination.
- Clients receive victory RPCs and render final escape telemetry overlays.

## Dependencies
- Upstream M3 Standard Gravity, M11 Advanced Traversal, M15 Modular Construction, M16 Vehicles, M17 Hazards, M18 Enemies.

## Performance
- Boundary tracking: evaluated at low overhead during physics ticks ($x^2 + z^2 > R^2$ calculation takes < 1 µs per player).

## Known limitations
- Cinematic story cutscenes and alien reveals are handled in M20; M19 focuses on the physics escape boundary detection and win condition resolution.

## Failure modes
- Premature fall into abyss prior to reaching rim: detected as falling failure rather than intentional escape if aborted within interior hole/hazard.
- Simultaneous escapes: host uses arrival timestamp to break ties deterministically.

## Arowana notes
- AGENTS.md canon: the first player off the disc ends the match; if everyone dies trying, last one standing wins. "Who escapes" is a race outcome, not a shared ceremony — rivals may cooperate mid-run, but the finish line is zero-sum.
- Escape is a physics fact, not a trigger volume: the host detects travel beyond the disk boundary. No custom gravity-influence threshold, teleport, or fragile Area3D at the rim.
- Two materially different strategies, e.g. a built machine (M15/M16) vs an endurance climb (M11/M17) — and whatever cursed third thing the community invents.

## References — search before building (mempalace wing `.references`, filter by room)
- `simple_x_terrain` — MIT, free to port — rim/boundary geometry math.
- `vantix` — Apache-2.0, free to port — authoritative world-state detection patterns.
