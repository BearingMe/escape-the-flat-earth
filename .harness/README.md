# .harness — Progress Protocol

No task lists. Progress is tracked as **milestones** and **checkpoints**.

- `milestones/` — what we want to reach. One file per milestone: `m01`–`m21`.
- `checkpoints/` — our progress. One file per checkpoint, written as work lands.

Checkpoints are named `YYYY-MM-DD-<milestone>-<slug>.md`, e.g. `2026-10-26-m01-host-join-live.md`.

## Import decisions (why milestone wording looks adapted)

The milestone plan was imported from `flat-earth-milestones.md` (deleted after import; its content lives here and in `milestones/`). Three decisions were made at import:

1. **GDScript 2.0, not C#** — the source plan targeted Godot .NET/C#; the project stack is GDScript-only (AGENTS.md). C# mentions were translated to typed GDScript equivalents.
2. **Hybrid frame** — the source plan reads as a cooperative survival expedition; Arowana is a battle royale. Kept: the BR win condition (first off the disc ends the match; last one standing if everyone dies) with the survival/crafting/building milestones as the escape toolkit. Rivals cooperate opportunistically; the finish line is zero-sum.
3. **Improvised combat only** — no dedicated weapons milestone and no guns: combat is grabbed/thrown/rolled junk, contraptions, hazards, and momentum. M10 carries the damage rules; M11's player-grabbing doubles as melee.

## Milestone rules

1. **Multiplayer from day one.** M1 establishes hosting, joining, authority, and synchronization. Every subsequent gameplay feature must work in multiplayer. There is no later "multiplayer integration" milestone.
2. **Gravity is standard Earth gravity.** Use 9.8 m/s² along global downward Y only. Do not add horizontal, radial, or center-push gravity, and do not make gravity point toward the disk center or flip on the underside.
3. **Rigid world, real forces.** The disk does not collapse or deform. When physical simulation is introduced, mobile objects respond consistently to gravity and collisions; simplified atmospheric/weather models must be documented as approximations.
4. **Authority is explicit.** The host owns canonical game state, shared physics, resources, and persistent state. Clients may interpolate or predict visuals and movement where justified. (See AGENTS.md netcode rules.)
5. **Every milestone is independently demonstrable.** The milestone must have a working demo and acceptance checks, not just an implementation checklist.
6. **Automate meaningful tests.** Test calculations, multiplayer invariants, persistence, and procedural determinism. Do not test trivial getters, constants, or engine behavior without a regression reason.
7. **Keep systems separate.** World data, generation, simulation, rendering, networking, and interaction must have explicit responsibilities. (See AGENTS.md boundaries.)
8. **Do not implement future milestones early.** Small supporting abstractions are acceptable; full systems belong to their milestone.
9. **Failure behavior is designed and tested.** Expected failures are explicit, recoverable failures preserve valid state, and authority boundaries reject bad client intents. See [error handling](../docs/error-handling.md) and [testing](../docs/testing.md).

## Roadmap

| Phase | Milestones | Demonstrable outcome |
|---|---|---|
| Foundation | M1–M3 | Multiplayer disk, camera, and movement under standard downward gravity |
| World | M4–M6 | Procedural terrain, five biomes, environmental population |
| Quality gate | M7 | Tested, profiled, refactored world foundation |
| Environment | M8–M9 | Minimap and dynamic synchronized weather |
| Physical co-op | M10–M11 | Object manipulation, climbing, and ragdolls |
| Survival economy | M12–M14 | Survival, scavenging, inventory, crafting |
| Engineering | M15–M16 | Cooperative builds and vehicles |
| Challenges | M17–M18 | Environmental hazards and five enemy archetypes |
| Endgame | M19–M20 | Multiple escape routes and a playable ending |
| Final quality gate | M21 | Release-ready cooperative game |

## Milestone index

| File | Milestone |
|---|---|
| [m01](milestones/m01-disk-multiplayer-foundation.md) | M1 — Disk & Multiplayer Foundation |
| [m02](milestones/m02-camera-system.md) | M2 — Camera System |
| [m03](milestones/m03-character-movement.md) | M3 — Character Movement |
| [m04](milestones/m04-procedural-terrain.md) | M4 — Procedural Terrain |
| [m05](milestones/m05-five-biomes.md) | M5 — Five Biomes |
| [m06](milestones/m06-world-population.md) | M6 — World Population |
| [m07](milestones/m07-quality-gate-world-foundation.md) | M7 — Quality Gate & Refactoring |
| [m08](milestones/m08-minimap-world-map.md) | M8 — Minimap & World Map |
| [m09](milestones/m09-dynamic-weather.md) | M9 — Dynamic Weather |
| [m10](milestones/m10-physics-interactions.md) | M10 — Physics Interactions |
| [m11](milestones/m11-advanced-movement-ragdolls.md) | M11 — Advanced Movement & Ragdolls |
| [m12](milestones/m12-expedition-survival.md) | M12 — Expedition Survival |
| [m13](milestones/m13-scavenging-inventory.md) | M13 — Scavenging & Inventory |
| [m14](milestones/m14-crafting.md) | M14 — Crafting |
| [m15](milestones/m15-modular-construction.md) | M15 — Modular Construction |
| [m16](milestones/m16-vehicles-transportation.md) | M16 — Vehicles & Transportation |
| [m17](milestones/m17-environmental-hazards.md) | M17 — Environmental Hazards |
| [m18](milestones/m18-enemies-ai.md) | M18 — Enemies & AI |
| [m19](milestones/m19-escape-mechanics.md) | M19 — Escape Mechanics |
| [m20](milestones/m20-ending-victory.md) | M20 — Ending & Victory |
| [m21](milestones/m21-final-quality-gate-release.md) | M21 — Final Quality Gate & Release Readiness |

## Milestone handoff checklist

When work on a milestone starts, extend its file with:

- **Demo:** the smallest reproducible scenario proving the new capability.
- **Tests:** high-value automated checks and any required multiplayer/manual checks.
- **Authority:** which state is host-owned, client-local, derived, or persistent.
- **Dependencies:** the earlier systems used and any assumptions introduced.
- **Performance:** relevant measurements, not speculative optimizations.
- **Known limitations:** deviations, approximations, and intentionally deferred work.
- **Failure modes:** expected and unexpected failures, recovery/player feedback, and tests for the failure paths.

**Scope rule:** A milestone is done when its acceptance criteria are met, not when every conceivable enhancement is implemented.
