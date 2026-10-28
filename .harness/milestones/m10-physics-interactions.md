# M10 — Physics Interactions

**Phase:** Physical co-op · **Depends on:** M3, M7 · **Status:** complete

## Goal
Make handling everyday objects enjoyable and chaotic in co-op.

## Scope
- Physical pickups with mass, momentum, friction, collision, and standard global-down gravity.
- Grab, carry, push, pull, drag, and throw.
- One-handed and two-handed interactions where useful.
- Two players can manipulate the same object.
- Host authority over shared object state, ownership handoff, and release behavior.
- Interaction feedback and clear reach/weight limits.
- Network-safe cleanup when players disconnect while holding objects.

## Validation
- Objects fall, slide, and roll correctly on the upper surface and fall downward when leaving the disk; the rim and underside do not attract them.
- Heavier objects are harder to move and retain momentum as expected.
- Two players can carry/manipulate the same object without duplicates.
- Rapid grabs/releases do not create competing owners or unstable joints.
- Disconnecting an object holder does not leave an object frozen or attached.
- Shared interactions remain usable under simulated latency.

## Demo
- Interactive grab, carry, push/pull, and throw: approach any physical prop, press `E` or Left-Click to grab, scroll mouse wheel to adjust distance, Left-Click / `F` to throw with momentum.
- Automated tests verifying multi-player tug-of-war, mass inertia, impact damage calculations, and disconnect cleanup: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_physics_prop_definition.gd`: validates prop data tables, mass/reach limits, and impulse calculations.
- `tests/unit/test_impact_damage.gd`: validates host-authoritative momentum-based damage formula: $Damage = \text{clamp}(mass \times velocity \times factor, 0, max)$.
- `tests/integration/test_physics_grab_throw.gd`: validates host-authoritative grab joint/force, carrying, distance adjustment, throwing, multi-player cooperative carry/tug-of-war, and clean disconnect detachment.

## Authority
- Host owns all physical `RigidBody3D` simulations, joint/spring attachments, carrier lists, and impact damage evaluations.
- Clients send grab, adjust-distance, and throw intents via RPC (`submit_grab_intent`, `submit_throw_intent`).
- Object positions and velocities synchronize to clients via `MultiplayerSynchronizer` or state replication.

## Dependencies
- Upstream M1–M7 systems: `ObserverPlayer`, Jolt Physics 3D, standard downward gravity (-9.8 m/s²), `World`, `Net`.

## Performance
- Physics queries: short sphere-casts / raycasts on intent only (< 10 µs per grab attempt).
- Active physics bodies: sleep when settled, awake when grabbed or impacted; minimal CPU budget per tick.

## Known limitations
- Pure ragdoll characters are introduced in M11; M10 focuses on physical props, environmental junk, and improvised momentum impact damage.

## Failure modes
- Client grabs out-of-reach object: rejected by host authority.
- Player disconnects while holding prop: holder registration is evicted immediately and the prop returns to free simulation under gravity.
- Simultaneous grab attempts: host arbitrates multiple holders cooperatively or applies combined/contested forces without joint explosion.

## Arowana notes
- **This is the combat milestone.** Improvised-only damage model per the import decision: damage = momentum × mass, computed by the host. Grab, carry, throw, drag, and drop are the entire arsenal — nothing else ships.
- Two players manipulating one object is a core BR beat: tug-of-war over the good junk is a fight, legally.
- Reach/weight limits create the junk meta: heavy = slow but devastating. The host does all the damage math — clients throw intents, never verdicts.

## References — search before building (mempalace wing `.references`, filter by room)
- `physics_arsenal` — MIT, free to port — PlayerInteraction grab/throw is the direct port target.
- `tinybox` — AGPL-3.0, architecture-only — joint/constraint patterns; clean-room transcription only, never copy-paste.
