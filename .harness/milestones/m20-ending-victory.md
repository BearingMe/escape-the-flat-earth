# M20 — Ending & Victory

**Phase:** Endgame · **Depends on:** M19 · **Status:** not started

## Goal
Deliver a satisfying payoff to the ridiculous scientific expedition.

## Scope
- Victory flow when escape conditions are met.
- Match-end rules (who escaped first, who was left behind, what the result means — betrayal is part of the story).
- A short reveal/ending sequence — potentially an alien/firmament revelation (lore decision to make here: AGENTS.md canon has the firmament but no aliens yet).
- Results summary that reflects player actions or engineering approach where feasible.
- Return to menu, replay, or continue sandbox play.
- Save/completion state for finished runs.

## Validation
- Victory triggers exactly once for a valid escape event.
- All connected players receive consistent completion state.
- Leaving someone behind follows documented completion rules.
- Ending sequence works with solo testing and full cooperative sessions.
- Players can safely replay or resume without corrupting previous progress.
- Completing the game from start to finish requires no developer commands.

## Arowana notes
- The escapee's reveal moment is the payoff of the entire bit: "the only way to prove the Earth is flat was to fall off it" — written 100% straight.
- The results screen is the run's story: builder, climber, traitor, last one standing.
- The alien revelation is NOT yet canon in AGENTS.md — decide it during this milestone and record it here (or adjust the AGENTS.md pillar) before implementing.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — UI + match-state flow through the autoloads (`game.gd`, `events.gd`).
