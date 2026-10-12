# Spellforge — Task Tracker

**Last Updated:** 2026-10-11
**Roadmap:** [GOAL_AND_ROADMAP.md](GOAL_AND_ROADMAP.md) — all tasks below belong to a phase there
**Old entries (SF-001…004, May–Jun):** preserved at the bottom as [Archive](#archive) — SF-004's balance pass was superseded by the prototype plan's Phase 6

---

## Active Work

| ID | Phase | Task | Branch / PR | Status |
|----|-------|------|-------------|--------|
| SF-115 | Phase 6 | Test harness: Studio MCP smoke pipeline + 3 harness-caught fixes | `fix/datastore-playmode-fallback` → [PR #5](https://github.com/emaharmony/Spellforge/pull/5) | 🔶 in review |
| SF-120 | Phase 4 | SpellFired VFX: streak + impact burst, element-colored | `feat/spell-vfx` → [PR #6](https://github.com/emaharmony/Spellforge/pull/6) | ✅ merged |
| SF-130 | Phase 5 | BossWarning fired on wave-10 boss spawn + banner client | `feat/onboarding-glue` → [PR #7](https://github.com/emaharmony/Spellforge/pull/7) | 🔶 in review |
| SF-131 | Phase 5 | First-join instruction card (auto-dismiss on wave 1 clear) | `feat/onboarding-glue` → [PR #7](https://github.com/emaharmony/Spellforge/pull/7) | 🔶 in review |
| SF-132 | Phase 5 | C keybind → crafting UI toggle (in SpellforgeUI itself) | `feat/onboarding-glue` → [PR #7](https://github.com/emaharmony/Spellforge/pull/7) | 🔶 in review |
| SF-140 | Phase 6 | TEST_MODE/TEST_START_WAVE harness fixtures + PT-002 lifecycle gate | `balance/playtest` → [PR #8](https://github.com/emaharmony/Spellforge/pull/8) | 🔶 in review |
| SF-141 | Phase 6 | Boss + victory path validation (Amber Colossus, wave-10 flow) | `balance/playtest` → [PR #8](https://github.com/emaharmony/Spellforge/pull/8) | 🔶 in review |
| SF-142 | Phase 6 | Kill-credit fix: Rarity attribute + boss tier bounty | `balance/playtest` → [PR #8](https://github.com/emaharmony/Spellforge/pull/8) | 🔶 in review |

### Merge order: PR #1 → #2 → #3 (each stacks on the previous)

---

## Upcoming (queued in roadmap order)

| ID | Phase | Task | Notes |
|----|-------|------|-------|
| SF-112 | Phase 3 | Playtest: persistence round-trip (rejoin restores all) | exit gate — needs published place for DataStore (PT-001 smoke PASS covers the loop) |
| SF-120 | Phase 4 | SpellFired projectile VFX client listener | one small file; color from spell |
| SF-130 | Phase 5 | BossWarning banner on wave 10 | remote exists, never fired |
| SF-131 | Phase 5 | First-join instruction card | "Survive 10 waves. Craft between waves. Press C." |
| SF-132 | Phase 5 | Confirm/implement crafting keybind toggle | verify key exists |
| SF-140 | Phase 6 | PT-001 solo full run | notes → docs/playtest/PT-001.md |
| SF-141 | Phase 6 | PT-002 duo full run | co-op split + revive visible |
| SF-142 | Phase 6 | PT-003 boss speedrun | verify boss pacing fun-not-tedious |
| SF-143 | Phase 6 | Balance tuning from PT evidence | wave counts, HP, pack costs |

### Playing next (playtest gate for current PRs)
| ID | Phase | Task | Notes |
|----|-------|------|-------|
| SF-100 | PR#1–3 | Studio playtest of merged stack | one session validates all three checklists |

---

## Done

| ID | Date | Phase | Task | Result | Evidence |
|----|------|-------|------|--------|----------|
| SF-090 | 2026-10-10 | PR#1 | Gameloop audit + fix branch created | 7 dead-wire bugs found & fixed | commit dc0d43e |
| SF-091 | 2026-10-10 | PR#1 | Repo branch structure mapped (default branch fossil) | documented; PRs target master | audit notes |
| SF-092 | 2026-10-10 | Plan | PROTOTYPE_PLAN.md written (6 phases, criteria, gaps G1–G9) | committed in PR #1 | commit dccd30d |
| SF-093 | 2026-10-10 | Phase 1 | Run integrity implementation | 149+/23- across 4 files + new RunResultsUI | PR #2 |
| SF-094 | 2026-10-10 | Phase 1 | Self-review fixes (5 defects caught pre-commit) | inflated kills, solo-death results screen, wave stats, stale cooldowns, post-defeat wave fire | PR #2 review notes |
| SF-095 | 2026-10-10 | Phase 2 | Server-truth inventory + InventorySync | FragmentInventory authoritative, auto-sync | PR #3 |
| SF-096 | 2026-10-10 | Phase 2 | AssembleSpell economy gate (validate + deduct + reject reasons) | crafting free rides end | PR #3 |
| SF-097 | 2026-10-10 | Phase 2 | Shop integrity (generate-then-spend + ShopResult) | empty pack never eats crystals | PR #3 |
| SF-098 | 2026-10-10 | Phase 2 | Fragment persistence + starter kit | DataStore round-trip + first-join grant | PR #3 |
| SF-101 | 2026-10-11 | PR#1 | Gameloop fix merged | 7 dead-wire bugs closed | PR #1 merged (e6f81e3) |
| SF-102 | 2026-10-11 | Phase 1 | Run integrity merged | results screen, Play Again, restart-safe systems, kill credit | PR #2 merged (b9d3ba7) |
| SF-103 | 2026-10-11 | Phase 2 | Economy server-truth merged | inventory gate, craft deduct, pack integrity, InventorySync | PR #3 merged (fbe0369) |
| SF-110 | 2026-10-11 | Phase 3 | Meta persistence merged | run stats wire (recordRunCompletion was dead code), spell recipe save + free rejoin re-equip, isBest unlock callout | PR #4 merged (66f5edd) |
| SF-111 | 2026-10-11 | Phase 3 | Max HP upgrade merged | 150💎 one-time, BuyMaxHP remote, owned-state UI, failure reasons | PR #4 merged (66f5edd) |
| PT-001 | 2026-10-11 | Harness | Automated smoke test PASS via Studio MCP | core loop verified live: spawn→attack→12 kills→102💎→wave-3 defeat→results UI; 3 bugs caught+fixed (adfc10f, 1949b76, f6f4e28); evidence docs/playtest/PT-001.md + 3 captures | PR #5 |

---

## Content Expansion (Phases 7–10 — locked 2026-10-11, start only after Phase 6 milestone)

| ID | Phase | Task | Notes |
|----|-------|------|-------|
| SF-200 | Phase 7 | Power ladder v2: rename to Spark/Blast/SuperNova/Megaton, add Megaton ×4.0 tier | old IDs → new IDs compat map; nobody loses fragments |
| SF-201 | Phase 7 | Migrate FragmentData.Powers to universal 4-tier ladder (all 12 elements) | powers become element-agnostic names |
| SF-210 | Phase 8 | Water element: core + 3 shapes + 4 powers + 2 modifiers, soak/slow damage type | tidal surge modifier |
| SF-211 | Phase 8 | Wind element: swirl, gale (knockback) | reposition enemies |
| SF-212 | Phase 8 | Earth element: stagger, quake (AoE stun) | |
| SF-213 | Phase 8 | Metal element: shred (armor-pierce %), magnetize (pull) | |
| SF-214 | Phase 8 | ElementData/FragmentData data-entry + crafting UI renders new elements | pool ≥ 100 frags |
| SF-220 | Phase 9 | Rarity 2.0: Mythic (×4.5, ~1/12k) + Prismatic (×6.0, ~1/250k) fragments | unique VFX colors, collection badges |
| SF-221 | Phase 9 | Luck stat: victory streaks +0.1× (capped), Fortune Charm consumable, co-op bonus | earned-only; displayed odds |
| SF-222 | Phase 9 | 4-slot rarity contribution → spell tier badge (Common → Prismatic) | dupes upgrade builds |
| SF-230 | Phase 10 | Light element: blind (miss chance), radiance (heal on kill) | |
| SF-231 | Phase 10 | Void element: decay (max-HP damage), singularity (pull + DoT) | tank/boss counter |

---

## Blockers

**None active.** Watch items:
- ⏳ Studio playtest pending for PRs #1–#3 (Ema runs Studio; Mac mini can't — house known constraint SF-C1)
- ⏳ Repo default branch is the fossil `feature/spellforge-m1-wave-defense` — suggest switching default to `master` post-merge
- ⏳ PAT rotation reminder from system-sweep session (not Spellforge-scoped)

---

## Archive

| ID | Date | Task | Result |
|----|------|------|--------|
| SF-001 | 2026-05-08 | Core systems built | 21 files, forge + defend |
| SF-002 | 2026-05-08 | Git synced | Mac + Windows + GitHub |
| SF-003 | 2026-05-08 | Balance v2 branch | feature/balance-v2 |
| SF-004 | ~2026-06-05 | Balance pass | SUPERSEDED → Phase 6 of prototype plan |

### Constraints
- **SF-C1** Roblox Studio + playtests run on Ema's machine only; agent validates by code review + static checks
- **SF-C2** Playtest notes mandatory per run → `docs/playtest/PT-NNN.md`
- **SF-C3** House rule: every feature tested before moving to the next
