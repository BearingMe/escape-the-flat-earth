# M7 — Quality Gate & Refactoring

**Phase:** Quality gate · **Depends on:** M1–M6 · **Status:** complete

## Goal
Stabilize the complete world foundation before adding gameplay systems.

## Scope
- Audit boundaries between gravity, networking, generation, terrain, rendering, and controls.
- Remove unnecessary coupling, dead code, temporary workarounds, and duplicated logic.
- Review seed handling, authority rules, entity identifiers, and lifecycle cleanup.
- Add focused tests for the configured 9.8 m/s² global-down gravity, deterministic generation, and multiplayer joining; no finite-disk gravity math is in scope.
- Profile terrain generation, chunk streaming, rendering, physics, CPU, GPU, and memory.
- Fix critical defects and optimize only measured bottlenecks.
- Document architecture, world generation, gravity assumptions, and operational setup.

## Validation
- All acceptance checks from M1–M6 still pass.
- Clean checkout, documented setup, build, and multiplayer launch succeed.
- Full-disk traversal and two-player distant exploration work without crashes.
- No known critical collision, standard-gravity, authority, or world-generation defects.
- No unexplained persistent memory growth or major frame-time spikes in measured test routes.
- Architecture documentation matches the actual code.

## Demo
- Two-player distant exploration E2E: `godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd -- --e2e-distant-exploration`
- World generation and streaming profiler: `godot --headless --path . --scene res://tests/scenes/world_profile.tscn`

## Tests
- `tests/integration/test_terrain_streamer.gd`: verified 78-chunk traversal across full 10,000 m disk diameter keeps active loaded chunk count and static prop registry strictly bounded to the active window with zero leaks.
- `tests/e2e/run_multiplayer_smoke.gd`: automated separate-process host + client distant region streaming at x=2048m, verifying chunk loading, prop count, and clean disconnect/teardown.
- `tests/scenes/world_profile.tscn`: automated profiling for mesh generation, collision shape creation, population generation, streaming load budgets across multiple frames, memory baseline/peak/after-cleanup, and runtime monitor counters.

## Authority
- Host maintains authoritative ownership over session configuration, world seeds, kinematic CharacterBody3D simulation, and static prop identities in `World`.
- Clients independently derive matching terrain heightmaps and visual prop batches (`MultiMeshInstance3D`) from synchronized world configuration without client-side registry mutation.

## Dependencies
- Godot 4.7.x, Jolt Physics 3D, ENet MultiplayerPeer.
- Upstream systems from M1–M6: `WorldConfig`, `DiskTerrainGenerator`, `TerrainPopulationGenerator`, `TerrainStreamer`, `ObserverPlayer`, and `Log`.

## Performance
- Chunk creation: ~11–14 ms mesh generation, ~200–330 µs collision creation, ~1.9–4.0 ms population generation (~13–18 ms total per 128 m chunk).
- Two-player distant exploration: 50 total chunks streamed over 24 frames (~740 ms total load) with mean frame time ~1.3–1.5 ms and max frame time bounded at ~32 ms.
- Memory: baseline ~61.25 MB static memory; 50 loaded chunks peak at ~72.84 MB (~232 KB per chunk); after unload/cleanup memory returns to ~62.76 MB with 0 B persistent leak across repeated load/unload cycles.
- Forward+ Renderer (live RX 7700 XT): 146 FPS, 261 draw calls, 7,869 primitives, 252 MB video memory.

## Known limitations
- Props remain non-colliding visual batches (`MultiMeshInstance3D`) until M10 physics interactions.
- Headless runs report 0 for GPU rendering monitors (`render/total_draw_calls_in_frame`, `render/video_mem_used`); full GPU metrics require visible editor/game runs.

## Failure modes
- Desynchronized client config: rejected at spawn (`Log.error("network.invalid_world_config_spawn")`).
- Excessive streaming frame spikes: mitigated by the 2-chunk creation budget per frame.
- Unregistered props on unload: verified clean eviction with `World.unregister_static_prop_chunk()`.

## Out of scope
- New gameplay features.

## Arowana notes
- This is also the "jank is a feature; breakage is not" enforcement point — cut anything that threatens the core loop (spawn → loot → build → fight → escape). Slop survives; breakage does not.
- Profile for BR pacing: two players exploring distant regions simultaneously must not tank frame time.
- DoD per AGENTS.md applies here with teeth: import + smoke boot + gdlint + GUT all clean, host + client verified.

## References — search before building (mempalace wing `.references`, filter by room)
- Process milestone — no direct repo to mine. Verify via GUT suite, gdlint, and mempalace room audits of what was already ported.
