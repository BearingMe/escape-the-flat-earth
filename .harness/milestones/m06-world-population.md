# M6 — World Population

**Phase:** World · **Depends on:** M4, M5 · **Status:** complete

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
- [x] Same seed and location yield the same static prop layout and stable prop IDs; different seeds diverge.
- [x] Surface snapping, slope limits, disk/spawn clearance, and spacing checks reject invalid placements; adjacent chunks do not duplicate lattice cells.
- [x] Static scenery has no physics collision and a broad spawn clearing, so props do not block traversal.
- [x] Chunk streaming owns both visuals and host records; integration verifies unload and active-registry counts stay bounded.
- [x] Host/client E2E matches sampled population fingerprints and counts; only the host owns lifecycle records.
- [x] All five biomes have authored population pools and remain reachable through M5's deterministic biome distribution.

## Arowana notes
- Sandbox-first: every prop placed here is a future throwable (M10 feeds on this milestone). Props that *look* grabbable should be planned as grabbable — otherwise players will feel lied to.
- The host-authoritative prop lifecycle bullet is what makes the M10 interactable migration cheap later — honor it now.
- "Collision only where gameplay requires it" also keeps the junk physics budget sane.

## Implementation handoff

- **Generation:** `TerrainPopulationGenerator` evaluates a seed-hashed 16 m world lattice, samples the dominant M5 biome, then applies that profile's authored tree/shrub/rock/debris/ice density. Candidate ownership is determined by the candidate's world position, so adjacent chunks cannot duplicate a prop and generation order does not matter.
- **Placement:** Terrain height is sampled at each root; a four-point height probe determines its surface normal. Per-kind slope limits, randomized scale/yaw, disk-edge clearance, minimum spacing, and a 42 m central spawn/traversal clearing bound placement.
- **Rendering/streaming:** `TerrainChunk` owns the `TerrainPopulationView`; terrain chunk unload frees all associated batches. Low-poly geometry/materials are shared, instances are grouped into `MultiMeshInstance3D` batches, non-shadow-casting scenery is distance-culled at 450 m, and forest trees switch from detailed trunk/canopy to a far silhouette around 145–185 m. Existing terrain chunk creation remains capped at two per frame.
- **Authority:** Deterministic stable IDs encode world seed and lattice coordinates. The host alone registers streamed prop IDs and metadata in `World`; chunk unload unregisters still-static props. Clients derive the same immutable visuals from the synchronized seed/config and do not own a lifecycle registry. When M10 makes a prop movable/removable, transition it to a host-owned replicated entity; do not mutate the local MultiMesh or trust a client claim.
- **Collision:** These first-pass scenery meshes are intentionally non-colliding and non-interactive. Terrain remains the movement collider; scenery therefore cannot block traversal or consume per-prop physics bodies. M10's gameplay objects must add only the collision their interaction needs.
- **Tests:** Unit coverage checks same-seed layouts/IDs, different-seed divergence, chunk-border ownership, surface height/slope/edge/spawn rules, non-overlapping footprints, profile pools, and validation. Integration checks batched views follow chunk streaming and the host registry follows active chunks. Six-process multiplayer E2E compares prop fingerprints/counts across host and clients and verifies only the host owns lifecycle records.
- **Known limitations:** Visuals are low-poly primitive placeholders; forest trees are conifer silhouettes. Biome profiles use one dominant biome per placement, so transitions can change prop pool at the dominant-ID boundary even though terrain colors/elevation blend. No dedicated frame-time or memory benchmark has been recorded.
- **Failure modes:** Invalid biome densities (including totals above 1) fail catalog validation. Invalid placements are skipped; host registry errors report once and prevent that chunk from being accepted. No runtime prop mutations are exposed in M6.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — chunk-streamed population patterns.
- `open_acre` — GPL-3.0, architecture-only (clean-room) — GridManager scatter/placement patterns.
