# Checkpoint — M19 Escape Mechanics

**Date:** 2026-10-28 · **Status:** complete

M19 establishes the core win condition and endgame loop of *Arowana: Escape the Flat Earth*, detecting continuous physics-based perimeter breach beyond the 5,000 m disk radius into free-fall, supporting multiple distinct traversal routes (endurance climb, foot vault, vehicular ramp launch), and providing the last-one-standing battle royale fallback.

## Delivered Capabilities
- **Continuous Perimeter Boundary Detection (`EscapeTracker`)**:
  - Boundary breach math ($x^2 + z^2 > (R + 2.0)^2$) without custom artificial gravity fields, teleporters, or fragile trigger volumes.
  - Detects authentic departure off the edge of the world under standard global-down gravity (-9.8 m/s²).
- **Multiple Supported Escape Routes**:
  - *Foot Vault & Endurance Climb*: scaling the 250 m Ice Wall on foot with grapple and thermal insulation, vaulting over the crest into free-fall.
  - *Vehicular Ramp Launch*: launching a reconnaissance vehicle or contraption sled at terminal speed off an engineered scaffold ramp over the rim.
- **Match Conclusion & Win Condition Evaluation (`World`)**:
  - Canonical zero-sum outcome: the first player off the disc ends the match as victor (`ESCAPE`).
  - Fallback victory: if all rivals succumb to combat or environmental hazards, the last living survivor wins (`LAST_ONE_STANDING`).
  - Broadcasts authoritative match conclusion events to all connected peers via reliable RPC.

## Verification
- `gdformat --check .` — passed (94 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 165 tests, 5,090 assertions across 43 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
