# M5 — Five Biomes

**Phase:** World · **Depends on:** M4 · **Status:** not started

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
- All five biomes are present and distinguishable.
- Biome placement is reproducible from the same seed.
- Biome boundaries do not create unintended holes or terrain discontinuities.
- Ice wall coverage is continuous around the perimeter.
- Host, client, and late joiner agree on biome identity at sampled coordinates.
- Terrain and collision remain traversable where intended.

## Arowana notes
- The Ice Wall biome is the endgame perimeter — its "future escape challenges" hook is M19.
- Biome identity feeds M8 (map regions), M9 (weather), and M18 (spawning); keep the deterministic biome-data interface clean.
- The bit is canon: the ice wall is real, it is load-bearing, and the tundra exists because "beyond the wall it's provider-free" or some such in-game lore — written straight.

## References — search before building (mempalace wing `.references`, filter by room)
- `simple_x_terrain` — MIT, free to port — SplineConformNode / IslandMaskNode for perimeter shaping and noise-driven biome boundaries.
