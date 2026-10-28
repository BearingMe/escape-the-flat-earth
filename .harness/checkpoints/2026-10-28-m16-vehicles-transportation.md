# Checkpoint — M16 Vehicles & Transportation

**Date:** 2026-10-28 · **Status:** complete

M16 delivers ground vehicles and expedition transportation built on modular raycast suspension, lateral tire friction, multi-passenger seating, fuel consumption, and high-speed ramming physics under standard downward gravity (-9.8 m/s²).

## Delivered Capabilities
- **Vehicle Kinematics Model (`VehicleKinematics`)**:
  - Implements spring-damper suspension forces ($F_{susp} = k \times \Delta x - d \times v_{comp}$) adapted from `modu_vehicle`.
  - Directional drive force integration scaled with throttle input and available fuel.
  - Lateral tire friction opposing sideways drift to guarantee responsive steering on terrain while preserving slide dynamics on ice.
  - Fuel consumption model burning fuel proportional to throttle demand.
- **Physical Vehicle Entity (`VehicleEntity`)**:
  - `RigidBody3D` 4-wheel chassis with independent raycast suspension (`vehicle_entity.tscn`).
  - Multi-passenger seating architecture supporting a driver seat and passenger seat.
  - Prevents multiplayer desynchronization and clipping by anchoring seated players to interior seat anchors while matching vehicle velocity.
  - High-speed ramming damage based on `ImpactDamageModel` ($mass \times velocity$).
  - Clean dismount mechanics ensuring characters dismount to safe exterior ground without getting trapped inside collision geometry.

## Verification
- `gdformat --check .` — passed (81 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 143 tests, 5,015 assertions across 36 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
