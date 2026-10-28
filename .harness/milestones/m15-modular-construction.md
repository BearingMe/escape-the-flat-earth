# M15 — Modular Construction

**Phase:** Engineering · **Depends on:** M10, M14 · **Status:** complete

## Goal
Let players assemble physical structures and absurd contraptions out of parts.

## Scope
- Placeable structural components and attachment rules.
- Connectors, hinges, rigid joints, and detachable links.
- Build, move, rotate, attach, dismantle, and repair components.
- Structural load and joint failure using a documented approximation.
- Shared cooperative construction with host-authoritative assemblies.
- Construction blueprints or save/load for builds.
- Practical safeguards for unreasonable object counts and unstable assemblies.

## Validation
- Players can collaboratively create and modify the same assembly.
- Connectors and joints hold under expected loads and break past tolerances.
- Builds remain stable under global-down gravity on the upper surface; gravity does not hold them to the vertical rim or underside.
- Concurrent edits do not duplicate parts or corrupt the assembly graph.
- Saved builds recreate their expected components and joint relationships.
- Invalid/unstable builds fail gracefully instead of crashing the session.

## Demo
- Assemble structures and ramps in-game: snap beams, ramps, and platforms together via sockets, dismantle components to recover salvage, and apply excessive physical force to stress-test joint failure.
- Automated tests verifying socket snapping, joint load calculations, stress breakage, blueprint save/restore, and part limit safeguards: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_construction_part_definition.gd`: validates component dimensions, mass, snap socket anchors, and breaking force limits.
- `tests/unit/test_structural_load_model.gd`: validates documented cantilever/load approximation: cumulative child mass + acceleration vs joint tensile/shear strength.
- `tests/integration/test_modular_assembly.gd`: validates cooperative construction, host-authoritative placement, joint creation, physical demolition breakage, blueprint serialization, and maximum part safeguards.

## Authority
- Host maintains authoritative ownership over assembly hierarchies, joint attachments, load calculations, and structural collapse.
- Clients send placement, rotation, attach, and dismantle intents via RPC (`submit_place_part_intent`, `submit_dismantle_intent`).

## Dependencies
- Upstream M10 Physics Interactions (mass, momentum, standard downward gravity), M14 Crafting (building materials).

## Performance
- Joint load evaluation: linear tree pass on physics tick; O(N) where N <= 50 parts per assembly (< 15 µs).
- Maximum assembly cap (50 parts per assembly, 200 world construction pieces) guarantees simulation stability under Jolt physics.

## Known limitations
- Finite element method (FEM) continuous beam elasticity is not simulated; a documented discrete joint load approximation calculates shear/tensile breaking thresholds.

## Failure modes
- Over-budget construction attempt: host rejects placement with error code when assembly part cap is reached.
- Structural collapse: when a root joint snaps, detached subtree forms a separate dynamic rigid body or dismantles into loose salvage.

## Arowana notes
- Builds are escape contraptions AND player-made obstacles — walls across chokepoints, ramps up the ice wall, bridges over... nothing.
- Joint failure is demolition-as-combat: breaking a rival's ramp mid-climb is a legitimate strategy.
- The "unreasonable object counts / unstable assemblies" safeguards are load-bearing — jank is a feature; breakage is not.

## References — search before building (mempalace wing `.references`, filter by room)
- `tinybox` — AGPL-3.0, architecture-only — contraption joints + MotorSeat patterns; clean-room transcription only.
- `open_acre` — GPL-3.0, architecture-only — HitchSocket3D attach-point concept; clean-room transcription only.
