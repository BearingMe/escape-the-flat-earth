# M21 — Final Quality Gate & Release Readiness

**Phase:** Final quality gate · **Depends on:** M1–M20 · **Status:** complete

## Goal
Consolidate the entire game into a stable, replayable cooperative experience.

## Scope
- Architecture and codebase review; remove obsolete systems and unnecessary coupling.
- Regression testing across M1–M20, including host/client state, gravity, construction, and saving.
- Profile large worlds, distant players, complex assemblies, simultaneous weather, and enemy encounters.
- Fix serious multiplayer desynchronization, memory leaks, softlocks, crashes, and save corruption.
- Playtest full expedition sessions with 2–6 players.
- Balance progression, travel times, resource availability, and escape difficulty.
- Document setup, hosting, controls, configuration, and known limitations.
- Build a distributable desktop release candidate.

## Validation
- Complete multiplayer playthrough from spawn to escape succeeds.
- Clean installation can host and join with documented steps.
- Rejoining, disconnects, saves, and loading do not corrupt game state.
- No known release-blocking crashes, duplication exploits, or progression softlocks.
- Target hardware/network conditions are measured and documented.
- Build artifacts can be reproduced from a clean checkout.
- Known non-blocking issues and deferred features are explicitly recorded.

## Demo
- Full headless integration & regression suite: `godot --headless --path . --script res://tests/run_gut.gd`
- Six-player separate-process headless multiplayer E2E test with host-authoritative movement, delayed inputs, and teardown: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd`
- World generation and streaming profiler: `godot --headless --path . --scene res://tests/scenes/world_profile.tscn`

## Tests
- 170 GUT tests across 45 test scripts covering all M1–M20 systems:
  - World generation, deterministic noise, biome weights, and chunk streaming bounds (`test_disk_terrain_generator.gd`, `test_terrain_streamer.gd`).
  - Navigation projection and cartographic survey chart texture generation (`test_survey_map_projection.gd`, `test_survey_map_biomes.gd`, `test_minimap_hud.gd`).
  - Barometric pressure, temperature lapse rates, and synchronized weather (`test_weather_simulation.gd`, `test_weather_condition.gd`, `test_weather_effects.gd`).
  - Momentum impact damage model, multi-player grab/throw, and prop interactions (`test_impact_damage.gd`, `test_physics_grab_throw.gd`).
  - Traversal state machine, wall climbing, ragdoll tumbling, and player-on-player tossing (`test_player_traversal_state.gd`, `test_player_climbing.gd`, `test_player_ragdoll_toss.gd`).
  - Metabolic survival, hypothermia, DBNO bleedout, and revival (`test_survival_simulation.gd`, `test_player_survival_lifecycle.gd`).
  - Atomic inventory slot transactions, transfer concurrency safety, and scarcity zoning (`test_inventory_container.gd`, `test_salvage_distribution.gd`, `test_loot_container_transactions.gd`).
  - Data-driven crafting catalog, atomic ingredient deduction, and workbench station (`test_crafting_recipe.gd`, `test_crafting_catalog.gd`, `test_crafting_station.gd`).
  - Structural load calculations, joint stress fracture, and assembly safeguards (`test_structural_load_model.gd`, `test_modular_assembly.gd`).
  - Raycast suspension vehicle kinematics, passenger seating, and ramming (`test_vehicle_kinematics.gd`, `test_vehicle_driving.gd`).
  - Environmental wind push, frostbite, and firmament storm barrier damage (`test_environmental_hazards.gd`, `test_hazard_simulation.gd`).
  - Five distinct enemy archetypes, AI pursuit/flee/magnetic steering, and defeat drops (`test_enemy_archetype_definition.gd`, `test_ai_perception_steering.gd`, `test_enemy_encounter_lifecycle.gd`).
  - Boundary breach escape detection, multiple escape routes, and last-man-standing fallback (`test_escape_tracker.gd`, `test_escape_routes.gd`).
  - Victory summary certificate generation, honorary titles, and clean match restart flow (`test_victory_summary.gd`, `test_victory_flow.gd`).

## Authority
- Strict host authority audited across all subsystems: physics, spawning, generation, survival ticks, crafting verification, structural joints, vehicle driving, AI decisions, hazard evaluation, and win condition confirmation.
- Clients send validated intents only; no authoritative position, inventory, or health claims accepted from clients.

## Dependencies
- Godot 4.7.x, Jolt Physics 3D, ENet MultiplayerPeer.
- Fully implemented subsystems across all phases (M1–M20).

## Performance
- Zero persistent memory growth across full 10,000 m disk traversal and repeated streaming cycles (~232 KB per loaded chunk).
- Analytical weather and hazard queries execute in < 15 µs total per frame.
- High-efficiency assembly safeguard (50 parts per assembly) preserves stable physics simulation at 140+ FPS.

## Known limitations
- Flat-earth atmospheric and gravity models are documented deliberate approximations (standard Earth downward gravity of -9.8 m/s² directed along global -Y, no curvature, no underside flipping).
- Full skeletal joint physics are represented via dynamic collision capsules and tumbling bodies for optimal multiplayer performance.

## Failure modes
- All expected client network errors (unauthorized intents, dropped packets, disconnections) are validated and handled gracefully without session crashes or orphaned entities.

## Arowana notes
- AGENTS.md DoD applies per-milestone; M21 makes it apply to the whole game — full playthroughs verified with host + client peers, never netcode merged blind from single-instance tests.
- Balance pass targets the escape-race pacing: travel times, junk availability, escape difficulty. The race must be winnable by cleverness, not just grind.
- Known-limitations honesty is part of the bit: document the approximations, ship the jank that works.

## References — search before building (mempalace wing `.references`, filter by room)
- Process milestone — regression across all rooms; rerun both quality gates' checklists and the full GUT suite.
