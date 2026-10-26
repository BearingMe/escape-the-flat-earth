# Reference Vault Restored

**Date:** 2026-10-26 · **Milestone:** M1–M21 planning / reference groundwork

## Progress
- Recreated `.references/` in the project root on `main`; it remains gitignored/local-only.
- Shallow-cloned all seven sources into their project `source/` folders using the repository URLs in `.references/index.md`.
- Restored the three analysis files (`observations.md`, `constraints.md`, `references.md`) for each project from the still-intact MemPalace `.references` wing. The 21 documents were rebuilt from overlapping chunks and checked for missing chunks; Tinybox's references map was re-fetched after catching an incorrect chunk ID.
- Recreated `.references/README.md` and `index.md` as vault entry points.
- MemPalace remains intact (5,731 drawers across the seven reference rooms); room-scoped searches verified for `modu_vehicle` and `simple_x_terrain`.
- Vantix's 75 Git LFS objects are materialized (~1.09 GiB). The other six repositories cloned without LFS payloads.

## Important preservation note
`.references/` is ignored by Git. Keep the source URLs in the committed `.references/index.md` / this checkpoint, and the searchable corpus in MemPalace; do not assume a branch switch or worktree recreation preserves the local vault. Before deleting any worktree that may hold local-only data, verify or move ignored folders first.

## Verification
- Seven `source/` folders; each remote URL matches the supplied repository.
- All 21 analysis files present; vault README and index present.
- `git status` stays clean for `.references/` because the folder is intentionally ignored; checkpoint is the tracked record of recovery.
