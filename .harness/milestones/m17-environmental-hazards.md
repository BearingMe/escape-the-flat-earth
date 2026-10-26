# M17 — Environmental Hazards

**Phase:** Challenges · **Depends on:** M5, M9, M15, M16 · **Status:** not started

## Goal
Make the disk's geography itself a source of increasingly absurd survival problems.

## Scope
- Hazards derived from terrain, standard global-down gravity, and weather; no radial or horizontal gravity effects.
- Falls, unstable ground, cliffs, extreme cold, strong winds, and storms.
- Dangerous rim and ice wall traversal conditions.
- Hazard mitigation through equipment, construction, and teamwork.
- Clear visual/audio cues and recoverable failure where appropriate.
- Network-consistent damage and hazard events.

## Validation
- Hazard effects follow configured physical/environmental conditions.
- Identical exposure produces predictable gameplay outcomes.
- Protective gear and engineered solutions mitigate appropriate hazards.
- Hazard collisions and damage agree across clients.
- Hazards challenge traversal without routinely creating unavoidable softlocks.
- Performance remains stable with weather and physics interactions enabled.

## Arowana notes
- Design option worth exploring: scale hazard intensity with match phase — "the firmament seals" / rim storms intensify late-match. That's the BR closing-circle mechanic wearing flat-earth clothes; decide here whether the race needs it.
- "Recoverable failure where appropriate" keeps the loop alive: a hazard should humiliate, not softlock.
- All hazard damage is host-computed — identical exposure must produce identical outcomes on every peer.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — hazards compose M5 terrain + M9 weather + host-authoritative damage per AGENTS.md.
