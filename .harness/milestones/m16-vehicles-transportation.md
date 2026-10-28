# M16 — Vehicles & Transportation

**Phase:** Engineering · **Depends on:** M14, M15 · **Status:** complete

## Goal
Turn player-built contraptions into practical or catastrophically impractical transportation.

## Scope
- Modular wheels, steering, suspension, motors/engines, and fuel.
- Basic ground vehicles and passenger seating.
- Boats/rafts and buoyancy where water gameplay is available; otherwise introduce a simplified navigable-water surface first.
- Simple experimental traversal equipment (e.g., carts, gliders, sleds) where feasible.
- Vehicle mounting, driving, collisions, breakage, and recovery.
- Host-authoritative vehicle physics and passenger state.
- Build/repair loops using M14–M15 components.

## Validation
- Players can build, enter, drive, exit, and repair a basic vehicle.
- Multiple players can ride the same vehicle.
- Acceleration, braking, and steering respond to terrain and standard global-down gravity only.
- Engines consume configured fuel; detached parts behave consistently.
- Passengers do not desynchronize or fall through the vehicle under normal operation.
- Damaged and abandoned vehicles are safely handled through save/load.

## Demo
- Mount and drive the expedition recon sled / buggy: press `E` on the driver's seat to mount, use `W`/`S` for throttle and `A`/`D` for steering, carry a passenger in the rear seat, and ram obstacles at speed to deal momentum impact damage.
- Automated tests verifying raycast suspension, lateral tire friction, multi-passenger seating, fuel consumption, and vehicle collision impacts: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_vehicle_kinematics.gd`: validates raycast spring-damper suspension force math, steering angles, throttle force, and fuel depletion rates.
- `tests/integration/test_vehicle_driving.gd`: validates host-authoritative vehicle simulation under standard downward gravity, driver input propagation, passenger mounting/dismounting, and ramming impacts.

## Authority
- Host owns all vehicle `RigidBody3D` simulations, raycast ground forces, engine throttle, fuel levels, and passenger seating states.
- Clients send throttle, steer, brake, mount, and dismount intents via RPC (`submit_driving_input`, `submit_mount_intent`, `submit_dismount_intent`).

## Dependencies
- Upstream M10 Impact Damage Model, M11 Player Traversal, M15 Construction Assemblies, standard downward gravity (-9.8 m/s²).

## Performance
- Raycast suspension: 4 down-facing raycasts evaluated on physics ticks (< 10 µs per vehicle).
- Sleeping: vehicles sleep when stopped and unoccupied; wake when mounted or impacted.

## Known limitations
- Pure flight aerodynamics and boat hull hydrodynamics are simplified to ground/sled traversal until endgame escape mechanics in M19.

## Failure modes
- Driver disconnects while vehicle in motion: vehicle smoothly coasts and brakes to a halt under ground friction.
- Passenger desync / obstruction: dismounting validates clear exit ground before placing character.

## Arowana notes
- Vehicles are escape machines first, weapons second — ramming is legal and encouraged.
- "Passengers do not desynchronize or fall through" is the classic multiplayer-vehicle trap; the vault's synchronizer patterns exist precisely for this.
- Detached parts stay host-authoritative — a thrown wheel is just M10 junk with extra steps.

## References — search before building (mempalace wing `.references`, filter by room)
- `modu_vehicle` — CC0, free to port — raycast suspension + drivetrain; the direct port target.
- `tinybox` — AGPL-3.0, architecture-only — MotorSeat/passenger seating concept; clean-room transcription only.
