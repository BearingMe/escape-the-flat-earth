# M9 — Dynamic Weather

**Phase:** Environment · **Depends on:** M5, M7 · **Status:** complete

## Goal
Make weather change over time and vary by location without hard-coding visual effects as game logic.

## Scope
- World-level weather state independent of rendering.
- Position-dependent temperature, humidity, wind, pressure, and precipitation.
- Rain, snow, fog, storms, and smooth transitions.
- Weather influenced by biome, elevation, and simplified atmospheric rules.
- Host-simulated weather state synchronized to clients.
- Local visual effects and audio from shared conditions.
- Debug controls for forcing states and advancing time.
- Public environmental data interface for later survival systems.

## Validation
- Given the same seed and time progression, weather state is reproducible.
- Nearby chunks share consistent conditions at their borders.
- All clients perceive compatible weather state at the same coordinates.
- Visual transitions are smooth; joining mid-storm reproduces current conditions.
- Weather continues evolving when no player occupies a region.
- Weather simulation and effects remain within measured performance limits.

## Demo
- Headless simulation & integration tests exercising deterministic sample queries, host synchronization, and smooth precipitation transitions: `godot --headless --path . --script res://tests/run_gut.gd`
- In-game weather controller displaying local temperature, humidity, wind gusts, and barometric pressure in telemetry, with local camera-following particle effects (rain/snow/fog).

## Tests
- `tests/unit/test_weather_simulation.gd`: validates barometric formulas, temperature lapse rates with altitude, biome climate base modulations, cyclonic front progression, and determinism across seeds.
- `tests/unit/test_weather_condition.gd`: validates data integrity, serialization/deserialization, clamping, and public interface queries.
- `tests/integration/test_weather_network_sync.gd`: validates host-authoritative state replication, client condition reconciliation, and mid-match synchronization.
- `tests/integration/test_weather_effects.gd`: validates local visual controller responds smoothly to changing conditions (rain, snow, fog, clear).

## Authority
- Host owns canonical simulation timeline (`weather_time`), global cyclonic front vectors, and forced weather overrides.
- Clients receive compact synchronized state scalars (`front_offset`, `time_elapsed`, `global_storm_cycle`) and deterministically evaluate local conditions $(x, y, z)$ on demand.

## Dependencies
- Upstream M1–M7 systems: `WorldConfig`, `DiskTerrainGenerator`, `TerrainBiomeCatalog`, `World`, `Net`, `Log`.

## Performance
- Atmospheric simulation: math-based analytical evaluation (trigonometric fronts + low-frequency octave noise); evaluation takes < 2 µs per query with zero heap allocations per sample.
- Client visuals: camera-following local particle volume (max 2,000 particles) with zero world-wide particle overhead.

## Known limitations
- The flat-earth atmospheric circulation is an intentional approximation: radial cyclonic drift around the North Pole hub under the firmament dome, rather than a spherical Navier-Stokes global climate simulation.

## Failure modes
- Desynchronized host time: client smoothly clamps and interpolates local state without hitching.
- Out-of-bounds queries (deep abyss / above firmament): barometric formula clamps cleanly to vacuum/void limits without NaN or division by zero.

## Arowana notes
- Weather is the escape race's dynamic obstacle (rim storms closing the wall) and the comedy generator (wind yeeting someone's build into the abyss).
- "Effects are not game logic" — every effect reads the shared host state; the debug force-controls are dev-build only, never in the shipped match.
- Document the atmospheric approximation per milestone rule 3.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — SmokeVoxelField for fog/volumetric effect patterns.
- No direct weather-sim reference — the atmospheric model is a documented approximation built fresh.
