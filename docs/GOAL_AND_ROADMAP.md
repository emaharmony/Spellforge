# Spellforge — Goal & Roadmap

**Repo:** github.com/emaharmony/Spellforge
**Companion docs:** [PROTOTYPE_PLAN.md](PROTOTYPE_PLAN.md) (phase detail) • [tasks.md](tasks.md) (task-by-task tracking)

---

## The Goal

**Build a playable prototype of Spellforge: a co-op wizard wave-defense game with modular spell crafting — playable beginning to end, in Roblox.**

"Playable beginning to end" means, concretely:

1. **Join** — a player enters, gets a wizard, a starter spell, and a fragment kit
2. **Defend** — 10 waves of enemies attack; the wizard's auto-attack stops them; enemies who reach the wizard deal damage
3. **Earn** — kills and waves award crystals and fragment drops
4. **Craft** — between waves, fragments assemble into stronger spells through the crafting UI (validated, deduplicated, server-economized)
5. **Win or lose** — clear wave 10's boss → victory screen; all wizards fall → defeat screen
6. **Again** — one click restarts a clean run; crystals, fragments, and records persist between sessions

Prototype scope *excludes*: manual casting (M2), spell equipping/swap UI, co-op lobby, ranged enemy AI, audio, art polish, monetization. Those come after the prototype proves the loop is fun.

### Success criteria (all must hold)
- A new player can complete a full 10-wave run unassisted (survive, craft, win)
- Two consecutive playtests with zero server errors or soft-locks
- No economy exploit: fragments cannot be duplicated or crafted without owning them
- Progress survives rejoin (crystals, fragments, spells, best wave)

---

## The Roadmap

Six phases from current state to prototype-done. Each phase = one branch = one PR, playtested before merge (house rule). All task tracking in [tasks.md](tasks.md) must reference these phases.

| Phase | Branch | Delivers | Status |
|-------|--------|----------|--------|
| **PR #1 — Gameloop fix** | `feature/simple-gameloop` | The 7 dead-wire fixes: auto-attack loop, enemy repath, undefined methods, spawn ring, range cap | 🔶 in review |
| **PR #2 — Run integrity (Phase 1)** | `fix/run-integrity` | Results screen, Play Again, resetable WaveSystem, kill-credit fix, arena walls | 🔶 in review |
| **PR #3 — Economy truth (Phase 2)** | `feat/economy-server-truth` | Server-fragment inventory, craft deduct, pack integrity, InventorySync, starter kit | 🔶 in review |
| **Phase 3 — Meta persistence** | `feat/meta-persistence` | Spells/bestWave persistence, Max HP shop entry | ⚪ queued |
| **Phase 4 — Combat feel** | `feat/spell-vfx` | SpellFired projectile VFX (color by spell) | ⚪ queued |
| **Phase 5 — Onboarding** | `feat/onboarding-glue` | Boss warning, first-join instructions | ⚪ queued |
| **Phase 6 — Balance & playtest** | `balance/playtest` | PT-001/002/003 runs, evidence-based tuning | ⚪ queued |

**Dependency chain:** PR #1 → #2 → #3 (strict); Phase 4 may parallel #3; Phase 5 after #3; Phase 6 last (needs everything).

### Phase exit criteria
- **Phase 1:** full solo run to victory; Play Again restarts clean; defeat path also restarts clean
- **Phase 2:** pack buy → craft → fragments deducted → rejoin → state intact; exploit attempts fail
- **Phase 3:** rejoin restores spells/bestWave; Max HP upgrade buy works once-and-only-once
- **Phase 4:** combat is visually readable without logs
- **Phase 5:** new player completes first run unassisted
- **Phase 6:** two consecutive clean full runs (PT-001/002 + any 2 of PT-003)

---

## Ground Rules
- **PRs only** — one task = one branch = one PR; Ema reviews and merges
- **Playtest before merge** — every phase validated in Studio (notes → `docs/playtest/PT-NNN.md`)
- **Update tasks.md after every objective** — status changes, completion, blockers; all updates must name the roadmap phase they belong to
- **No scope creep** — out-of-scope items go to the Backlog section, not into active work

---
*Last updated: 2026-10-10 after PR #3*
