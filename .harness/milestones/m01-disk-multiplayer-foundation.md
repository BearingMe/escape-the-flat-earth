# M1 — Disk & Multiplayer Foundation

**Phase:** Foundation · **Depends on:** — · **Status:** not started

## Goal
Establish an explorable physical disk and a working multiplayer session as the project's foundation.

## Scope
- Create a Godot 4 GDScript project with an executable main scene and configurable world settings.
- Build a rigid disk with upper surface, underside, and rim, including collision.
- Use a configurable disk radius and thickness; default to 5 km and 500 m.
- Establish a finite, uniform-density disk gravity model or a validated numerical approximation; calibrate central surface acceleration as configured.
- Expose local gravity as a vector independent from rendering meshes.
- Establish host/join for 2–6 players, player identity, spawning, and session teardown.
- Synchronize minimal player/observer positions and orientation using an explicit authority model.
- Provide a temporary spectator/debug controller for traversing and inspecting the disk; regular camera and movement come in M2–M3.
- Introduce a world seed and stable identifiers for entities likely to need persistence.
- Add debug overlays for network role, player count, and local gravity vector.

## Validation
- Host and at least one client connect and see each other moving.
- Six clients can join a local test session without duplicate player identities.
- A disconnected player is removed cleanly; the session continues.
- The upper surface, rim, and underside are inspectable and have valid collision.
- Gravity at the disk axis has no horizontal component; gravity points toward the disk on both sides.
- Gravity is finite and continuous at sampled locations, including the rim; compare against numerical reference values.
- World dimensions and gravity settings change through configuration, not source edits.
- A clean checkout builds and launches.

## Out of scope
- Gameplay camera, polished character movement, survival, inventories, persistent saves, dedicated servers.

## Arowana notes
- The session is the match lobby: this milestone is also the battle-royale foundation — 2–6 players, host-authoritative per AGENTS.md.
- Gravity goes behind an autoload API (never a per-node down-vector). Underside walkers exist from day one; that's the physics bit played straight.
- Seed + stable IDs are the determinism groundwork M4's late-join parity leans on.
- The spectator controller is a dev/test tool only — never shippable as an escape cheat.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — host-authoritative session patterns, lag compensation, network invariants.
- `simple_x_terrain` — MIT, free to port — IslandMaskNode disc-boundary math for rim/underside geometry.
- `voxelbound` — MIT, free to port — position sync / delta sync patterns for players.
- Finite uniform-disk gravity has no reference repo — derive analytically, validate against a numerical integrator.
