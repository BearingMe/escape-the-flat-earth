# M11 — Advanced Movement & Ragdolls

**Phase:** Physical co-op · **Depends on:** M3, M10 · **Status:** not started

## Goal
Support physical comedy and cooperative traversal.

## Scope
- Climbing, ledge grabbing, ropes, and assisted traversal.
- Falling, stumbling, and ragdoll state transitions.
- Grab, pull, drag, or rescue other players.
- Recovery from ragdoll and temporary incapacitation.
- Physical movement response to carried equipment and local gravity.
- Multiplayer synchronization of player interaction states.

## Validation
- Players can climb and traverse intended obstacles.
- One player can help another recover from a fall or ledge.
- Ragdolls respond to collision and gravity without physics explosions.
- Entering/exiting ragdoll does not permanently break controls.
- Interaction and recovery remain synchronized for all clients.
- No persistent ownership locks after death, disconnect, or recovery.

## Arowana notes
- "Grab, pull, drag, or rescue other players" doubles as melee: rescue a teammate or yeet a rival off the edge — same verbs, opposite intents. That symmetry IS the improvised-combat design.
- Ragdoll doubles as the death cam + comedy. Recovery rules must never softlock the match: the last-one-standing fallback depends on clean death state.
- Climbing the ice wall becomes a viable (insane) escape route — keep M19 in mind when designing traversal verbs.

## References — search before building (mempalace wing `.references`, filter by room)
- `tinybox` — AGPL-3.0, architecture-only — seat/attachment state machines; clean-room transcription only.
- `physics_arsenal` — MIT, free to port — interaction rigging patterns.
