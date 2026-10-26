# M12 — Expedition Survival

**Phase:** Survival economy · **Depends on:** M9, M10 · **Status:** not started

## Goal
Introduce survival pressure that encourages teamwork without burying the fun in micromanagement.

## Scope
- Health, stamina, hunger, thirst, and body temperature.
- Fall injuries, exhaustion, and environmental exposure.
- Consumable food, water, and basic medical equipment.
- Carrying weight and movement trade-offs.
- Incapacitation, revival, death, and respawn rules.
- Server-owned survival state with client UI feedback.
- Adjustable difficulty parameters for cooperative sessions.

## Validation
- Survival values progress at predictable rates.
- Temperature reacts to local weather and biome conditions.
- Injuries and carried mass have consistent gameplay effects.
- Players can revive teammates and return to gameplay.
- Death/respawn does not duplicate players or items.
- Clients cannot independently author canonical survival values.

## Arowana notes
- In the BR frame, survival stats are attrition pressure in the race — not micromanagement. Difficulty knobs are host config.
- Revival stays: reviving someone is a mercy *or* a hostage situation — both are on-brand.
- Underside expeditions get their own thermal profile (no sun down there — lore-friendly and mechanically distinct).
- "Clients cannot independently author canonical survival values" is AGENTS.md never-trust-client, verbatim.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — host-owned stat model with typed signals; keep all formulas in one data-driven place.
