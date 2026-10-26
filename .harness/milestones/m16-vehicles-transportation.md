# M16 — Vehicles & Transportation

**Phase:** Engineering · **Depends on:** M14, M15 · **Status:** not started

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

## Arowana notes
- Vehicles are escape machines first, weapons second — ramming is legal and encouraged.
- "Passengers do not desynchronize or fall through" is the classic multiplayer-vehicle trap; the vault's synchronizer patterns exist precisely for this.
- Detached parts stay host-authoritative — a thrown wheel is just M10 junk with extra steps.

## References — search before building (mempalace wing `.references`, filter by room)
- `modu_vehicle` — CC0, free to port — raycast suspension + drivetrain; the direct port target.
- `tinybox` — AGPL-3.0, architecture-only — MotorSeat/passenger seating concept; clean-room transcription only.
