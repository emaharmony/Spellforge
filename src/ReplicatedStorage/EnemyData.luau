-- EnemyData.luau — 5 enemy types + boss for v2 balanced game loop
local Config = require(game.ReplicatedStorage:WaitForChild("Config"))

local EnemyData = {}

EnemyData.Types = {
	walker = {
		id = "walker",
		name = "Shadow Walker",
		hp = 25,
		speed = 8,
		damage = 4,
		attackRange = 5,
		attackCooldown = 1.0,
		crystalDrop = 1,
		rarity = "common",
		color = Color3.fromRGB(80, 80, 100),
		size = Vector3.new(3, 5, 3),
		description = "Slow but steady, walks toward wizard",
	},

	runner = {
		id = "runner",
		name = "Glow Sprinter",
		hp = 12,
		speed = 16,
		damage = 3,
		attackRange = 4,
		attackCooldown = 0.8,
		crystalDrop = 1,
		rarity = "common",
		color = Color3.fromRGB(255, 100, 150),
		size = Vector3.new(2, 4, 2),
		description = "Fast and fragile, reaches wizard quickly",
	},

	tank = {
		id = "tank",
		name = "Stone Golem",
		hp = 100,
		speed = 4,
		damage = 12,
		attackRange = 6,
		attackCooldown = 2.0,
		crystalDrop = 5,
		rarity = "uncommon",
		color = Color3.fromRGB(100, 100, 110),
		size = Vector3.new(5, 7, 5),
		description = "Slow and tough, takes many hits",
	},

	wraith = {
		id = "wraith",
		name = "Void Wraith",
		hp = 40,
		speed = 10,
		damage = 6,
		attackRange = 8,
		attackCooldown = 1.5,
		crystalDrop = 3,
		rarity = "uncommon",
		color = Color3.fromRGB(150, 50, 200),
		size = Vector3.new(2.5, 5, 2.5),
		isRanged = true,
		projectileSpeed = 40,
		projectileColor = Color3.fromRGB(180, 80, 255),
		description = "Ranged attacker, fires dark bolts at wizard",
	},

	spider = {
		id = "spider",
		name = "Crystal Spider",
		hp = 15,
		speed = 14,
		damage = 2,
		attackRange = 3,
		attackCooldown = 0.6,
		crystalDrop = 2,
		rarity = "common",
		color = Color3.fromRGB(0, 230, 180),
		size = Vector3.new(2, 2, 2),
		swarmBonus = true, -- spawns in groups, each drops crystals
		description = "Fast swarm enemy, dangerous in groups",
	},

	boss = {
		id = "boss",
		name = Config.BOSS.name,
		hp = Config.BOSS.hp,
		speed = Config.BOSS.speed,
		damage = Config.BOSS.damage_stomp,
		attackRange = Config.BOSS.stomp_range,
		attackCooldown = Config.BOSS.stomp_cooldown,
		crystalDrop = Config.BOSS.crystal_reward,
		rarity = "epic",
		color = Config.BOSS.color,
		size = Config.BOSS.size,
		isBoss = true,
		description = "The Amber Colossus — final challenge",
	},
}

function EnemyData.GetById(id: string): any
	return EnemyData.Types[id]
end

function EnemyData.GetAll(): { string }
	local ids = {}
	for id, _ in EnemyData.Types do
		table.insert(ids, id)
	end
	return ids
end

-- Get wave composition by wave number (1-10)
function EnemyData.GetWaveComposition(waveNumber: number): any
	if waveNumber < 1 or waveNumber > #Config.WAVE_COMPOSITION then
		warn("[EnemyData] Invalid wave number: " .. waveNumber)
		return Config.WAVE_COMPOSITION[#Config.WAVE_COMPOSITION]
	end
	return Config.WAVE_COMPOSITION[waveNumber]
end

return EnemyData