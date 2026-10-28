# Checkpoint — M12 Expedition Survival

**Date:** 2026-10-28 · **Status:** complete

M12 introduces host-authoritative survival state (health, stamina, hunger, thirst, core body temperature) that responds dynamically to local weather conditions and underside exposure, alongside consumable items, down-but-not-out incapacitation, and cooperative/opportunistic revival.

## Delivered Capabilities
- **Survival Simulation Model (`SurvivalState`)**:
  - Host-authoritative tracking of Health (0–100), Stamina (0–100), Hunger (0–100), Thirst (0–100), and Core Body Temperature (normal 37.0°C).
  - Stamina depletion during sprinting and climbing; resting recovery rate of 22% per second; sprint blocking when stamina is exhausted.
  - Thermal transfer with ambient weather: exposure to the subzero Ice Wall or sunless Underside causes core temperature loss into hypothermia (< 33°C), triggering health attrition damage.
  - Metabolic attrition: starvation and dehydration deal damage over time when meters empty.
- **Consumable Item System (`ConsumableDefinition`)**:
  - Authored Resource definitions for survival rations (`canned_beans.tres`, `water_canteen.tres`, `medical_kit.tres`).
  - Restores nutritional, hydration, and medical health stats on host consumption.
- **Incapacitation & Revival Mechanics (`ObserverPlayer`)**:
  - Down-but-not-out (DBNO) incapacitation: reaching 0 HP knocks the player into ragdoll with a 30-second bleedout countdown.
  - Another player can interact to revive the downed player (`revive_target_host`), restoring them to 35 HP and active movement.
  - Bleedout expiration cleanly transitions the character to permanent death, preventing softlocks or duplicate respawns.

## Verification
- `gdformat --check .` — passed (57 files).
- `gdlint .` — passed (clean, 0 problems).
- `godot --headless --path . --import` — passed.
- Headless `boot_smoke.tscn` — passed.
- GUT — 108 tests, 4,832 assertions across 25 scripts, all passed.
- Six-process multiplayer E2E (`run_multiplayer_smoke.gd`) — passed.
