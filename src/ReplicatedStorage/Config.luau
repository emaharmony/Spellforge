-- Config.luau — Game constants for Spellforge
local Config = {}

-- Game
Config.GAME_NAME = "Spellforge"
Config.MAX_PLAYERS = 4
Config.PLATFORM_SIZE = 100

-- Wizard
Config.WIZARD_SPEED = 16
Config.WIZARD_START_HP = 100
Config.WIZARD_REGEN_RATE = 1 -- HP per second out of combat

-- Spells
Config.SPELL_BASE_DAMAGE = 10
Config.SPELL_BASE_RANGE = 50
Config.SPELL_BASE_COOLDOWN = 1.5
Config.SPELL_CAST_RANGE = 60

-- Fragments
Config.FRAGMENT_SLOTS = { "shape", "element", "power", "modifier" }
Config.FRAGMENTS_PER_SPELL = 4

-- Enemies
Config.ENEMY_WALK_SPEED = 8
Config.ENEMY_ATTACK_RANGE = 5
Config.ENEMY_ATTACK_DAMAGE = 5
Config.ENEMY_ATTACK_COOLDOWN = 1.0

-- Waves
Config.WAVE_COUNT = 5
Config.WAVE_REST_TIME = 10 -- seconds between waves
Config.WAVE_BASE_ENEMIES = 4
Config.WAVE_ENEMY_INCREMENT = 2 -- extra enemies per wave

-- Crystals
Config.CRYSTAL_PER_WAVE = 10
Config.CRYSTAL_PER_KILL = 1

-- Rarity weights
Config.RARITY_WEIGHTS = {
    common = 60,
    uncommon = 25,
    rare = 10,
    epic = 4,
    legendary = 1,
}

Config.RARITY_MULTIPLIERS = {
    common = 1.0,
    uncommon = 1.3,
    rare = 1.6,
    epic = 2.0,
    legendary = 3.0,
}

return Config