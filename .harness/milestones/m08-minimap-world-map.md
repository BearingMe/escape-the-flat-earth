# M8 — Minimap & World Map

**Phase:** Environment · **Depends on:** M5, M7 · **Status:** not started

## Goal
Give players reliable navigation on a finite disk.

## Scope
- Circular minimap showing the disk's actual shape.
- Player position, heading, and positions of teammates where appropriate.
- Distinct biome regions derived from generated world data.
- Configurable zoom and north-up/camera-relative rotation.
- Optional full-screen map.
- Clear representation of rim and underside traversal.
- Client-local UI backed by authoritative world coordinates.

## Validation
- Map location matches world location at known test points.
- Biome boundaries agree with generated terrain.
- Teammate markers update correctly and disappear on disconnect.
- Heading, zoom, and orientation work on all sides of the disk.
- Minimap remains responsive with several players exploring different regions.

## Arowana notes
- The map is itself a lore artifact: render it as an "official" flat-earth survey chart — played 100% straight, no winking.
- BR discipline: opponents' positions must never reach the UI except through legitimately visible state (e.g. last-known from your own sightings). No authoritative-position leaks.
- With 2–6 free-for-all players, "teammates where appropriate" means squad mode only if/when it exists — default FFA renders no other markers.

## References — search before building (mempalace wing `.references`, filter by room)
- No direct reference repo — plain Godot Control/UI over authoritative world data; biome regions come from M5's deterministic data.
