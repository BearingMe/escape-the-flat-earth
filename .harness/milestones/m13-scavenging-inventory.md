# M13 — Scavenging & Inventory

**Phase:** Survival economy · **Depends on:** M6, M10, M12 · **Status:** not started

## Goal
Give expeditions a material purpose and players a reason to transport objects home.

## Scope
- World-spawned salvage and biome-specific materials.
- Gathering, collecting, carrying, dropping, and storing items.
- Inventory stacks and unique physical item identities where required.
- Containers, loot transfer, and shared storage.
- Resource scarcity/distribution rules by region.
- Host-authoritative transactions and stable item IDs.
- Minimal persistence for inventories and world resources.

## Validation
- Resource placement is reproducible from a world seed where intended.
- Gather/drop/transfer operations cannot duplicate items under concurrent interaction.
- World items and inventories stay consistent between clients.
- Disconnects during transfer preserve exactly one canonical item state.
- Inventory and depleted resources survive save/load.
- Every biome contains meaningful resources or exploration value.

## Arowana notes
- This is the loot loop — it replaces the BR drop-crate convention: the world IS the loot table.
- Scarcity zoning = risk/reward: the rim and the underside hold the best junk; the center is safe and boring. Greed pulls players toward the edge — that's the match funnel.
- "Shared storage" in a BR is also a betrayal magnet. Good.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — host-authoritative transactions + stable item IDs per AGENTS.md; item variants as `.tres` data tables in `common/data/`.
