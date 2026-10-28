# M11 — Advanced Movement & Ragdolls

**Phase:** Physical co-op · **Depends on:** M3, M10 · **Status:** complete

## Goal
Support physical comedy and cooperative traversal.

## Scope
- Climbing, ledge grabbing, ropes, and assisted traversal.
- Falling, stumbling, and ragdoll state transitions.
- Grab, pull, drag, or rescue other players.
- Recovery from ragdoll and temporary incapacitation.
- Physical movement response to carried equipment under standard global-down gravity.
- Multiplayer synchronization of player interaction states.

## Validation
- Players can climb and traverse intended obstacles.
- One player can help another recover from a fall or ledge.
- Ragdolls respond to collision and 9.8 m/s² global-down gravity without physics explosions.
- Entering/exiting ragdoll does not permanently break controls.
- Interaction and recovery remain synchronized for all clients.
- No persistent ownership locks after death, disconnect, or recovery.

## Demo
- Vertical wall climbing and ledge traversal: approach steep wall or obstacle, press `W` + `Space` to initiate climb.
- Ragdoll incapacitation, recovery, and player-tossing: take a heavy physics hit to tumble into ragdoll, recover with `Space` once settled, or have another player grab (`E`) and hurl (`F`) you across the terrain.
- Automated tests verifying ledge climbing, ragdoll tumbling, player-grabbing symmetry, and recovery timers: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_player_traversal_state.gd`: validates state machine transitions (`NORMAL`, `CLIMBING`, `RAGDOLL`, `CARRIED`), climb speed limits, and recovery eligibility.
- `tests/integration/test_player_climbing.gd`: validates wall/obstacle detection, upward vertical velocity under standard gravity, stamina/climb bounds, and dismount.
- `tests/integration/test_player_ragdoll_toss.gd`: validates knockdown from impact damage, tumbling under -9.8 m/s² gravity, player-on-player grab and yeet mechanics, and clean recovery upon ground settle.

## Authority
- Host owns canonical player state machine, knockdown/ragdoll eligibility, grab attachments between players, and throw impulse math.
- Clients send climb intents, recover requests, and player grab/throw intents.
- State (`movement_state`, `is_knocked_down`, `carrier_peer_id`) replicates reliably to all peers.

## Dependencies
- Upstream M1–M10 systems: `ObserverPlayer`, `ImpactDamageModel`, `PhysicalProp`, standard downward gravity.

## Performance
- Climbing raycasts: single forward wall raycast when jumping near geometry (< 5 µs per frame).
- Ragdoll simulation: simplified capsule tumbling on host without multi-bone skeleton overhead in headless tests.

## Known limitations
- Full skeletal joint ragdolls are visual cosmetics in graphical clients; simulation authority models physical tumbling via dynamic physics collision capsules.

## Failure modes
- Knockdown while already carried: drops from carrier immediately and tumbles freely.
- Carrier disconnects while carrying player: carried player immediately transitions back to free simulation without stuck coordinates.
- Infinite climbing exploits: climbing checks surface normal angle and maximum vertical climb limits.

## Arowana notes
- "Grab, pull, drag, or rescue other players" doubles as melee: rescue a teammate or yeet a rival off the edge — same verbs, opposite intents. That symmetry IS the improvised-combat design.
- Ragdoll doubles as the death cam + comedy. Recovery rules must never softlock the match: the last-one-standing fallback depends on clean death state.
- Climbing the ice wall becomes a viable (insane) escape route — keep M19 in mind when designing traversal verbs.

## References — search before building (mempalace wing `.references`, filter by room)
- `tinybox` — AGPL-3.0, architecture-only — seat/attachment state machines; clean-room transcription only.
- `physics_arsenal` — MIT, free to port — interaction rigging patterns.
