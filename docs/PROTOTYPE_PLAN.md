# Spellforge → Playable Prototype Plan

**Goal:** from current state to a game that runs beginning-to-end: join → survive 10 waves → boss → victory → play again, with an honest economy and persistence.

**Last updated:** 2026-10-10
**Prerequisite:** PR #1 (`feature/simple-gameloop`) merges first — it fixes the 7 dead-wire bugs that block the loop entirely.

---

## Current State (audited 2026-10-10)

**Works (server-side):** wave composition 1–10, boss spawn + stomp/crystal-rain, auto-attack combat (after PR #1), enemy movement/repath, crystals per kill/wave, rest phase with ready-up, spell assembly computation, co-op crystal split, HUD/rest/crafting UIs, DataStore save of crystals.

**Broken or missing (blocks "beginning to end"):**

| # | Gap | Severity |
|---|-----|----------|
| G1 | No run end-state: victory/defeat fires a HUD text only — no results screen, no restart path, `start()` can't be called again (loops die) | 🔴 blocks "end" |
| G2 | Fragment economy has no server truth: fragments are client-echo only; `FragmentInventory` instantiated never used; `AssembleSpell` validates ownership of nothing and deducts nothing — crafting is free and infinite | 🔴 economy hole |
| G3 | Persistence saves crystals only — fragments/spells/bestWave lost between sessions | 🟡 prototype-blocker-lite |
| G4 | No initial fragment grant: new players have 0 fragments; starter spell is hardcoded (fine) but crafting is unreachable until first drops | 🟡 UX |
| G5 | No client sync of full inventory on join/rejoin (client table starts empty) | 🟡 UX |
| G6 | No arena walls — wizards/enemies can walk off platform edge into void | 🟡 feel |
| G7 | `BossWarning` + `ShopResult` remotes exist but are never fired/consumed | 🟢 polish |
| G8 | `EnemySpawner:spawnWave` (v1 dead code) unused — WaveSystem has its own | 🟢 cleanup |
| G9 | `SwapFragment`/`EquipSpell` remotes defined, unimplemented (single-equipped-spell only) | 🟢 M2 scope |

---

## Phases

### Phase 0 — Land the loop fix (PR #1)
- Review + merge `feature/simple-gameloop` (7 dead-wire fixes).
- **Exit:** Studio playtest — wave 1 completes, crystals awarded, no server errors.

### Phase 1 — Run integrity: end → restart (fixes G1, G6)
The run needs a real ending and a clean "again."
- `WaveSystem:reset()` — full run-state teardown (enemies, combatState, readyPlayers) and re-`start()`.
- Restart-safe loops: attack/enemy/boss loops become per-run (`start()` owns them) instead of spawned once in GameInit.
- Results screen (client): victory/defeat panel — wave reached, kills, crystals earned — with **Play Again**; on all-players-ready or host click, server resets and restarts.
- Invisible arena walls (4 parts, platform edge).
- **Exit:** playtest — full solo run to victory, then Play Again → second full run works. Defeat path also restarts clean.

### Phase 2 — Economy integrity (fixes G2, G5, G7)
Make fragments real before persistence trusts them.
- Server inventory wiring: every fragment source (`dropForKill`, `dropForWave`, `generatePack`) calls `fragmentInventory:addFragment` — server table is truth.
- `AssembleSpell`: validate `hasAllFragments`, deduct on success; reject silently-bad recipes with a client-visible reason.
- New `InventorySync` remote: full `{id=count}` table fired on join and after every change (replaces incremental-only echo).
- `ShopResult` fired on pack purchase success/failure; client consumes (toast/refund feedback).
- **Exit:** buy pack → craft → fragments deducted; dropping below required count blocks assembly. Two clients see identical inventories after trade-free co-op kills. (Playtest PT-001/PT-002 notes.)

### Phase 3 — Persistence + starter grant (fixes G3, G4)
- `DataManager`: serialize fragments, spells (owned spell ids), equippedSpell, totalKills, bestWave; restore on join.
- First-join grant: starter 4 fragments (`fire_element`, `fire_shape_bolt`, `fire_power_ember`, `fire_mod_split`) so crafting is immediately usable.
- Between-run meta: rest-shop "Max HP upgrade" entry (the `maxHPUnlocked` flag exists, unwired) — cost crystals.
- **Exit:** rejoin the game → fragments/spells/bestWave intact. Fresh account gets starter kit.

### Phase 4 — Combat feel (light, optional-in-parallel)
- `SpellFired` client VFX: simple projectile part (wizard → target, tween, color from spell) — one small file. Combat becomes visible/readable.
- Wraith: repath loop already walks them into melee range; leave "ranged" as flavor for now (data-only). Real projectiles = M2.
- **Exit:** watching wave 2 makes sense without reading logs.

### Phase 5 — Onboarding glue (fixes G7)
- Boss warning banner on wave 10 start (`BossWarning` finally fired).
- First-join instruction card: "Survive 10 waves. Craft spells between waves. Press C." (keybind toggle for SpellforgeUI; confirm the existing toggle key, add if missing).
- **Exit:** a new player can complete their first run unassisted.

### Phase 6 — Balance + playtest to prototype-done
- PT-001 solo full run / PT-002 duo run / PT-003 boss speedrun — notes in `docs/playtest/PT-NNN.md` per house rule.
- Tune from evidence: wave enemy counts, walker HP (25 feels right vs 8 dmg), pack costs vs crystal income (~15×wave/run), boss 500hp single-player (~1.6min — verify it's fun not tedious).
- **Exit:** two consecutive playtests with zero crashers → prototype complete.

### Deliberately out of scope (post-prototype)
- Wraith projectiles, spell equipping/swap UI (G9 — M2), CoopLobby/FragmentScreen stubs, audio, map art, monetization, DataStore versioning/migrations.

---

## Dependency chain

```
PR #1 (loop fix) ──► Phase 1 (run integrity) ──► Phase 2 (economy) ──► Phase 3 (persistence)
                                                        │
                                                        └──► Phase 4 (VFX, parallel) ──► Phase 5 (onboarding) ──► Phase 6 (balance/playtest)
```

## Suggested branches / PRs
- `fix/run-integrity` (Phase 1)
- `feat/economy-server-truth` (Phase 2)
- `feat/persistence-and-starter-kit` (Phase 3)
- `feat/spell-vfx` (Phase 4)
- `feat/onboarding-glue` (Phase 5)
- One PR per phase, each playtested before merge (house rule: every feature tested before the next task).