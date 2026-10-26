# AGENTS.md

## Project Overview
**Arowana** — *"Escape the Flat Earth"*: a first-person, multiplayer battle royale sandbox in Godot 4, full of unhinged bullshit. The Earth is flat, the ice wall is real, the firmament is load-bearing, and the only way out is off the edge. Players fight, build, and exploit cursed physics to be the first to escape — or the last one standing.

Design pillars — never trade these away for "clean" code:
- **The bit is canon**: flat-earth lore is played 100% straight in-game. Lean in, never wink.
- **Sandbox first**: every item must be throwable, buildable, rideable, or explosive. Ideally all four.
- **Jank is a feature; breakage is not**: comedic physics jank is acceptable. The core loop (spawn → loot → build → fight → escape) must always work.
- **Escape is the win condition**: first player off the disc ends the match; if everyone dies trying, last one standing wins.
- **Newtonian flat earth**: the long-term physics intent is a finite-disk field that points at the disc from both sides; never use a global down-vector. Per explicit user direction on 2026-10-26, gravity implementation is deferred: keep engine default gravity at zero and do not restore a gravity subsystem until the user reopens that scope.
- **Improvised combat only**: no guns. Every weapon is grabbed, thrown, built, or crashed — mass and momentum are the damage model, and the host does the math.

## Tech Stack
- Godot 4.x (latest stable), GDScript 2.0, strongly typed
- Multiplayer: built-in high-level multiplayer API over ENet — P2P, one player hosts, others join by IP — 2–6 players per session
- Testing: GUT 9.7.1 (`addons/gut`) for unit/integration; project-owned headless Godot processes for E2E
- Format/lint: gdformat + gdlint (`pip install gdtoolkit`)
- No C#, no third-party netcode, no Steam integration unless explicitly requested

## Commands
```bash
godot --headless --path . --import         # import assets (run after clone, before any headless run)
godot --headless --path . --scene res://tests/scenes/boot_smoke.tscn --quit-after 60  # smoke-test runtime/autoload boot
godot --path .                             # run the game
gdformat .                                 # formatter config excludes vendored/generated/reference code
gdlint .                                   # linter config excludes vendored/generated/reference code
godot --headless --path . --script res://tests/run_gut.gd  # run GUT; fails if no tests are discovered
```
`godot` must be on PATH (Windows: use the full path to the Godot editor exe if not).

## Repository Structure
```
project.godot
addons/      # Third-party plugins (Godot AI, GUT). Vendored — never hand-edit.
assets/      # Art, audio, fonts, models. Zero code.
autoload/    # Global singletons: Log (structured diagnostics), net.gd (host/join/peers), game.gd (match state), events.gd (signal bus)
common/      # Shared utilities + custom Resources (.tres item/weapon data tables). Zero scenes.
entities/    # player/, weapons/, npcs/, props/ — each folder holds its .tscn + .gd together
levels/      # flat_earth/ (the disc, ice wall, firmament) + small test arenas
ui/          # menu/ (main menu, host/join), hud/ (health, build menu)
tests/       # unit/, integration/, e2e/, fixtures/, support/ — see docs/testing.md
docs/        # Testing, structured logging, and error-handling conventions
.opencode/   # OpenCode project skills (mempalace setup). Committed.
.references/ # Local-only reference vault (7 repos + analysis) mirroring the mempalace `.references` wing. Gitignored — never commit.
.harness/    # Progress protocol: milestones/ (goals) + checkpoints/ (progress). Committed.
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
- Expected failures return typed errors/results; unexpected failures are reported once with actionable context via `Log.error()`. Assertions are for programmer invariants, never user/network input. See `docs/error-handling.md` and `docs/logging.md`.
- New behavior includes meaningful unit/integration coverage and tests for its fallible paths; E2E covers cross-process and multiplayer behavior. See `docs/testing.md`.
- Commit messages follow Conventional Commits only: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc. (e.g. `feat: add buildable prop spawner`). Never use vague messages like "update" or "stuff".

## Memory Systems
Two memory systems are available; the split is strict, never cross them:
- **agentmemory** — Arowana work memory: session observations, decisions, bugs/gotchas, lessons, per-file history. Search it before redoing past Arowana work; save decisions and lessons there as the project evolves.
- **mempalace** — external reference corpus: the `.references/` vault, mined into the `.references` wing (rooms = one per reference project, underscore names like `modu_vehicle`). Search it before browsing `source/` folders directly: MCP `mempalace_search({ query, room })` — filter by **room only**, never by wing (the wing name `.references` is rejected by MCP validation; room names are unique palace-wide so room filtering is equivalent). CLI fallback: `mempalace search "query" --room <project>`.
- Never write Arowana session state into mempalace, and never search agentmemory for reference-repo content. Other mempalace wings belong to other projects — always scope queries to the `.references` wing.

## Progress Tracking
No task lists. Progress lives in `.harness/` (see its README):
- `milestones/` — what we want to reach; one file per milestone, written when a goal is set.
- `checkpoints/` — our progress; one file per checkpoint, written as work lands.
The M1–M21 roadmap lives in `milestones/` (imported from the flat-earth plan); milestone rules and the handoff checklist are in `.harness/README.md`.
- **Every milestone must be committed.** Commit all milestone-scoped changes before marking its checkpoint complete or starting the next milestone. Use Conventional Commit messages; a checkpoint is not a substitute for a commit.

## Workflow
1. **Understand**: read the relevant scenes/scripts first; mirror how existing netcode handles the same problem. For anything terrain-, vehicle-, grab/throw-, or netcode-shaped, search mempalace (see Memory Systems) for a proven reference implementation before writing from scratch.
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
- Never leave ad-hoc `print()` debug spam in merged code; use `Log` for structured application diagnostics and follow `docs/error-handling.md` for recovery. Assertions are for programmer invariants only.

## Definition of Done
Work is complete ONLY when:
- `godot --headless --path . --import` and the headless boot smoke scene exit clean
- `gdlint` passes and `gdformat` has been applied to project-owned GDScript (not vendored addons)
- GUT suite is green
- Relevant headless E2E scenarios pass; multiplayer changes include a separate host and client process — never merge netcode blind from a single-instance test
- No unexpected engine, GUT, or `push_error` output remains; intentional errors are asserted with recovery behavior covered
- All changes for the milestone are committed with Conventional Commit messages before it is marked complete
- No unrelated files were touched
