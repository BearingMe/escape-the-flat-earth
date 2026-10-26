# M18 — Enemies & AI

**Phase:** Challenges · **Depends on:** M5, M10, M17 · **Status:** not started

## Goal
Introduce five enemy archetypes with distinct mechanics rather than five health-bar variations.

## Scope
- AI framework with perception, navigation, pursuit, retreat, and combat/interaction behaviors.
- Five thematically absurd archetypes, with final names/designs decided during this milestone.
- Distinct strengths, weaknesses, and responses to terrain, weather, physics objects, or machines.
- Biome-aware spawning and encounter intensity.
- Group encounters and opportunities for cooperative counterplay.
- Host-owned AI decisions and authoritative damage/physics interactions.
- Debug tools for encounter spawning and behavior inspection.

## Validation
- All five enemies have recognizably different tactics.
- AI navigates appropriate terrain and does not routinely get stuck.
- Enemies respond consistently to nearby players and relevant physics stimuli.
- Two or more players can engage the same enemy without conflicting state.
- Spawns and despawns do not leak entities or degrade long sessions.
- Encounters are survivable with intended equipment and teamwork.

## Arowana notes
- PvE enemies herd players toward the rim — soft match pacing that keeps the race moving when nobody wants to be first over the wall.
- Five archetypes must be mechanically distinct AND absurd (played straight). In a BR, enemies pressure every player equally — no player-owned AI, ever.
- Enemies should also react to improvised junk (M10/M15/M16) — a buildable anti-enemy contraption is the sandbox promise kept.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — HitboxRig/damage patterns.
- Navigation goes through Godot's NavigationServer — no reference repo; search the mempalace rooms for nav patterns before writing from scratch.
