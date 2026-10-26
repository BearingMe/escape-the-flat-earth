# M6 — World Population

**Phase:** World · **Depends on:** M4, M5 · **Status:** not started

## Goal
Add environmental objects and make the five biomes feel explorable.

## Scope
- Biome-specific trees, shrubs, rocks, debris, ice formations, and other props.
- Deterministic placement using world seed and local biome data.
- Terrain-aware placement, scale, orientation, and clearance rules.
- Instancing, culling, and distance-based detail appropriate for large landscapes.
- Collision only where gameplay requires it.
- Stream prop populations with terrain chunks.
- Host-authoritative lifecycle for props that may later become interactable.

## Validation
- Same seed and location yield the same static prop layout.
- No widespread floating, buried, or overlapping props.
- Props do not unintentionally obstruct required traversal routes.
- Distant players can explore different chunks without excessive memory growth.
- Static prop appearance is consistent between host and clients.
- All five biomes can be visited in a single exploratory session.

## Arowana notes
- Sandbox-first: every prop placed here is a future throwable (M10 feeds on this milestone). Props that *look* grabbable should be planned as grabbable — otherwise players will feel lied to.
- The host-authoritative prop lifecycle bullet is what makes the M10 interactable migration cheap later — honor it now.
- "Collision only where gameplay requires it" also keeps the junk physics budget sane.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — chunk-streamed population patterns.
- `open_acre` — GPL-3.0, architecture-only (clean-room) — GridManager scatter/placement patterns.
