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

### Replayability pillar (locked 2026-10-11 design session)
After the prototype loop is proven, Spellforge scales into a deep collection game:
- **12 elements** (6 today + water/wind/earth/metal, then light/void) — 288+ distinct same-element spells
- **Universal 4-tier power ladder: Spark → Blast → SuperNova → Megaton** (×1.0 / ×1.5 / ×2.5 / ×4.0) — replaces per-element power names
- **Rarity 2.0:** Mythic + Prismatic chase tiers, earned-only stacking Luck stat, displayed odds, 4-slot rarity contribution to spell tier (every fragment drop matters, dupes upgrade builds)

### Success criteria (all must hold)
- A new player can complete a full 10-wave run unassisted (survive, craft, win)
- Two consecutive playtests with zero server errors or soft-locks
- No economy exploit: fragments cannot be duplicated or crafted without owning them
- Progress survives rejoin (crystals, fragments, spells, best wave)

Post-prototype (Phases 7–10) success criteria:
- 288+ distinct same-element spells; every fragment rarity contributes to spell tier (no dead drops)
- A chase tier players grind for across many runs, with visible odds and earned luck only (no Robux luck — Roblox paid-random-item odds compliance by design)

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
| **Phase 7 — Power ladder v2** | `feat/power-ladder-v2` | Universal Spark/Blast/SuperNova/Megaton tiers + Megaton (×4.0), old-ID compat map | ⚪ queued |
| **Phase 8 — Element Wave A** | `feat/elements-wave-a` | Water / Wind / Earth / Metal (core, 3 shapes, 4 powers, 2 modifiers each) | ⚪ queued |
| **Phase 9 — Rarity 2.0** | `feat/rarity-v2` | Mythic+Prismatic, earned Luck stat + displayed odds, 4-slot rarity → spell tier badges | ⚪ queued |
| **Phase 10 — Element Wave B** | `feat/elements-wave-b` | Light / Void (blind+radiance, decay+singularity mechanics) | ⚪ queued |

**Dependency chain:** PR #1 → #2 → #3 (strict); Phase 4 may parallel #3; Phase 5 after #3; Phase 6 gates the prototype milestone. **Phases 7–10 (content expansion) start only after Phase 6** — the loop must be fun before we scale it. Phase 7 before 8 (new elements use the new ladder); 9 after 7 (rarity touches all fragments); 10 last (needs 9's mechanics for light/void effects).

### Phase exit criteria
- **Phase 1:** full solo run to victory; Play Again restarts clean; defeat path also restarts clean
- **Phase 2:** pack buy → craft → fragments deducted → rejoin → state intact; exploit attempts fail
- **Phase 3:** rejoin restores spells/bestWave; Max HP upgrade buy works once-and-only-once
- **Phase 4:** combat is visually readable without logs
- **Phase 5:** new player completes first run unassisted
- **Phase 6:** two consecutive clean full runs (PT-001/002 + any 2 of PT-003) — **prototype milestone reached; content expansion unlocked**
- **Phase 7:** all old power IDs map cleanly (no lost player fragments); Megaton craftable and visibly strongest
- **Phase 8:** 4 new elements fully craftable; each damage type + modifier distinguishable in play; fragment pool ≥ 100
- **Phase 9:** Mythic/Prismatic drop with displayed odds; Luck stacking visible in UI; a Prismatic spell shows a tier badge and hits harder
- **Phase 10:** Light/Void craftable with their unique mechanics live

---

## Ground Rules
- **PRs only** — one task = one branch = one PR; Ema reviews and merges
- **Playtest before merge** — every phase validated in Studio (notes → `docs/playtest/PT-NNN.md`)
- **Update tasks.md after every objective** — status changes, completion, blockers; all updates must name the roadmap phase they belong to
- **No scope creep** — out-of-scope items go to the Backlog section, not into active work

---
*Last updated: 2026-10-10 after PR #3*
