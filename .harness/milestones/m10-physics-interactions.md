# M10 — Physics Interactions

**Phase:** Physical co-op · **Depends on:** M3, M7 · **Status:** not started

## Goal
Make handling everyday objects enjoyable and chaotic in co-op.

## Scope
- Physical pickups with mass, momentum, friction, collision, and local gravity.
- Grab, carry, push, pull, drag, and throw.
- One-handed and two-handed interactions where useful.
- Two players can manipulate the same object.
- Host authority over shared object state, ownership handoff, and release behavior.
- Interaction feedback and clear reach/weight limits.
- Network-safe cleanup when players disconnect while holding objects.

## Validation
- Objects fall, slide, and roll correctly at center, rim, and underside.
- Heavier objects are harder to move and retain momentum as expected.
- Two players can carry/manipulate the same object without duplicates.
- Rapid grabs/releases do not create competing owners or unstable joints.
- Disconnecting an object holder does not leave an object frozen or attached.
- Shared interactions remain usable under simulated latency.

## Arowana notes
- **This is the combat milestone.** Improvised-only damage model per the import decision: damage = momentum × mass, computed by the host. Grab, carry, throw, drag, and drop are the entire arsenal — nothing else ships.
- Two players manipulating one object is a core BR beat: tug-of-war over the good junk is a fight, legally.
- Reach/weight limits create the junk meta: heavy = slow but devastating. The host does all the damage math — clients throw intents, never verdicts.

## References — search before building (mempalace wing `.references`, filter by room)
- `physics_arsenal` — MIT, free to port — PlayerInteraction grab/throw is the direct port target.
- `tinybox` — AGPL-3.0, architecture-only — joint/constraint patterns; clean-room transcription only, never copy-paste.
