# Architecture

## System Shape
Headless-first multiplayer peer-to-peer sandbox in Godot 4. Host is authoritative over physics simulation, procedural generation, survival metabolism, crafting, building, vehicle dynamics, AI logic, and match victory conditions; clients simulate local cameras, collect inputs, render cartographic HUD overlays, and interpolate replicated server transforms.

## Layers and Modules
- `autoload/`: Global runtime singletons (`Log`, `World`, `Net`). Owns process lifecycle, peer topology, weather broadcast, hazard simulation, and escape tracking.
- `common/`: Shared domain logic, custom Resources, and mathematical models (zero scenes, zero UI dependencies):
  - World & Terrain: `WorldConfig`, `DiskTerrainGenerator`, `TerrainBiomeCatalog`, `TerrainBiomeDefinition`, `TerrainPopulationGenerator`, `TerrainChunkPopulation`.
  - Navigation & Cartography: `SurveyMapProjection`, `SurveyMapRaster`.
  - Atmospheric & Environmental: `WeatherCondition`, `WeatherSimulation`, `EnvironmentalHazardModel`, `HazardSystem`.
  - Physics & Combat: `PhysicalPropDefinition`, `ImpactDamageModel`, `PlayerTraversalState`.
  - Survival Economy: `SurvivalState`, `ConsumableDefinition`, `ItemDefinition`, `InventoryContainer`, `SalvageDistribution`, `CraftingRecipe`, `CraftingCatalog`.
  - Engineering & Transport: `ConstructionPartDefinition`, `StructuralLoadModel`, `ConstructionAssembly`, `VehicleKinematics`.
  - AI & Endgame: `EnemyArchetypeDefinition`, `AISteeringModel`, `EscapeTracker`, `VictorySummary`.
- `entities/world/`: World disk geometry (`disk.tscn`), chunk streaming (`terrain_streamer.tscn`), individual terrain chunks (`terrain_chunk.tscn`), MultiMesh prop batch views (`terrain_population_view.gd`), and camera-following atmospheric effects (`weather_controller.tscn`).
- `entities/player/`: Observer avatar (`observer.tscn` + `observer.gd`). Handles local first-person camera control, intent collection, kinematic simulation under -9.8 m/s² gravity, wall climbing, ragdoll tumbling, physical grabbing/throwing of props and players, survival tracking, and inventory.
- `entities/props/`: Interactive physical entities:
  - `physical_prop.tscn`: Grabbable/throwable `RigidBody3D` with multi-player tethering and impact damage.
  - `loot_container.tscn`: Shared storage chest with concurrent-safe atomic transactions.
  - `crafting_station.tscn`: World fabrication workbench for tool and contraption recipes.
  - `construction_part.tscn`: Modular structural pieces (beams, ramps) with socket attachment and joint stress fracture.
  - `vehicle_entity.tscn`: 4-wheel raycast suspension vehicle with driver and passenger seating.
- `entities/npcs/`: AI combat entities:
  - `enemy_entity.tscn`: CharacterBody3D driven by a 4-state utility machine across 5 distinct archetypes (Drone, Sentinel, Swarmer, Rover, Magnetic Anomaly).
- `ui/`: Heads-up displays and menus:
  - `ui/map/`: Circular brass-bezel minimap and full-screen Gleason azimuthal survey chart (`minimap.tscn` + `minimap.gd`).
  - `ui/menu/`: Match conclusion and Flat Earth Proof of Flatness certificate (`victory_screen.tscn` + `victory_screen.gd`).
- `levels/flat_earth/`: Main world scene (`world.tscn`) and scene coordinator (`world_controller.gd`). Binds netcode, spawners, streamer, weather, hazards, and UI.
- `tests/`: Headless test infrastructure:
  - `tests/unit/`: Pure domain and algorithmic calculations (28 scripts).
  - `tests/integration/`: Node and cross-entity interaction tests (17 scripts).
  - `tests/e2e/`: Multi-process scenarios verifying multi-client joining, convergence, and distant exploration.
  - `tests/scenes/`: Dedicated boot smoke (`boot_smoke.tscn`) and world profiler (`world_profile.tscn`).

## Dependency and Authority Rules
1. **Host Authority**: The host exclusively owns canonical transforms, physics bodies, joint attachments, health/stamina/metabolism, inventory slot contents, crafting deductions, AI decisions, and victory determination. Clients send validated intents only (`@rpc`).
2. **Standard Downward Gravity**: Fixed globally at 9.8 m/s² directed along global negative Y (`Vector3(0, -1, 0)`). No artificial radial gravity, center-directed force, or underside flipping exists anywhere on the disk.
3. **Improvised Combat**: Damage is strictly momentum-derived ($Damage = \text{clamp}((Momentum - Threshold) \times Factor, 0, Max)$). Objects and players hurled at speed deal physical impact damage.
4. **Deterministic Synthesis**: World geometry, biome weights, prop distributions, and salvage tables are derived identically from `WorldConfig` and the synchronized seed.
5. **No Tree Path Hardcoding**: All node references use `@onready` + `%` unique names. Script cross-talk occurs via signals, groups (`"network_players"`), or autoload APIs.

## Verification Procedures
- Asset Import: `godot --headless --path . --import`
- Boot Smoke Test: `godot --headless --path . --scene res://tests/scenes/boot_smoke.tscn --quit-after 60`
- Unit and Integration Suite: `godot --headless --path . --script res://tests/run_gut.gd`
- Multiplayer Smoke E2E: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd`
- Distant Exploration E2E: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd -- --e2e-distant-exploration`
- World Profiler: `godot --headless --path . --scene res://tests/scenes/world_profile.tscn`
- Formatter & Linter: `gdformat --check .` and `gdlint .`
