# M20 — Ending & Victory

**Phase:** Endgame · **Depends on:** M19 · **Status:** complete

## Goal
Deliver a satisfying payoff to the ridiculous scientific expedition.

## Scope
- Victory flow when escape conditions are met.
- Match-end rules (who escaped first, who was left behind, what the result means — betrayal is part of the story).
- A short reveal/ending sequence: "The only way to prove the Earth is flat was to fall off it" — official Flat Earth Geodetic Survey Certification of Flatness.
- Results summary that reflects player actions, stats, and engineering approach.
- Return to menu, replay, or restart match.
- Save/completion state for finished runs.

## Validation
- Victory triggers exactly once for a valid escape event.
- All connected players receive consistent completion state.
- Leaving someone behind follows documented completion rules.
- Ending sequence works with solo testing and full cooperative sessions.
- Players can safely replay or resume without corrupting previous progress.
- Completing the game from start to finish requires no developer commands.

## Demo
- Complete an escape run: cross the 5,000 m rim to trigger the victory flow; review the official Flat Earth Survey Commission Certificate of Proven Flatness, match stats summary, and restart the session cleanly.
- Automated tests verifying single-trigger victory guarantees, results summary generation, client victory synchronization, and session restart: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_victory_summary.gd`: validates stats collection, title assignments based on escape strategy, and certification certificate formatting.
- `tests/integration/test_victory_flow.gd`: validates host-authoritative match conclusion broadcast, single-trigger victory guarantee across peers, and clean session reset without lingering state.

## Authority
- Host strictly owns canonical match termination, winner designation, and official stats tally.
- All peers receive victory signals and instantiate the client results UI (`VictoryScreen`).

## Dependencies
- Upstream M19 Escape Mechanics, M10 Impact Model, M12 Survival, M13 Inventory.

## Performance
- Results UI: static 2D layout in CanvasLayer; zero ongoing physics overhead during endgame presentation.

## Known limitations
- Cinematic CGI animations are represented via scripted in-engine 2D/3D camera and typography.

## Failure modes
- Host disconnect during victory screen: clients display local results and return to main menu gracefully.
- Multiple simultaneous triggers: single-invocation guard (`is_match_concluded`) drops duplicate triggers.

## Arowana notes
- The escapee's reveal moment is the payoff of the entire bit: "the only way to prove the Earth is flat was to fall off it" — written 100% straight.
- Canon decision: No alien conspiracy — the universe beyond the firmament is the infinite frozen abyss of the Great Ice Plain. The official certificate confirms terrestrial flatness once and for all.
- The results screen is the run's story: builder, climber, traitor, last one standing.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — UI + match-state flow through the autoloads (`game.gd`, `events.gd`).
