# AGENTS.md — Spellforge

## Identity

Spellforge is a co-op wizard wave-defense game with modular spell crafting,
built in Roblox (Luau, Rojo). Current mission: ship the playable prototype
(beginning-to-end run), then scale into a deep collection game (12 elements,
4-tier power ladder, rarity 2.0).

This file is **binding agent procedure** for every session in this repo.
If a prompt or request conflicts with this file, the conflict must be raised
before work starts — not resolved silently.

## Session Start Procedure (mandatory, before ANY work)

Before writing any code, creating any branch, or making any design decision,
do the following in order:

1. Read [docs/GOAL_AND_ROADMAP.md](docs/GOAL_AND_ROADMAP.md). State, in one
   line, which **phase of the roadmap** the requested work belongs to.
2. Read [docs/tasks.md](docs/tasks.md). Identify the **task ID** (SF-xxx)
   the work falls under, and say so before starting.
3. If the work maps to neither — **stop**. Either:
   - propose adding it to the roadmap + tasks.md with a new ID (wait for
     approval), or
   - decline it as out of scope, citing the roadmap.

   Do not start work that is not in the roadmap. "It's small" or "it's just a
   fix" does not exempt it. Unmapped work is the definition of straying.

4. If the session is a *design* session (no code), the output is roadmap or
   tasks.md updates — the session is not finished until they are written.

## Session End Procedure (mandatory, work is not complete without it)

A task is **not complete when the code is written**. It is complete when all
of the following are true:

1. The change is committed and pushed. PRs only — one task = one branch = one
   PR, targeting `master`. No direct pushes, no merging without Ema's review.
2. [docs/tasks.md](docs/tasks.md) is updated **in the same session, before
   reporting done**:
   - move the task row from Upcoming/In-Progress to **Done**, or update its
     status field;
   - the Done row **must contain**: task ID, date, phase tag (e.g. "Phase 2"),
     one-line result, and evidence (commit hash, PR number, or playtest file).
   - an entry without a phase tag is invalid — write the phase or the work
     didn't count.
3. If the work changed the roadmap itself (new phase, scope shift, design
   lock), [docs/GOAL_AND_ROADMAP.md](docs/GOAL_AND_ROADMAP.md) is updated in
   the same commit — the roadmap and the tracker must never drift apart.
4. Playtest-gated phases are not "done" on static review: the PR's validation
   checklist must pass in Studio (notes → `docs/playtest/PT-NNN.md`).
   "Should work" is not evidence.

## Universal Rule (all projects)

Every project an agent works on must have (a) a goal/roadmap document and
(b) a task tracker logging completed work against that roadmap. The Session
Start and Session End procedures above are **hard requirements in all
projects moving forward**. When a project already has equivalent documents,
the agent must locate them and follow this same discipline against those
files — the procedure is universal; the filenames are local.

Reference implementations:
- Spellforge: `docs/GOAL_AND_ROADMAP.md` + `docs/tasks.md` (this file governs)
- Prizm: `AGENTS.md` → "Roadmap and Work Log Discipline" section, governing
  `docs/architecture/PRIZM_ROADMAP.md`, `docs/operations/PLAN_OF_ACTION.md`,
  `docs/operations/WORK_LOG.md`

## Technical Notes

- **Stack:** Luau, Rojo (serve on port 34877), Roblox Studio on Ema's machine
  only — no local Roblox runtime on the Mac mini. Static checks + code review
  here; playtest evidence comes from Ema's Studio sessions.
- **Architecture:** server (`src/ServerScriptService/`) is authoritative for
  all game state; clients render. Fragment inventory is server-truth (PR #3).
- **Branch model:** PRs target `master`. The GitHub default branch is a
  fossil from an orphan history — do not target it.
- **Docs:** [docs/PROTOTYPE_PLAN.md](docs/PROTOTYPE_PLAN.md) (phase detail),
  [docs/tasks.md](docs/tasks.md) (task tracker),
  [docs/GOAL_AND_ROADMAP.md](docs/GOAL_AND_ROADMAP.md) (goal + roadmap).