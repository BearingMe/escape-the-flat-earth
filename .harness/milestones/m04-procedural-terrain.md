# M4 — Procedural Terrain

**Phase:** World · **Depends on:** M1, M2, M3 · **Status:** not started

## Goal
Replace the smooth disk's top surface with deterministic, streamable terrain without losing its finite shape.

## Scope
- Seeded terrain generation with configurable noise and elevation bounds.
- Chunked terrain mesh generation and terrain collision.
- Chunk streaming and unloading based on player proximity.
- Seamless chunk borders and stable world-space coordinates.
- Preserve disk rim and underside as finite, navigable geometry.
- Make world generation authoritative and deterministic across host and clients.
- Support simultaneous exploration in distant areas by different players.

## Validation
- Same seed/configuration yields the same terrain; different seeds differ.
- Adjacent chunks have no cracks or collision seams.
- Terrain does not extend beyond the configured disk.
- Players in separate regions receive the correct chunks without forcing all chunks to stay loaded.
- Joining late produces the same world geometry as the host.
- Chunk creation, removal, and collision updates avoid major traversal stalls.

## Arowana notes
- The late-join-parity bullet is load-bearing for the BR: every player must race on the same world, no matter when they joined.
- Chunk streaming is what makes a 5 km disk affordable; two players exploring opposite edges at once is core BR pacing, not an edge case.
- Terrain stays inside the disc — the rim and the abyss beyond it remain the finite-world statement.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — greedy mesher, chunk streaming, delta sync.
- `simple_x_terrain` — MIT, free to port — seeded noise pipeline, heightfield→ArrayMesh compiler with LOD stepping, disc mask keeping terrain inside the rim.
