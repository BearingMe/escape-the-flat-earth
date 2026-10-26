# M19 — Escape Mechanics

**Phase:** Endgame · **Depends on:** M15, M16, M17, M18 · **Status:** not started

## Goal
Convert "reach the rim" into an actual engineering and traversal endgame.

## Scope
- Define what counts as escape in terms of leaving the disk's environment/gravitational influence.
- Support multiple plausible attempts rather than a single scripted key/door.
- Integrate vehicles, machines, climbing, weather, supplies, and gravity into escape attempts.
- Provide buildable or discoverable endgame equipment and sufficient resources.
- Make rim/ice wall traversal a meaningful final obstacle.
- Detect meaningful success/failure from authoritative world state.
- Recover or restart after failed attempts without corrupting persistent progression.

## Validation
- At least two materially different escape strategies can succeed in test scenarios.
- Gravity and physics remain consistent during attempts; no arbitrary edge teleport.
- The game detects an authentic escape without a fragile single trigger volume.
- Escaping works with multiple players, including passengers and separated teammates.
- Failed attempts leave the world in a valid, playable state.
- Endgame materials and goals are reachable from a fresh game.

## Arowana notes
- AGENTS.md canon: the first player off the disc ends the match; if everyone dies trying, last one standing wins. "Who escapes" is a race outcome, not a shared ceremony — rivals may cooperate mid-run, but the finish line is zero-sum.
- Escape is a physics fact, not a trigger volume: beyond-gravity-influence detection, computed by the host. No teleport, no fragile Area3D at the rim.
- Two materially different strategies, e.g. a built machine (M15/M16) vs an endurance climb (M11/M17) — and whatever cursed third thing the community invents.

## References — search before building (mempalace wing `.references`, filter by room)
- `simple_x_terrain` — MIT, free to port — rim/boundary geometry math.
- `vantix` — Apache-2.0, free to port — authoritative world-state detection patterns.
