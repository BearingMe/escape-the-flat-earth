# M18 — Enemies & AI

**Phase:** Challenges · **Depends on:** M5, M10, M17 · **Status:** complete

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

## Demo
- Encounter and engage the 5 distinct archetypes across biomes:
  1. Geodetic Drone (charging aerial rammer in Plains),
  2. Ice Wall Sentinel (boulder-throwing brute in Tundra/Rim),
  3. Void Swarmer (stamina-sapping pack in Forest),
  4. Patrol Rover (steam-pushing patrol vehicle on Underside),
  5. Magnetic Anomaly (metal-attracting singularity in Mountains).
- Automated tests verifying perception detection, pursuit behavior, projectile throwing, salvage drops, and clean entity despawn: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_enemy_archetype_definition.gd`: validates archetype stats, perception radii, attack cooldowns, and drop tables.
- `tests/unit/test_ai_perception_steering.gd`: validates line-of-sight checks, pursuit steering vectors, retreat thresholds, and magnetic attraction physics.
- `tests/integration/test_enemy_encounter_lifecycle.gd`: validates host-authoritative AI state machines, player targeting, boulder throwing, defeat salvage drops, and leak-free despawning.

## Authority
- Host owns all AI perception, navigation steering, attack timers, health pools, and loot drops.
- Clients replicate enemy transforms and play local audio/visual cues.

## Dependencies
- Upstream M5 Five Biomes, M10 Physical Props and Impact Damage, M12 Survival State.

## Performance
- Perception updates: throttled to staggered intervals (5 Hz / 0.2s) with distance squared pruning (< 50 µs total per frame across active enemies).
- Active enemy budget: capped at 24 world entities simultaneously.

## Known limitations
- Complex hierarchical task network (HTN) planning is omitted in favor of robust, responsive utility state machines tailored for fast multiplayer BR combat.

## Failure modes
- Enemy target dies or disconnects: immediately clears target and returns to patrol/idle state.
- Terrain obstruction / entrapment: unstuck watchdog teleports or pathfinds toward the nearest valid surface point.

## Arowana notes
- PvE enemies herd players toward the rim — soft match pacing that keeps the race moving when nobody wants to be first over the wall.
- Five archetypes must be mechanically distinct AND absurd (played straight). In a BR, enemies pressure every player equally — no player-owned AI, ever.
- Enemies should also react to improvised junk (M10/M15/M16) — a buildable anti-enemy contraption is the sandbox promise kept.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — HitboxRig/damage patterns.
- Navigation goes through Godot's NavigationServer — no reference repo; search the mempalace rooms for nav patterns before writing from scratch.
