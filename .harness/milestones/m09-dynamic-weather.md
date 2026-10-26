# M9 — Dynamic Weather

**Phase:** Environment · **Depends on:** M5, M7 · **Status:** not started

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

## Arowana notes
- Weather is the escape race's dynamic obstacle (rim storms closing the wall) and the comedy generator (wind yeeting someone's build into the abyss).
- "Effects are not game logic" — every effect reads the shared host state; the debug force-controls are dev-build only, never in the shipped match.
- Document the atmospheric approximation per milestone rule 3.

## References — search before building (mempalace wing `.references`, filter by room)
- `vantix` — Apache-2.0, free to port — SmokeVoxelField for fog/volumetric effect patterns.
- No direct weather-sim reference — the atmospheric model is a documented approximation built fresh.
