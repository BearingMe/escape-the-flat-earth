# M15 — Modular Construction

**Phase:** Engineering · **Depends on:** M10, M14 · **Status:** not started

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

## Arowana notes
- Builds are escape contraptions AND player-made obstacles — walls across chokepoints, ramps up the ice wall, bridges over... nothing.
- Joint failure is demolition-as-combat: breaking a rival's ramp mid-climb is a legitimate strategy.
- The "unreasonable object counts / unstable assemblies" safeguards are load-bearing — jank is a feature; breakage is not.

## References — search before building (mempalace wing `.references`, filter by room)
- `tinybox` — AGPL-3.0, architecture-only — contraption joints + MotorSeat patterns; clean-room transcription only.
- `open_acre` — GPL-3.0, architecture-only — HitchSocket3D attach-point concept; clean-room transcription only.
