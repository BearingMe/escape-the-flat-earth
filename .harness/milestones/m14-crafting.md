# M14 — Crafting

**Phase:** Survival economy · **Depends on:** M13 · **Status:** complete

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

## Demo
- Interact with world expedition workbenches: view craftable recipes, craft tools and equipment (grappling spikes, thermal wraps, steam megaphone, firmament sensor), and repair damaged tools using scrap metal.
- Automated tests verifying recipe validation, atomic material consumption, shared station concurrency, and durability tracking: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_crafting_recipe.gd`: validates recipe ingredient requirements, output counts, station prerequisites, and validation checks.
- `tests/unit/test_crafting_catalog.gd`: validates catalog registration, recipe discovery by available ingredients, and recipe queries.
- `tests/integration/test_crafting_station.gd`: validates host-authoritative crafting execution, atomic ingredient deduction, inventory overflow handling, durability repairs, and concurrent multiplayer craft attempts.

## Authority
- Host owns all crafting recipe verification, ingredient consumption from player inventories, and item output generation.
- Clients send crafting requests via RPC (`submit_craft_intent(recipe_id)`) and receive updated inventory state.

## Dependencies
- Upstream M13 Scavenging & Inventory (`InventoryContainer`, `ItemDefinition`, `LootContainer`).

## Performance
- Recipe lookup: O(1) dictionary query in static `CraftingCatalog`.
- Ingredient consumption: atomic single-pass removal across inventory slots.

## Known limitations
- Complex crafting minigames are omitted in favor of instant/timed atomic recipes to preserve fast-paced battle royale tempo.

## Failure modes
- Insufficient ingredients or missing station: host rejects craft attempt with descriptive error code without consuming partial materials.
- Inventory full on craft completion: crafted item is dropped physically into the world in front of the crafting station.

## Arowana notes
- Crafting gates the endgame escape equipment (M19 leans here) — the recipe tree is the expedition's tech tree.
- A shared crafting station in a BR is a contested point of interest: expect workbench fights. Host validates every transaction.
- "Useful AND ridiculous" — both halves are mandatory. A rescue winch and a steam-powered megaphone are equally legitimate recipes.

## References — search before building (mempalace wing `.references`, filter by room)
- `open_acre` — GPL-3.0, architecture-only (clean-room) — data-driven recipe/station patterns.
