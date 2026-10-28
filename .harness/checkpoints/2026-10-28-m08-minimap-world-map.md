# Checkpoint — M8 Minimap & World Map

**Date:** 2026-10-28 · **Status:** complete

M8 implements client-local navigation on the finite disk rendered as an official Flat Earth Survey Commission cartographic chart (Gleason standard azimuthal equidistant projection).

## Delivered Capabilities
- **Survey Map Projection (`SurveyMapProjection`)**: Polar azimuthal coordinate transformations between world space, normalized disk coordinates, and map pixels. Provides heading calculations, cardinal orientation formatting, zoom level definitions, and real-time disk traversal classification (Habitable Basin, Outer Tundra, Ice Wall Rim, Abyss Void, Underside).
- **Cartographic Raster Generation (`SurveyMapRaster`)**: Generates an authoritative 256x256 survey chart image and `ImageTexture` directly from `DiskTerrainGenerator` and `TerrainBiomeCatalog`. Includes concentric survey rings (Equator, Tropic of Capricorn, Ice Wall, Disk Rim), center hub, and meridian rays with transparent abyss padding.
- **Minimap HUD (`MinimapHUD`)**:
  - Circular brass-bezel minimap anchored in HUD with compass rose (N/E/S/W).
  - Configurable zoom: Local Near (500m), Local Far (1500m), Full Disk (5000m) cycled via `Z`.
  - Configurable rotation: Heading-Up vs. North-Up toggled via `N`.
  - Local player indicator needle and telemetry readout (X/Z coordinates, altitude, heading, current biome, distance to Ice Wall).
  - Traversal and edge hazard telemetry: prominent warnings for approaching the Ice Wall, crossing into the Abyss, or traversing the underside.
  - Fullscreen chart overlay toggled via `M` displaying full disk survey chart, cartographic headers, and geodetic telemetry.
- **Multiplayer / Battle Royale Privacy Discipline**:
  - Teammate registration interface with automatic marker rendering and cleanup on disconnect.
  - Zero opponent markers rendered or queried in free-for-all mode, preventing position-leak exploits.

## Verification
- `gdformat --check .` — passed (36 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 67 tests, 4,646 assertions across 13 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed with 1 host + 5 clients, delayed intents, convergence, and teardown.
