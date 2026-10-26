# M7 — Quality Gate & Refactoring

**Phase:** Quality gate · **Depends on:** M1–M6 · **Status:** not started

## Goal
Stabilize the complete world foundation before adding gameplay systems.

## Scope
- Audit boundaries between gravity, networking, generation, terrain, rendering, and controls.
- Remove unnecessary coupling, dead code, temporary workarounds, and duplicated logic.
- Review seed handling, authority rules, entity identifiers, and lifecycle cleanup.
- Add focused unit and integration tests for numerical gravity, deterministic generation, and multiplayer joining.
- Profile terrain generation, chunk streaming, rendering, physics, CPU, GPU, and memory.
- Fix critical defects and optimize only measured bottlenecks.
- Document architecture, world generation, gravity assumptions, and operational setup.

## Validation
- All acceptance checks from M1–M6 still pass.
- Clean checkout, documented setup, build, and multiplayer launch succeed.
- Full-disk traversal and two-player distant exploration work without crashes.
- No known critical collision, gravity, authority, or world-generation defects.
- No unexplained persistent memory growth or major frame-time spikes in measured test routes.
- Architecture documentation matches the actual code.

## Out of scope
- New gameplay features.

## Arowana notes
- This is also the "jank is a feature; breakage is not" enforcement point — cut anything that threatens the core loop (spawn → loot → build → fight → escape). Slop survives; breakage does not.
- Profile for BR pacing: two players exploring distant regions simultaneously must not tank frame time.
- DoD per AGENTS.md applies here with teeth: import + smoke boot + gdlint + GUT all clean, host + client verified.

## References — search before building (mempalace wing `.references`, filter by room)
- Process milestone — no direct repo to mine. Verify via GUT suite, gdlint, and mempalace room audits of what was already ported.
