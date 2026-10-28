# Checkpoint — M17 Environmental Hazards

**Date:** 2026-10-28 · **Status:** complete

M17 delivers geography-driven environmental hazards under standard downward gravity (-9.8 m/s²), including gale-force rim wind squalls, frostbite exposure, protective equipment/shelter mitigation, and the contracting Firmament storm barrier.

## Delivered Capabilities
- **Environmental Hazard Modeling (`EnvironmentalHazardModel`)**:
  - Horizontal wind push physics: calculates displacement forces from gale-speed wind vectors (> 6.0 m/s), driving unanchored players and loose props towards perimeter edges.
  - Frostbite attrition: inflicts temperature-scaled damage in freezing zones (<= -10°C), with 80% damage mitigation when carrying thermal wraps and 100% protection inside vehicle/structure shelters.
  - Firmament storm barrier: radial contraction model calculating atmospheric discharge damage for entities outside the safe circle based on breach depth.
- **Dynamic Hazard System (`HazardSystem`)**:
  - Host-authoritative match boundary progression: contracts the active playable perimeter smoothly from the full 5000 m disk radius inward, driving match pacing.
  - Evaluates player hazard exposure on physics ticks, applying physical push impulses and metabolic attrition.
- **Player & World Integration (`ObserverPlayer`, `World`)**:
  - Evaluates local weather, underside depth, thermal gear inventory items, and shelter states.
  - Applies directional push forces directly to character velocity.

## Verification
- `gdformat --check .` — passed (85 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 148 tests, 5,033 assertions across 38 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
