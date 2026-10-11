-- Config.luau — Game constants for Spellforge (v2 — Balanced Game Loop)
local Config = {}

-- Game
Config.GAME_NAME = "Spellforge"
Config.MAX_PLAYERS = 4
Config.PLATFORM_SIZE = 100
Config.TOTAL_WAVES = 10
Config.WAVE_REST_TIME = 15 -- seconds between waves (crafting/shop time)

-- Wizard
Config.WIZARD_SPEED = 16
Config.WIZARD_START_HP = 100
Config.WIZARD_MAX_HP = 120 -- after first full run upgrade
Config.WIZARD_REGEN_OOC = 2 -- HP per second out of combat
Config.WIZARD_REGEN_IC = 0 -- HP per second in combat
Config.CRYSTAL_HEAL_COST = 20
Config.CRYSTAL_HEAL_AMOUNT = 30

-- Spells (v2 damage curve)
Config.SPELL_BASE_DAMAGE = 8 -- base, multiplied by power/shape/rarity
Config.SPELL_BASE_RANGE = 50
Config.SPELL_BASE_COOLDOWN = 1.5
Config.SPELL_CAST_RANGE = 60

-- Shape multipliers (affects damage per hit, some shapes hit multiple times)
Config.SHAPE_MULTIPLIERS = {
	bolt = { damage = 1.0, cooldown = 1.0, range = 1.0, description = "Single projectile" },
	nova = { damage = 0.6, cooldown = 1.5, range = 0.5, description = "Area explosion around wizard" },
	beam = { damage = 0.4, cooldown = 0.8, range = 1.5, ticks = 3, description = "Continuous beam (3 ticks)" },
	orbit = { damage = 0.5, cooldown = 2.0, range = 0.7, projectiles = 2, description = "Orbiting projectiles (×2)" },
	chain = { damage = 0.7, cooldown = 1.2, range = 0.8, bounces = 3, description = "Bounces between enemies (×3)" },
}

-- Fragments
Config.FRAGMENT_SLOTS = { "shape", "element", "power", "modifier" }
Config.FRAGMENTS_PER_SPELL = 4

-- Fragment drop rates (per kill)
Config.FRAGMENT_DROP_CHANCE = 0.05 -- 5% per kill
Config.FRAGMENT_DROP_PER_WAVE = 2 -- guaranteed fragments per wave completion

-- Pity system
Config.PITY_UNCOMMON_AFTER = 5 -- waves without uncommon+, next drop guaranteed uncommon+
Config.PITY_RARE_AFTER = 10 -- waves without rare, next drop guaranteed rare

-- Crystal economy
Config.CRYSTAL_PER_WAVE_BASE = 15 -- base crystals per wave
Config.CRYSTAL_PER_WAVE_MULTIPLIER = 1.0 -- × wave# (wave 1 = 15, wave 5 = 75, wave 10 = 150)
Config.CRYSTAL_PER_KILL = {
	common = 1,
	uncommon = 2,
	rare = 3,
	epic = 5,
	legendary = 10,
	boss = 50,
}

-- Crystal shop
Config.CRYSTAL_PACKS = {
	minor = { cost = 50, fragments = 3, minRarity = "uncommon", description = "3 fragments, guaranteed uncommon+" },
	major = { cost = 150, fragments = 5, minRarity = "rare", description = "5 fragments, guaranteed rare+" },
}

-- Rarity weights (for drops)
Config.RARITY_WEIGHTS = {
	common = 55,
	uncommon = 28,
	rare = 12,
	epic = 4,
	legendary = 1,
}

Config.RARITY_MULTIPLIERS = {
	common = 1.0,
	uncommon = 1.5,
	rare = 2.5,
	epic = 3.5,
	legendary = 5.0,
}

-- Enemies (v2 — rebalanced)
Config.ENEMY_WALK_SPEED = 8
Config.ENEMY_ATTACK_RANGE = 5
Config.ENEMY_ATTACK_DAMAGE = 5
Config.ENEMY_ATTACK_COOLDOWN = 1.0

-- Wave composition (10 waves)
Config.WAVE_COMPOSITION = {
	{ wave = 1, enemies = { walker = 3 }, description = "First stand" },
	{ wave = 2, enemies = { walker = 4, runner = 1 }, description = "Speed arrives" },
	{ wave = 3, enemies = { walker = 4, runner = 2, tank = 1 }, description = "Iron test" },
	{ wave = 4, enemies = { walker = 3, runner = 4, tank = 1 }, description = "Swarm pressure" },
	{ wave = 5, enemies = { walker = 4, runner = 2, wraith = 2 }, description = "Ranged threat" },
	{ wave = 6, enemies = { walker = 5, runner = 3, tank = 2, wraith = 1 }, description = "Sustained assault" },
	{ wave = 7, enemies = { spider = 6, wraith = 2 }, description = "Spider swarm" },
	{ wave = 8, enemies = { walker = 4, runner = 3, tank = 3, wraith = 2 }, description = "Iron gauntlet" },
	{ wave = 9, enemies = { walker = 3, runner = 2, tank = 2, wraith = 4, spider = 4 }, description = "All in" },
	{ wave = 10, enemies = { boss = 1 }, description = "Amber Colossus", isBoss = true },
}

-- Boss config
Config.BOSS = {
	name = "Amber Colossus",
	hp = 500,
	hpPerExtraPlayer = 250, -- +250 HP per player beyond 1
	damage_stomp = 15,
	damage_rain = 8,
	rain_projectiles = 4,
	stomp_range = 10,
	rain_range = 20,
	stomp_cooldown = 3,
	rain_cooldown = 5,
	crystal_reward = 50,
	speed = 6,
	size = Vector3.new(8, 12, 8),
	color = Color3.fromRGB(255, 193, 7),
}

-- Co-op
Config.COOP_CRYSTAL_SPLIT = { killer = 0.7, others = 0.3 } -- 70% to killer, 30% split among others
Config.COOP_REVIVE_TIME = 3 -- seconds standing near fallen ally
Config.COOP_REVIVE_HP = 0.5 -- revive at 50% HP

-- Elemental combos
Config.ELEMENTAL_COMBOS = {
	{ elements = { "fire", "ice" }, name = "Steam", damageMultiplier = 2.0, duration = 2 },
	{ elements = { "fire", "nature" }, name = "Wildfire", damageMultiplier = 1.5, duration = 3 },
	{ elements = { "ice", "lightning" }, name = "Thunderstorm", damageMultiplier = 1.8, duration = 2 },
	{ elements = { "shadow", "arcane" }, name = "Void Storm", damageMultiplier = 2.2, duration = 2 },
	{ elements = { "nature", "lightning" }, name = "Overgrowth", damageMultiplier = 1.5, duration = 4 },
	{ elements = { "fire", "shadow" }, name = "Dark Flame", damageMultiplier = 1.7, duration = 3 },
}

-- Wave rest UI
Config.WAVE_REST_SHOW_RESULTS = true
Config.WAVE_REST_SHOW_SHOP = true
Config.WAVE_REST_SHOW_CRAFTING = true
Config.WAVE_REST_READY_UP = true

-- Deprecated (kept for backward compat, use WAVE_COMPOSITION instead)
Config.WAVE_COUNT = 10
Config.WAVE_BASE_ENEMIES = 4
Config.WAVE_ENEMY_INCREMENT = 2
Config.CRYSTAL_PER_WAVE = 10
Config.CRYSTAL_PER_KILL_OLD = 1

return Config