# AGENTS.md

## Project Overview
**Arowana** — *"Escape the Flat Earth"*: a first-person, multiplayer battle royale sandbox in Godot 4, full of unhinged bullshit. The Earth is flat, the ice wall is real, the firmament is load-bearing, and the only way out is off the edge. Players fight, build, and exploit cursed physics to be the first to escape — or the last one standing.

Design pillars — never trade these away for "clean" code:
- **The bit is canon**: flat-earth lore is played 100% straight in-game. Lean in, never wink.
- **Sandbox first**: every item must be throwable, buildable, rideable, or explosive. Ideally all four.
- **Jank is a feature; breakage is not**: comedic physics jank is acceptable. The core loop (spawn → loot → build → fight → escape) must always work.
- **Escape is the win condition**: first player off the disc ends the match; if everyone dies trying, last one standing wins.

## Tech Stack
- Godot 4.x (latest stable), GDScript 2.0, strongly typed
- Multiplayer: built-in high-level multiplayer API over ENet — P2P, one player hosts, others join by IP
- Testing: GUT (`addons/gut`)
- Format/lint: gdformat + gdlint (`pip install gdtoolkit`)
- No C#, no third-party netcode, no Steam integration unless explicitly requested

## Commands
```bash
godot --headless --path . --import         # import assets (run after clone, before any headless run)
godot --headless --path . --quit-after 60  # smoke-test boot; must exit with no script/parse errors
godot --path .                             # run the game
gdformat .                                 # format all GDScript
gdlint .                                   # lint all GDScript
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit  # run tests
```
`godot` must be on PATH (Windows: use the full path to the Godot editor exe if not).

## Repository Structure
```
project.godot
addons/      # Third-party plugins (GUT). Vendored — never hand-edit.
assets/      # Art, audio, fonts, models. Zero code.
autoload/    # Global singletons: net.gd (host/join/peers), game.gd (match state), events.gd (signal bus)
common/      # Shared utilities + custom Resources (.tres item/weapon data tables). Zero scenes.
entities/    # player/, weapons/, npcs/, props/ — each folder holds its .tscn + .gd together
levels/      # flat_earth/ (the disc, ice wall, firmament) + small test arenas
ui/          # menu/ (main menu, host/join), hud/ (health, build menu)
tests/       # GUT tests, mirroring source folders
```

**Boundaries:**
- `autoload/` singletons are the only global state. Gameplay scripts never traverse the tree with `../` or absolute paths — use signals, groups, or autoload APIs.
- Scenes and their scripts live together in the same feature folder (`entities/player/player.tscn` + `player.gd`).
- `assets/` contains no code; `common/` contains no scenes.
- Peer/lifecycle management lives in `autoload/net.gd`; RPC logic for an entity lives in that entity's own script.

## Rules & Conventions
- GDScript style: tabs (Godot default), PascalCase for classes/nodes, snake_case for files/functions/vars, SCREAMING_SNAKE_CASE for constants. Full type hints on signatures and member vars.
- Scripts that are reused use `class_name`. Autoloads never get `class_name` (it collides with the autoload registration).
- Every RPC has an explicit `@rpc` annotation (`"authority"`, `"any_peer"`, reliable/unreliable) — never rely on default RPC config.
- **The host is authoritative.** Clients send intents; the host resolves damage, physics, loot, and win conditions. Never accept client claims about damage, spawns, or position on the host.
- Networked spawning goes through `MultiplayerSpawner`; state sync through `MultiplayerSynchronizer`. Synced nodes get deterministic names keyed by peer ID so paths match on all peers.
- Guard input and cosmetics with `is_multiplayer_authority()`.
- Item/weapon variants are `.tres` Resources in `common/data/` — don't write a new script class when a resource export will do.
- Signals are typed: `signal died(killer_id: int)`. Connect in code, not in the editor, when the wiring is logic.
- Node references use `@onready` + `%` unique names, never hardcoded string paths that scene edits can break.
- New `.tscn` files stay small and get assembled in code over deep nesting. Reference scripts/scenes by `res://` path; let `--import` generate UIDs — never invent `uid://...` strings.
- Commit messages follow Conventional Commits only: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc. (e.g. `feat: add buildable prop spawner`). Never use vague messages like "update" or "stuff".

## Workflow
1. **Understand**: read the relevant scenes/scripts first; mirror how existing netcode handles the same problem.
2. **Plan**: one feature per change, minimal blast radius.
3. **Implement**: follow the conventions above; scenes stay text-format.
4. **Verify**: smoke-test boot, tests, gdformat.
5. **Self-review**: no unrelated file changes, no debug prints left behind.

## Never
- Never edit `.godot/`, `*.import`, or anything under `addons/` by hand.
- Never commit `.godot/`. Never use binary scene/resource format (`.scn`/`.res`) for authored content — keep `.tscn`/`.tres`. Do commit `.uid` files.
- Never trust the client. Never ship gameplay-critical logic that runs independently per-peer.
- Never use per-peer `await get_tree().create_timer()` for match-critical timing — host-authoritative timers only.
- Never break the core loop to ship a joke. A joke that crashes the match gets fixed or cut.
- Never add an addon, plugin, or engine dependency without explicit user approval.
- Never commit secrets, private server IPs, or personal config (`override.cfg` is local-only).
- Never leave `print()` debug spam in merged code; use `push_warning()`/`assert()` for real problems.

## Definition of Done
Work is complete ONLY when:
- `godot --headless --path . --import` and the `--quit-after 60` smoke test exit clean
- `gdlint .` passes and `gdformat` has been applied
- GUT suite is green
- Multiplayer changes are verified with host + at least one client peer — never merge netcode blind from a single-instance test
- No unrelated files were touched
