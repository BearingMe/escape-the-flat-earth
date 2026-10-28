# M12 — Expedition Survival

**Phase:** Survival economy · **Depends on:** M9, M10 · **Status:** complete

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

## Demo
- HUD survival telemetry: real-time health, stamina, hunger, thirst, and body temperature meters.
- Environmental exposure: travel to the Ice Wall or Underside to observe hypothermia onset; consume food/water/medkits to recover.
- Incapacitation & Revival: taking lethal damage enters down-but-not-out bleedout; allies (or opportunistic rivals) can interact to revive the downed player.
- Automated test suite: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_survival_simulation.gd`: validates metabolic depletion rates, thermal equilibration against local weather, hypothermia/heatstroke thresholds, and difficulty multipliers.
- `tests/unit/test_consumable_definition.gd`: validates item data tables, nutritional/hydration values, and healing limits.
- `tests/integration/test_player_survival_lifecycle.gd`: validates host-authoritative survival state ticks, incapacitation bleedout, revival interaction, and consumable item application.

## Authority
- Host strictly owns all survival values (health, stamina, hunger, thirst, core temperature, bleedout timer).
- Clients send consumable consumption and revival intents via RPC; clients render HUD state from replicated values.

## Dependencies
- Upstream M9 Dynamic Weather (`World.get_weather_at`), M10 Impact Damage, M11 Player Traversal States.

## Performance
- Survival ticks execute at low frequency (2 Hz / 0.5s intervals) or smoothed per-frame; sub-microsecond math per player.

## Known limitations
- Complex nutritional disease/vitamin models are omitted; focus is on clean survival attrition driving BR escape pacing.

## Failure modes
- Client spoofed heal/nourish intents: validated and rejected by host authority.
- Interrupted revival: resets revival progress without locking either player.
- Disconnecting downed player: clean despawn without orphaned revival locks.

## Arowana notes
- In the BR frame, survival stats are attrition pressure in the race — not micromanagement. Difficulty knobs are host config.
- Revival stays: reviving someone is a mercy *or* a hostage situation — both are on-brand.
- Underside expeditions get their own thermal profile (no sun down there — lore-friendly and mechanically distinct).
- "Clients cannot independently author canonical survival values" is AGENTS.md never-trust-client, verbatim.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — host-owned stat model with typed signals; keep all formulas in one data-driven place.
