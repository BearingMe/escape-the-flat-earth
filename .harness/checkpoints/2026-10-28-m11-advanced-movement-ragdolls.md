# Checkpoint — M11 Advanced Movement & Ragdolls

**Date:** 2026-10-28 · **Status:** complete

M11 delivers cooperative traversal and improvised melee combat through wall/obstacle climbing, falling/stumbling ragdoll knockdown states, player recovery, and player-on-player grab and throw interactions under standard downward gravity (-9.8 m/s²).

## Delivered Capabilities
- **Player Traversal State Machine (`PlayerTraversalState`)**:
  - Four distinct authority-governed movement states: `NORMAL`, `CLIMBING`, `RAGDOLL`, `CARRIED`.
  - Surface normal validation for vertical walls and ice wall climbing.
  - Knockdown threshold evaluation (damage >= 20.0 or fall speed >= 18.0 m/s triggers ragdoll knockdown).
- **Wall Climbing & Obstacle Traversal (`ObserverPlayer`)**:
  - Vertical wall detection via forward raycast during mid-air jump.
  - Steady upward climb velocity (3.5 m/s) with a 6.0-second stamina limit.
  - Automatic dismount and return to normal movement on reaching flat ground or when stamina depletes.
- **Physical Ragdoll & Knockdown**:
  - Complete control disabling during ragdoll while tumbling under -9.8 m/s² downward gravity and ground friction.
  - Timed recovery mechanic requiring 1.5 seconds of settle time on the floor before recovery can be initiated via `Space`.
  - Permanent ragdoll corpse state on death, preventing ghost recovery.
- **Player-on-Player Grab, Carry, and Yeet**:
  - Symmetric interaction design: grabbing another player doubles as rescue/carry for allies and improvised projectile melee for enemies.
  - Carried players enter `CARRIED` state, tethered to the carrier's forward anchor.
  - Carrying a 75 kg human applies a heavy payload movement speed penalty (sprint disabled, walk speed capped at 60%).
  - Throwing a carried player calculates launch velocity via `ImpactDamageModel` (55.0 impulse), hurling the victim into an arcing ragdoll trajectory across the ice or off the disk rim into the abyss.
  - Network-safe disconnect and death cleanup: carried players immediately detach and resume free tumbling if the carrier dies or disconnects.

## Verification
- `gdformat --check .` — passed (52 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 97 tests, 4,786 assertions across 22 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
