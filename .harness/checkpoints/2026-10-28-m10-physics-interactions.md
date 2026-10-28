# Checkpoint — M10 Physics Interactions

**Date:** 2026-10-28 · **Status:** complete

M10 implements physical object manipulation and the improvised combat damage model ($Damage = \text{clamp}((Momentum - Threshold) \times Factor, 0, Max)$), supporting grabbing, carrying, pushing, pulling, throwing, cooperative multi-player lifting, tug-of-war, and disconnect/death cleanup under standard downward gravity (-9.8 m/s²).

## Delivered Capabilities
- **Physical Prop Definitions (`PhysicalPropDefinition`)**: Configurable physics props with mass (kg), grab reach, throw impulse, damage multiplier, two-handed flags, friction, and restitution (`wood_crate.tres`, `iron_anvil.tres`).
- **Host-Authoritative Improvised Combat Model (`ImpactDamageModel`)**:
  - Implements the canonical Arowana damage model where mass and momentum are the entire weapon arsenal.
  - Momentum threshold (24 kg*m/s) prevents zero-speed or gentle placement damage while allowing high-mass or thrown junk to deal devastating impact damage.
  - Calculates impulse-driven throw velocities scaled inversely with object mass (light objects fling fast, heavy anvils require short arcing tosses).
- **Physical Prop Entity (`PhysicalProp`)**:
  - `RigidBody3D` simulating under standard downward gravity without disk rim or underside attraction.
  - Multi-holder spring tethering supporting 1 or 2 players simultaneously, enabling cooperative lifting or competitive tug-of-war.
  - Distance adjustment (mouse wheel increment) to push and pull held objects along the view vector.
  - High-speed impact monitoring that applies damage to targets upon collision, crediting the thrower.
- **Observer Player Interaction (`ObserverPlayer`)**:
  - Added player health pool (default 100 HP), `apply_damage()` handling, and `player_died` signaling.
  - Raycast targeting from camera for grabbable props within reach (`E` or Left-Click).
  - Heavy prop / two-handed movement penalty: disables sprint and scales walk speed based on payload mass.
  - Network-safe lifecycle cleanup: automatic release of held props upon death or peer disconnect.

## Verification
- `gdformat --check .` — passed (48 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 90 tests, 4,752 assertions across 19 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
