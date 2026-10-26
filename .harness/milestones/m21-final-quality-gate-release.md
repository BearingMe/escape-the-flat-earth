# M21 — Final Quality Gate & Release Readiness

**Phase:** Final quality gate · **Depends on:** M1–M20 · **Status:** not started

## Goal
Consolidate the entire game into a stable, replayable cooperative experience.

## Scope
- Architecture and codebase review; remove obsolete systems and unnecessary coupling.
- Regression testing across M1–M20, including host/client state, gravity, construction, and saving.
- Profile large worlds, distant players, complex assemblies, simultaneous weather, and enemy encounters.
- Fix serious multiplayer desynchronization, memory leaks, softlocks, crashes, and save corruption.
- Playtest full expedition sessions with 2–6 players.
- Balance progression, travel times, resource availability, and escape difficulty.
- Document setup, hosting, controls, configuration, and known limitations.
- Build a distributable desktop release candidate.

## Validation
- Complete multiplayer playthrough from spawn to escape succeeds.
- Clean installation can host and join with documented steps.
- Rejoining, disconnects, saves, and loading do not corrupt game state.
- No known release-blocking crashes, duplication exploits, or progression softlocks.
- Target hardware/network conditions are measured and documented.
- Build artifacts can be reproduced from a clean checkout.
- Known non-blocking issues and deferred features are explicitly recorded.

## Arowana notes
- AGENTS.md DoD applies per-milestone; M21 makes it apply to the whole game — full playthroughs verified with host + client peers, never netcode merged blind from single-instance tests.
- Balance pass targets the escape-race pacing: travel times, junk availability, escape difficulty. The race must be winnable by cleverness, not just grind.
- Known-limitations honesty is part of the bit: document the approximations, ship the jank that works.

## References — search before building (mempalace wing `.references`, filter by room)
- Process milestone — regression across all rooms; rerun both quality gates' checklists and the full GUT suite.
