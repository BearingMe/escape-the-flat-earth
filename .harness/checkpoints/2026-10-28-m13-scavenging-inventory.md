# Checkpoint — M13 Scavenging & Inventory

**Date:** 2026-10-28 · **Status:** complete

M13 delivers the material scavenging and inventory economy for the escape race, replacing traditional drop-crates with deterministic world salvage distribution, atomic slot-based inventory transactions, shared storage containers, and risk-reward scarcity zoning pulling players toward the outer perimeter and the underside.

## Delivered Capabilities
- **Item Resource Definitions (`ItemDefinition`)**: Data-driven item metadata specifying item IDs, display names, stack caps, unit weights, categories, and rarity tiers (`wood_lumber.tres`, `scrap_metal.tres`, `tech_components.tres`, `ice_crystal.tres`, `void_obsidian.tres`).
- **Atomic Inventory Container (`InventoryContainer`)**:
  - Slot-based inventory supporting atomic additions, stack consolidation, partial removals, and slot swapping.
  - Inter-container transfer protocol preventing item duplication during concurrent transactions.
  - Real-time weight tracking with serialization and deserialization support.
- **Scarcity Zoning & Salvage Distribution (`SalvageDistribution`)**:
  - Disk-radius and altitude-based risk/reward tables:
    - Habitable Interior: common wood and scrap metal.
    - Outer Tundra: electronics and reinforced materials.
    - Ice Wall Rim: perimeter ice core crystals and aerospace salvage.
    - Underside: exotic void obsidian and alien alloys.
  - Deterministic sampling from world coordinates.
- **Shared Storage Containers (`LootContainer`)**:
  - World prop with integrated 16-slot storage chest.
  - Host-authoritative item transfers between player inventory and container.
  - Concurrency safety verified under simultaneous looting intents.
- **Player Encumbrance Trade-Offs (`ObserverPlayer`)**:
  - Integrated 12-slot personal inventory with 60 kg capacity.
  - Carried item weight dynamically scales movement speed (sprint disabled and walk speed throttled when carrying heavy loads over 30 kg).

## Verification
- `gdformat --check .` — passed (64 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 121 tests, 4,891 assertions across 28 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
