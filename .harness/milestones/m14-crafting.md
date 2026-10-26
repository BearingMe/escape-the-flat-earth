# M14 — Crafting

**Phase:** Survival economy · **Depends on:** M13 · **Status:** not started

## Goal
Turn recovered junk into useful and ridiculous expedition tools.

## Scope
- Data-driven recipes and crafting requirements.
- Basic tools, consumables, equipment, and building materials.
- Crafting stations where appropriate.
- Item durability and repair for selected equipment.
- Shared-station use in multiplayer.
- Crafting transactions synchronized and validated by the host.
- Recipe discovery/progression based on accessible resources.

## Validation
- Crafting consumes exactly the required inputs and yields valid outputs.
- Simultaneous users cannot spend the same materials twice.
- Repair and durability systems preserve item identity.
- Crafted items work with inventory and physics interaction systems.
- Recipe progression is achievable using generated world resources.
- Crafting state survives save/load.

## Arowana notes
- Crafting gates the endgame escape equipment (M19 leans here) — the recipe tree is the expedition's tech tree.
- A shared crafting station in a BR is a contested point of interest: expect workbench fights. Host validates every transaction.
- "Useful AND ridiculous" — both halves are mandatory. A rescue winch and a steam-powered megaphone are equally legitimate recipes.

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — data-driven recipe/station patterns.
