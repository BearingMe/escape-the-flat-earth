# M13 — Scavenging & Inventory

**Phase:** Survival economy · **Depends on:** M6, M10, M12 · **Status:** complete

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

## Demo
- Interact with world salvage crates and storage containers: open container (`E`), transfer items between inventory slots, drop items into the physical world, and gather regional salvage (wood in plains/forest, scrap in ruins, void obsidian on underside).
- Automated test suite verifying atomic item transactions, stacking limits, concurrency safety, weight capacity, and save/load serialization: `godot --headless --path . --script res://tests/run_gut.gd`

## Tests
- `tests/unit/test_inventory_container.gd`: validates slot insertions, stacking caps, removals, transfers, swap operations, weight calculations, and serialization.
- `tests/unit/test_salvage_distribution.gd`: validates deterministic biome resource tables and scarcity zoning (interior baseline vs. high-tier rim/underside loot).
- `tests/integration/test_loot_container_transactions.gd`: validates concurrent player access to shared containers, host-authoritative atomic item transfers, physical world drops, and disconnect safety.

## Authority
- Host owns all inventory container contents, transaction validations, world item drops, and storage states.
- Clients send transaction intents (`transfer_intent`, `drop_intent`, `loot_intent`) and replicate slot state via RPC / synchronizer.

## Dependencies
- Upstream M6 World Population, M10 Physical Props, M12 Expedition Survival.

## Performance
- Slot transactions execute in O(1) dictionary lookups.
- Network sync transmits compact slot changes only when inventories are mutated.

## Known limitations
- Grid-based Tetris spatial inventory is not used; clean slot-based stacking is used for snappy BR pacing.

## Failure modes
- Concurrent transfer race condition: host processes transactions sequentially; second attempt returns error without item duping.
- Full inventory drop: rejected gracefully or dropped into physical world space.

## Arowana notes
- This is the loot loop — it replaces the BR drop-crate convention: the world IS the loot table.
- Scarcity zoning = risk/reward: the rim and the underside hold the best junk; the center is safe and boring. Greed pulls players toward the edge — that's the match funnel.
- "Shared storage" in a BR is also a betrayal magnet. Good.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — host-authoritative transactions + stable item IDs per AGENTS.md; item variants as `.tres` data tables in `common/data/`.
