# Checkpoint — M9 Dynamic Weather

**Date:** 2026-10-28 · **Status:** complete

M9 implements dynamic, position-dependent atmospheric weather across the finite disk, simulated authoritatively on the host, synchronized to clients via compact scalar state, and driving local visual effects (rain, snow, fog, storms, blizzards) smoothly.

## Delivered Capabilities
- **Weather Condition Data Structure (`WeatherCondition`)**: Represents local environmental conditions: temperature (°C), humidity (0–1), 3D wind velocity vector (m/s), barometric pressure (kPa), precipitation type (Clear, Rain, Snow, Storm, Blizzard, Fog), precipitation intensity, fog density, and visibility ratio.
- **Atmospheric Simulation (`WeatherSimulation`)**:
  - Implements standard barometric pressure equation $P = 101.325 \times \exp(-h / 8400) \, \text{kPa}$ and elevation lapse rate (-0.0065 °C/m).
  - Biome-specific baseline climatology: sub-zero temperatures and high gale winds at the Ice Wall and Tundra; humid moderate climates in Plains and Forest; lower pressure and wind in Mountains.
  - Synoptic cyclonic front propagation: rotating wind circulation around the North Pole hub towards the outer perimeter under the firmament dome, generating dynamic storms, rain, snow, and blizzards.
  - Full determinism across seeds and simulation timelines.
  - Debug controls: `force_weather(type, intensity)`, `clear_override()`, `advance_time(delta)`.
- **Host-Authoritative Network Synchronization (`World`)**:
  - Host updates `weather_sim` on physics ticks and periodically replicates compact state (`sim_time_sec`, active overrides) to clients via `@rpc("authority", "call_remote", "unreliable")`.
  - Clients deterministically evaluate local conditions $(x, y, z)$ on demand with zero world-wide packet overhead.
  - Public interface `World.get_weather_at(world_pos)` available for survival and hazard systems.
- **Visual Weather Controller (`WeatherController`)**:
  - Headless-safe CPU-based camera-following particle volumes for rain and snow with dynamic wind tilt, velocity, and emission rates.
  - Smooth interpolation of visual intensities (`TRANSITION_SPEED = 1.5`) across chunk boundaries and front changes, eliminating visual pop.

## Verification
- `gdformat --check .` — passed (42 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 79 tests, 4,698 assertions across 16 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
