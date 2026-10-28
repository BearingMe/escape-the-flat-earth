# Architecture

## System shape
Headless-first multiplayer peer-to-peer sandbox in Godot 4. Host is authoritative over physics, generation, and canonical game state; clients simulate local cameras, collect inputs, and interpolate replicated server transforms.

## Layers and modules
- `autoload/` — Global runtime singletons (`Log`, `World`, `Net`). Owns process lifecycle, peer topology, and host prop registry. Must not depend on gameplay feature scenes.
- `common/` — Shared domain logic, generator math, and custom Resources (`WorldConfig`, `DiskTerrainGenerator`, `TerrainBiomeCatalog`, `TerrainPopulationGenerator`, `TerrainChunkPopulation`). Pure data/logic; zero scenes or UI.
- `entities/world/` — World geometry, disk base (`disk.tscn`), chunk streaming (`terrain_streamer.tscn`), chunks (`terrain_chunk.tscn`), and MultiMesh visual batches (`terrain_population_view.gd`).
- `entities/player/` — Observer avatar (`observer.tscn` + `observer.gd`). Handles local camera control, client intent forwarding, and server-authoritative CharacterBody3D kinematic simulation.
- `levels/flat_earth/` — Main world scene (`world.tscn`) and scene coordinator (`world_controller.gd`). Binds netcode, spawners, and debug overlays.
- `ui/` — Menus and heads-up displays. Visuals and user input only; queries state via autoload signals and APIs.
- `tests/` — GUT unit/integration suites (`tests/unit/`, `tests/integration/`) and multi-process headless scenarios (`tests/e2e/`).

## Dependency rules
- Gameplay scripts never use relative node climbing (`../`) or absolute tree paths (`/root/...`). Node references use `@onready` + `%` unique names.
- `common/` never imports scenes (`.tscn`).
- `entities/` interact across features via signals, group queries (`get_nodes_in_group`), or autoload singletons (`World`, `Net`, `Log`).
- Clients never mutate canonical world or player state; mutations pass to the host via explicit `@rpc` annotations.

## Authority and data flow
1. **Hosting & Session Configuration**: The host loads or synchronizes `WorldConfig` (seed, radius, chunk dimensions). When clients connect, `Net` transmits the canonical `WorldConfig` via `MultiplayerSpawner` spawn data.
2. **Deterministic World Generation**: Host and clients derive matching terrain heightmaps and prop placement independently using identical seed, chunk coordinates, and noise parameters (`DiskTerrainGenerator`, `TerrainPopulationGenerator`).
3. **Prop Registry Authority**: While client chunks render prop visuals via non-colliding `MultiMeshInstance3D` batches (`TerrainPopulationView`), only the host registers prop identities and state in `World` (`register_static_prop_chunk`).
4. **Movement & Physics**: Clients read local keyboard/mouse/gamepad input and forward movement intents to the host (`submit_movement_intent.rpc_id(1, ...)`). The host validates intent bounds, simulates movement under standard gravity, and replicates canonical positions via `MultiplayerSynchronizer`.

## Gravity and physics assumptions
- **Standard Downward Gravity**: Fixed at 9.8 m/s² directed along global negative Y (`Vector3(0, -1, 0)`).
- **No Curvature or Underside Flipping**: The disk is a flat, rigid cylinder (radius 5,000 m, thickness 500 m). Gravity remains globally downward across the entire surface and over the disk edge.
- **Off-Disc Condition**: Leaving the outer rim results in continuous vertical downward free-fall.

## Operational setup and verification
- **Editor & Tools**: Godot 4.x (standard/mono), GDScript 2.0. Python `gdtoolkit` (`gdformat`, `gdlint`).
- **Asset Import**: `godot --headless --path . --import`
- **Boot Smoke**: `godot --headless --path . --scene res://tests/scenes/boot_smoke.tscn --quit-after 60`
- **Unit and Integration Tests**: `godot --headless --path . --script res://tests/run_gut.gd`
- **Multiplayer Smoke**: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd`
- **Distant Exploration E2E**: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd -- --e2e-distant-exploration`
- **World Profiler**: `godot --headless --path . --scene res://tests/scenes/world_profile.tscn`
- **Format and Lint**: `gdformat --check .` and `gdlint .`
