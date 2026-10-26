# M1 — Disk & Multiplayer Foundation

**Phase:** Foundation · **Depends on:** — · **Status:** complete (standard Earth gravity)

## Goal
Establish an explorable physical disk and a working multiplayer session as the project's foundation.

## Scope
- Create a Godot 4 GDScript project with an executable main scene and configurable world settings.
- Build a rigid disk with upper surface, underside, and rim, including collision.
- Use a configurable disk radius and thickness; default to 5 km and 500 m.
- Establish host/join for 2–6 players, player identity, spawning, and session teardown.
- Synchronize minimal player/observer positions and orientation using an explicit authority model.
- Provide a temporary spectator/debug controller for traversing and inspecting the disk; regular camera and movement come in M2–M3.
- Introduce a world seed and stable identifiers for entities likely to need persistence.
- Add debug overlays for network role and player count.

## Validation
- Host and at least one client connect and see each other moving.
- Five clients plus the host (six total peers) can join a local test session without duplicate player identities.
- A disconnected player is removed cleanly; the session continues.
- The upper surface, rim, and underside are inspectable and have valid collision.
- Godot's project-wide default gravity is 9.8 m/s² along global downward Y; no horizontal, radial, or center-push gravity is applied.
- Disk dimensions and world seed change through configuration, not source edits.
- A clean checkout builds and launches.

## Out of scope
- Gameplay camera, polished character movement, survival, inventories, persistent saves, dedicated servers.

## Arowana notes
- The session is the match lobby: this milestone is also the battle-royale foundation — 2–6 players, host-authoritative per AGENTS.md.
- The user clarified on 2026-10-26: use normal Earth gravity (9.8 m/s²) downward only. Do not implement horizontal, radial, or center-push gravity.
- Seed + stable IDs are the determinism groundwork M4's late-join parity leans on.
- The spectator controller is a dev/test tool only — never shippable as an escape cheat.

## Handoff
- **Demo:** default launch hosts a local session; `--join=<address> --port=<port>` joins it. The temporary free camera traverses the top, rim, and underside of the configured collider.
- **Tests:** deterministic world-configuration tests, a disk-scene integration test, and separate-process host/client E2E covering connection, host-resolved movement, and disconnect.
- **Authority:** host owns player transforms and entity IDs; clients submit bounded movement/view intents only. Disk configuration and seed are shared deterministic inputs; debug UI is local.
- **Dependencies:** Godot 4.7 ENet high-level multiplayer, project GUT harness, default `WorldConfig` resource. The six-player cap includes the host (maximum five clients).
- **Performance:** use Godot's built-in gravity; no custom gravity queries or field simulation run in M1. The free-flight observer is a development-only traversal tool.
- **Known limitations:** built-in gravity acts only along global downward Y, so it does not hold players to the underside or sides of the disk. The temporary free-flight observer ignores collision and is development-only. Regular character movement and camera polish remain in M2–M3.
- **Failure modes:** invalid config/port/host capacity is rejected before mutating session state; failed joins and disconnects return the session to a usable offline state; malformed client intents are ignored without changing host state.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — host-authoritative session patterns, lag compensation, network invariants.
- `simple_x_terrain` — MIT, free to port — IslandMaskNode disc-boundary math for rim/underside geometry.
- `voxelbound` — MIT, free to port — position sync / delta sync patterns for players.
