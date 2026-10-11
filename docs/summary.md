# Spellforge — Project Summary

**Last Updated:** 2026-06-05
**Status:** Mid-Development (★★★ — 60% there, 15-18 files needed)
**Genre:** Tower Defense / Spell Crafting
**GitHub:** github.com/emaharmony/Spellforge
**Mac Repo:** /Users/ema/projects/repos/Spellforge
**Windows Path:** D:\Projects\Roblox\Spellforge
**Rojo Port:** 34877
**Branch:** feature/balance-v2

---

## Game Overview

Spell crafting tower defense — collect fragments, forge spells, defend crystals against waves. Cooperative multiplayer with wave system and elemental combat.

### Architecture
- **21 Luau files**, 156K total
- Server: GameInit, WaveSystem, CombatEngine, SpellAssembler, FragmentDropper, CrystalManager, FragmentInventory, CoopManager, DataManager, EnemySpawner
- Client: SpellforgeUI, DefenseHUD, WaveRestUI
- Shared: Config, Remotes, ElementData, EnemyData, FragmentData
- Rich data: elements, fragments, enemies, spell combinations
- Nested default.project.json (src subdir)

### Current State
- 60% complete per portfolio evaluation
- Wave system + spell crafting functional
- Fragment collection + inventory working
- Crystal defense mechanic implemented
- Coop framework started
- Missing: balance pass (on feature/balance-v2 branch), multiplayer polish, more enemies, audio

---

## Milestones

| Phase | Status |
|-------|--------|
| Core loop (forge + defend) | ✅ Working |
| Wave system | ✅ Working |
| Spell assembly | ✅ Working |
| Fragment collection | ✅ Working |
| Crystal defense | ✅ Working |
| Cooperative framework | ⚠️ Started |
| Balance pass | 🔄 In progress (balance-v2 branch) |
| More enemies + content | ❌ Not started |
| Audio/VFX | ❌ Not started |
| Publish | ❌ Not started |