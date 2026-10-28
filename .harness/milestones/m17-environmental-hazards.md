# M17 — Environmental Hazards

**Phase:** Challenges · **Depends on:** M5, M9, M15, M16 · **Status:** complete

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

## Demo
- Traversal under extreme environmental hazards: venture to the Ice Wall rim during a blizzard to experience gale-force push vectors and freezing exposure; deploy construction walls or enter vehicles to block wind push; monitor Firmament storm contraction.
- Automated tests verifying wind push displacement, thermal mitigation via crafted gear, shelter shielding behind construction walls, and atmospheric barrier damage: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_environmental_hazards.gd`: validates wind push vector calculations, exposure damage curves, mitigation multipliers from thermal wraps and shelter, and closing firmament storm boundaries.
- `tests/integration/test_hazard_simulation.gd`: validates host-authoritative hazard ticks against players and vehicles, shelter detection behind construction barriers, and storm barrier damage.

## Authority
- Host owns canonical hazard calculations (wind push forces, thermal attrition, firmament storm circle position/radius, and damage events).
- Clients receive environmental state and apply visual/audio cues locally.

## Dependencies
- Upstream M5 Five Biomes, M9 Dynamic Weather, M10 Impact Damage, M12 Expedition Survival, M15 Modular Construction, M16 Vehicles.

## Performance
- Spatial shelter queries: simplified raycast / bounding box occlusion checks executed only during active storms.
- Math-based hazard evaluation: zero heap allocations during runtime ticks.

## Known limitations
- Dynamic avalanche terrain mesh deformation is deferred; collapsing snow/ice ledges are simulated via dynamic falling physical boulder/ice props.

## Failure modes
- Overwhelming storm push: clamped to terminal displacement velocities to prevent physics tunneling.
- Storm barrier desync: host authoritative health deduction ensures clients cannot bypass storm damage by faking positions.

## Arowana notes
- Design option worth exploring: scale hazard intensity with match phase — "the firmament seals" / rim storms intensify late-match. That's the BR closing-circle mechanic wearing flat-earth clothes; decide here whether the race needs it.
- "Recoverable failure where appropriate" keeps the loop alive: a hazard should humiliate, not softlock.
- All hazard damage is host-computed — identical exposure must produce identical outcomes on every peer.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — hazards compose M5 terrain + M9 weather + host-authoritative damage per AGENTS.md.
