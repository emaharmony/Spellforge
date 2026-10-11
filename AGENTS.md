# AGENTS.md — Spellforge

## Identity

Spellforge is a co-op wizard wave-defense game with modular spell crafting, built in Roblox (Luau, Rojo). Current mission: prototype playable beginning-to-end, then scale into a deep collection game (12 elements, 4-tier power ladder, rarity 2.0).

## Project Governance (MANDATORY — applies in ALL projects, see below)

### RULE 1 — Alignment before work: read Goal & Roadmap first
Before starting any session, task, feature, refactor, or "quick fix" in this
project, read [docs/GOAL_AND_ROADMAP.md](docs/GOAL_AND_ROADMAP.md) (goal,
success criteria, phase roadmap, exit criteria). Then confirm the planned work
**aligns with a roadmap phase** and belongs to a task in
[docs/tasks.md](docs/tasks.md).

If a task does not map to a roadmap phase or task ID, do not silently proceed —
either (a) add it to the roadmap + tracker with an explicit ID and get it
approved, or (b) push back: it may be out of scope. **Roadmap first is how we
prevent straying.** The tracker's task IDs are the only sanctioned unit of work.

### RULE 2 — Completion means the log is written
A task is NOT complete when the code is done. It is complete when:
1. The change is committed (PRs only — one task = one branch = one PR)
2. [docs/tasks.md](docs/tasks.md) is updated: status change or a dated "Done"
   row with **task ID, roadmap phase tag, result, and evidence** (commit hash,
   PR number, test/playtest result)
3. Every entry names the roadmap phase it belongs to — no phase, no entry

If the work changed the roadmap itself (new phase, scope shift), update
[docs/GOAL_AND_ROADMAP.md](docs/GOAL_AND_ROADMAP.md) in the same commit —
the two documents must never drift.

### RULE 3 — Playtest evidence gates merges
Every phase is playtested in Studio before its PR merges (notes →
`docs/playtest/PT-NNN.md`). "Should work" is not evidence. Static review can
land a draft PR, but the phase is not "done" until the playtest checklist in
its PR passes.

## THE RULE — universal, all projects
Every project Lumi works on must have (a) a goal/roadmap document and (b) a
task tracker that logs completed work against that roadmap. RULE 1 (read and
align first) and RULE 2 (update the log after) are **hard requirements in all
projects moving forward**. If a similar document already exists in a project,
the project's AGENTS.md must point to it with the same RULE — the discipline
transfers, the filenames do not have to match.

Example: Prizm's equivalent is
[`AGENTS.md` → "Roadmap and Work Log Discipline"](https://github.com/emaharmony/prizm)
which governs `docs/architecture/PRIZM_ROADMAP.md`, `docs/operations/PLAN_OF_ACTION.md`,
and `docs/operations/WORK_LOG.md`.

## Technical Notes
- **Stack:** Luau, Rojo (serve on port 34877), Roblox Studio on Ema's machine only
- **Validation:** no local Roblox runtime — static checks + review on the Mac mini; playtest evidence comes from Ema's Studio sessions
- **Structure:** server (`src/ServerScriptService/`) authoritative for all game state; clients render. Fragment inventory is server-truth (Phase 2)
- **Branch model:** PRs only, `master` is the mainline (the GitHub default branch is a fossil — PRs target master)
- **Reference:** [docs/PROTOTYPE_PLAN.md](docs/PROTOTYPE_PLAN.md) (phase detail), [docs/tasks.md](docs/tasks.md) (task tracker)