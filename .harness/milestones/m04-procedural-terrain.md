# M4 — Procedural Terrain

**Phase:** World · **Depends on:** M1, M2, M3 · **Status:** complete

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

## Implementation handoff

- **Demo:** Run `godot --path .` for the world, or run `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd` to start a host and five separate clients. The E2E gives clients a different requested seed and verifies host-config adoption, terrain fingerprint parity, movement, disconnect cleanup, and teardown.
- **Tests:** GUT covers seeded generation, different-seed variation, adjacent mesh seams/normals, disk clipping, config serialization/validation, bounded multi-region streaming/unloading, terrain collision, and adjacent chunk collision geometry. The multiplayer E2E validates late-join config/fingerprint parity across six processes.
- **Authority:** The host owns the validated `WorldConfig` and sends its primitive dictionary with every authoritative player spawn. Each peer validates that config and deterministically generates local terrain. The host streams around every player; each client streams around its local player. Terrain chunks are derived geometry, not replicated state.
- **Dependencies:** M1 disk/world config, M2 observer spawn, M3 host-authoritative movement; Godot `FastNoiseLite` and Jolt concave-mesh collision. Gravity remains 9.8 m/s² along global downward Y.
- **Performance:** Streaming refreshes at 5 Hz and creates at most two chunks per frame. The six-process E2E completed with 35 host chunks loaded; no dedicated frame-time/profile budget has been measured yet.
- **Known limitations:** Terrain is a single seeded simplex-FBM heightfield; biomes, LOD, persistence, and cross-engine-version bitwise guarantees are deferred. The finite disk/rim/underside remain fixed geometry, and terrain triangles are clipped to the disk.
- **Failure modes:** Invalid configs and spawn dictionaries are rejected; generator setup and chunk instantiation/configuration failures return errors and emit one structured log event. Empty edge chunks are skipped. Unit/integration tests cover malformed config, disk clipping, and terrain collision; multiplayer tests cover late-join synchronization and host teardown.

## Arowana notes
- The late-join-parity bullet is load-bearing for the BR: every player must race on the same world, no matter when they joined.
- Chunk streaming is what makes a 5 km disk affordable; two players exploring opposite edges at once is core BR pacing, not an edge case.
- Terrain stays inside the disc — the rim and the abyss beyond it remain the finite-world statement.

## References — search before building (mempalace wing `.references`, filter by room)
- `voxelbound` — MIT, free to port — greedy mesher, chunk streaming, delta sync.
- `simple_x_terrain` — MIT, free to port — seeded noise pipeline, heightfield→ArrayMesh compiler with LOD stepping, disc mask keeping terrain inside the rim.
