# M8 — Minimap & World Map

**Phase:** Environment · **Depends on:** M5, M7 · **Status:** complete

## Goal
Give players reliable navigation on a finite disk.

## Scope
- Circular minimap showing the disk's actual shape.
- Player position, heading, and positions of teammates where appropriate.
- Distinct biome regions derived from generated world data.
- Configurable zoom and north-up/camera-relative rotation.
- Optional full-screen map.
- Clear representation of rim and underside traversal.
- Client-local UI backed by authoritative world coordinates.

## Validation
- Map location matches world location at known test points.
- Biome boundaries agree with generated terrain.
- Teammate markers update correctly and disappear on disconnect.
- Heading, zoom, and orientation work on all sides of the disk.
- Minimap remains responsive with several players exploring different regions.

## Demo
- Interactive HUD and fullscreen survey map: press `M` in-game to toggle the official Flat Earth Survey Commission chart; toggle zoom and rotation modes (`N` for North-Up vs. Heading-Up).
- Automated test suite verifying projection, biome fidelity, heading, and teammate lifecycle: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_survey_map_projection.gd`: validates polar azimuthal coordinate transforms, heading calculations, zoom boundaries, and traversal zone classification (Interior, Tundra, Ice Wall, Abyss/Underside).
- `tests/unit/test_survey_map_biomes.gd`: validates generated survey chart colors and biome IDs match `DiskTerrainGenerator` across seeds and test coordinates.
- `tests/integration/test_minimap_hud.gd`: validates local observer tracking, camera-relative and north-up orientations, full-screen map toggling, and teammate marker lifecycle without opponent leaks.

## Authority
- All survey map calculations run client-locally.
- The map queries the local player's authoritative transform and local world state; teammates are tracked only via explicit squad registration or network peer lifecycle. No opponent transforms are synchronized to non-host clients in FFA mode.

## Dependencies
- Upstream M1–M7 systems: `WorldConfig`, `DiskTerrainGenerator`, `TerrainBiomeCatalog`, `ObserverPlayer`, `World`, `Net`.

## Performance
- Survey chart texture generation: precomputed once per seed (128x128 or 256x256 image cached in memory, < 15 ms generation time, 0 allocations per frame).
- Minimap rendering: single 2D draw pass in HUD canvas layer; minimal draw calls (< 5) and sub-microsecond transform math per frame.

## Known limitations
- Free-for-all mode displays only the local observer; team/squad tracking is enabled when squad groupings are configured.
- Underside traversal is indicated via telemetry badges (e.g. altitude negative / firmament inverted status) rather than a separate inverted underside topographical raster.

## Failure modes
- Unconfigured world config: gracefully falls back to default world configuration and logs warning.
- Invalid player reference or dead player: preserves last known coordinates and displays disconnected/lost telemetry.
- Disconnected teammate: removes teammate marker immediately upon peer disconnection signal.

## Arowana notes
- The map is itself a lore artifact: render it as an "official" flat-earth survey chart — played 100% straight, no winking.
- BR discipline: opponents' positions must never reach the UI except through legitimately visible state (e.g. last-known from your own sightings). No authoritative-position leaks.
- With 2–6 free-for-all players, "teammates where appropriate" means squad mode only if/when it exists — default FFA renders no other markers.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — plain Godot Control/UI over authoritative world data; biome regions come from M5's deterministic data.
