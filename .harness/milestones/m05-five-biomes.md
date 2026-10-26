# M5 — Five Biomes

**Phase:** World · **Depends on:** M4 · **Status:** complete

## Goal
Partition the disk into five distinct procedural environments.

## Scope
- **Plains:** grassland and gentle hills.
- **Forest:** wooded terrain zones and varied elevation.
- **Mountains:** peaks, cliffs, valleys, and rocky ground.
- **Tundra:** snow-covered, sparsely populated outer regions.
- **Ice Wall:** perimeter glaciers and a formidable boundary.
- Position-informed biome distribution with noise-driven irregular boundaries.
- Blended elevation/material transitions where appropriate.
- Deterministic biome data exposed to other systems.
- Ensure the ice wall surrounds the full perimeter while allowing future escape challenges.

## Validation
- [x] All five biomes are reachable and distinct biome profiles produce distinct terrain colors.
- [x] Biome weights, heights, and chunk fingerprints are reproducible from the same seed.
- [x] Blended boundaries stay continuous; adjacent chunks share height, normal, and color samples.
- [x] Ice Wall identity and raised terrain continue around the full perimeter.
- [x] Host and all clients, including late joiners with a different requested seed, agree on sampled biome IDs.
- [x] Terrain collision and player grounding remain functional.

## Implementation handoff

- **Demo:** Run the flat-earth world to inspect biome-tinted terrain, or run `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd` to compare biome IDs on a host and five separate clients with mismatched requested seeds.
- **Tests:** GUT verifies all five IDs are reachable, data profiles are distinct, the Ice Wall is continuous around the perimeter, seeded biome weights repeat and normalize, transitions blend elevation/material color, and adjacent mesh seams remain identical. Existing integration coverage checks terrain collision and traversal.
- **Authority:** Biomes are deterministic derived data from the host-synchronized world seed/config and shared `.tres` definitions. Each peer evaluates the same sampler locally; no per-coordinate biome state is networked. `DiskTerrainGenerator.sample_biome_id`, `sample_biome`, and `sample_biome_weights` are the public lookup interface for map/weather/spawn systems.
- **Dependencies:** M4 `WorldConfig`, disk-clipped chunk mesh/collision, and host-authoritative configuration synchronization.
- **Performance:** Biome color/elevation are blended at terrain vertices; chunk generation remains capped at two chunks per frame by M4. No separate biome-generation frame-time benchmark has been recorded.
- **Known limitations:** Current biome surface distinction is data-driven color and elevation shaping; trees, shrubs, rocks, and ice props belong to M6. The Ice Wall is a continuous raised perimeter biome/ridge, not yet a vertical, breachable obstacle; escape challenges remain M19.
- **Failure modes:** Invalid or incomplete biome profiles fail catalog validation and terrain-generator configuration. Deterministic weights are normalized and resource IDs are checked for uniqueness; existing chunk-generation error handling remains responsible for mesh/collision failures.

## Arowana notes
- The Ice Wall biome is the endgame perimeter — its "future escape challenges" hook is M19.
- Biome identity feeds M8 (map regions), M9 (weather), and M18 (spawning); keep the deterministic biome-data interface clean.
- The bit is canon: the ice wall is real, it is load-bearing, and the tundra exists because "beyond the wall it's provider-free" or some such in-game lore — written straight.

## References — search before building (mempalace wing `.references`, filter by room)
- `simple_x_terrain` — MIT, free to port — SplineConformNode / IslandMaskNode for perimeter shaping and noise-driven biome boundaries.
