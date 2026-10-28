# Arowana: Escape the Flat Earth

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![GDScript](https://img.shields.io/badge/GDScript-2.0-blue)](https://docs.godotengine.org)
[![Testing](https://img.shields.io/badge/GUT-9.7.1-green)](https://github.com/bitwes/Gut)
[![Multiplayer](https://img.shields.io/badge/Multiplayer-Host--Authoritative-orange)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)

A first-person, multiplayer battle royale sandbox built in Godot 4.

The Earth is flat, the ice wall is real, the firmament is load-bearing, and the only way out is off the edge. Players scavenge, build, drive cursed modular contraptions, and exploit physics to be the first off the disc — or the last one standing.

---

## Core Pillars

- **The bit is canon**: Flat-earth lore is played 100% straight in-game. No winks, no fourth-wall breaks.
- **Sandbox first**: Grab, throw, build, drive, or launch physical objects across the terrain.
- **Improvised combat only**: No guns. Every weapon is grabbed, hurled, built, or crashed — mass and momentum are the damage model.
- **Escape is the win condition**: Vaulting past the 5,000-meter disc perimeter into free fall claims victory; if everyone dies trying, the last survivor wins.
- **Standard downward gravity**: Physics follows uniform downward gravity at $9.8\,\text{m/s}^2$ along the global $-Y$ axis across the entire surface, rim, and underside abyss — no radial gravity, no center-pull.
- **Strict host authority**: Zero client trust. The host authoritative server validates movement, combat impact, inventory transfers, construction joints, vehicle kinematics, and match win conditions.

---

## Gameplay & Systems

- **Procedural Flat-Earth Disc (5,000 m Radius, 200 m Depth)**:
  - *Arctic Hub* at the magnetic center ($r < 800\,\text{m}$)
  - *Temperate Habitable Belt* ($800\,\text{m} \le r < 2,800\,\text{m}$)
  - *Ring Sea / Maritime Expanse* ($2,800\,\text{m} \le r < 4,200\,\text{m}$)
  - *Circumferential Ice Wall Rim* ($4,200\,\text{m} \le r \le 5,000\,\text{m}$)
  - *Underside Void & Edge Abyss* ($y < -200\,\text{m}$)
  - Infinite deterministic chunk streaming with worker thread mesh generation.

- **Cartographic Survey Navigation**:
  - Real-time Gleason azimuthal equidistant projection minimap.
  - Nautical brass survey compass with true magnetic north tracking.

- **Dynamic Barometric Weather Simulation**:
  - Barometric pressure lapse rate $P(h) = 101.325 \times \exp(-h / 8400)\,\text{kPa}$.
  - Elevation temperature lapse ($-0.0065\,^\circ\text{C/m}$).
  - Cyclonic polar weather front rotating beneath the firmament dome.
  - High-latitude blizzard whiteouts, wind displacement forces, and frostbite hypothermia.

- **Advanced Traversal & Physics Interaction**:
  - 4-state locomotion state machine: `NORMAL`, `CLIMBING`, `RAGDOLL`, `CARRIED`.
  - Stamina-governed vertical climbing across ice faces, cliffs, and structures.
  - High-speed momentum stumble into dynamic ragdoll tumbling.
  - Symmetric player grab/carry/throw mechanics for team rescue or competitive hurling.
  - Two-player cooperative physical prop lifting and contested tug-of-war.

- **Metabolic Survival & Scavenging**:
  - Host-authoritative tracking of Health, Stamina, Hunger, Thirst, and Core Temperature.
  - Down-But-Not-Out (DBNO) incapacitation with 30-second bleedout and cooperative resuscitation.
  - Slot-based atomic inventory containers with verified non-duplicating transfers.
  - Regional resource distribution (Hub scrap, Ring Sea driftwood, Rim ice crystals, Void obsidian).
  - Dynamic inventory mass movement encumbrance penalties.

- **Modular Fabrication & Blueprint Construction**:
  - Data-driven crafting catalog with tier-based field workbenches.
  - Placeable structural components (beams, floors, walls, ramps, struts).
  - Physics-driven socket snapping and dynamic `Generic6DOFJoint3D` physical links.
  - Cantilever structural load calculation with realistic stress fracture collapse.

- **Multi-Occupant Modular Vehicles**:
  - 4-wheel raycast spring-damper suspension kinematics.
  - Dynamic steering, engine torque curves, tire grip friction, and fuel consumption.
  - Driver and passenger seating with multi-peer replication.
  - High-speed vehicular ramming damage scaled by total mass and velocity.

- **Firmament Defense Automata (AI Entities)**:
  - 5 distinct flat-earth lore enemy archetypes:
    - *Geodetic Drone* (aerial survey reconnaissance)
    - *Ice Sentinel* (heavy perimeter defense)
    - *Void Swarmer* (abyssal pack predator)
    - *Patrol Rover* (ground interdiction vehicle)
    - *Magnetic Anomaly* (erratic levitating energy core)
  - Utility AI perception, line-of-sight tracking, path steering, and salvage drop yields upon defeat.

- **Atmospheric Firmament Storm & Escape Protocol**:
  - Contracting radial firmament barrier that channels surviving players toward the rim.
  - Multi-modal perimeter escape options: foot sprint vault, endurance climbing leap, or high-speed vehicle ramp launch.
  - Zero-sum victory resolution conferring the official *Flat Earth Survey Commission Certificate of Proven Terrestrial Flatness*.

---

## Technical Architecture

```
project.godot
autoload/      # Core singletons: Log (structured diagnostics), Net (ENet P2P), World (simulation loop)
common/        # Shared pure logic, data structures, and custom Resource tables (.tres)
entities/      # Feature folders containing scenes (.tscn) and scripts (.gd):
  ├── player/  # Observer character controller, camera, climbing, ragdoll, survival
  ├── props/   # Physical props, modular construction parts, 4-wheel vehicles
  └── npcs/    # 5 flat-earth enemy AI archetypes
levels/        # flat_earth/ (disc, ice wall, firmament dome, ocean shader)
ui/            # Brass minimap, HUD bars, inventory screens, victory certificate modal
tests/         # Comprehensive GUT test suite and headless E2E verification
docs/          # Architecture boundaries, testing specifications, and logging rules
```

- **Host Authoritative**: The host server computes all physics outcomes, health depletion, collision impacts, inventory swaps, and boundary checks. Clients stream inputs and receive synchronized state.
- **Deterministic Replication**: Keyed peer identification, dedicated `MultiplayerSpawner`, and `MultiplayerSynchronizer` configurations ensure clean synchrony across peers without desync.

---

## Getting Started

### Prerequisites

- [Godot Engine 4.x](https://godotengine.org) (Forward Plus or Mobile renderer, console/headless binary recommended for test runners).
- Python with `gdtoolkit` (optional, for code formatting and linting):
  ```bash
  pip install gdtoolkit
  ```

### Running the Game

1. **Import Assets** (must be run first in headless or graphical mode):
   ```bash
   godot --headless --path . --import
   ```

2. **Launch the Game**:
   ```bash
   godot --path .
   ```

3. **Smoke Test Runtime**:
   ```bash
   godot --headless --path . --scene res://tests/scenes/boot_smoke.tscn --quit-after 60
   ```

---

## Testing & Quality Assurance

The project enforces automated test coverage across unit logic, multi-node integration, and multi-process network sessions:

- **Run Full GUT Suite**:
  ```bash
  godot --headless --path . --script res://tests/run_gut.gd
  ```
  *(170 tests across 45 test scripts covering terrain math, survival, kinematics, AI steering, and networking)*

- **Run Headless 6-Process Multiplayer E2E**:
  ```bash
  godot --headless --path . --script res://tests/e2e/run_multiplayer_smoke.gd
  ```

- **Run Formatting & Linting**:
  ```bash
  gdformat .
  gdlint .
  ```

---

## License

This project is licensed under the [MIT License](LICENSE).
