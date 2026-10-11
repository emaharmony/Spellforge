-- FragmentDropper.luau — Fragment drops based on wave performance and kill stats
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))

local FragmentDropper = {}
FragmentDropper.__index = FragmentDropper

function FragmentDropper.new()
	local self = setmetatable({}, FragmentDropper)
	self.dryStreak = 0 -- waves without uncommon+
	self.rareDryStreak = 0 -- waves without rare
	self.playerKills = {} -- player id -> kill count
	self.playerWaves = {} -- player id -> waves survived
	self.elementBias = {} -- player id -> most used element
	return self
end

-- Track a kill for drop bias
function FragmentDropper:recordKill(player: Player, enemyRarity: string)
	if not self.playerKills[player.UserId] then
		self.playerKills[player.UserId] = 0
	end
	self.playerKills[player.UserId] += 1
end

-- Track element usage for fragment bias
function FragmentDropper:setElementBias(player: Player, element: string)
	self.elementBias[player.UserId] = element
end

-- Roll a random rarity using weighted distribution
function FragmentDropper._rollRarity(pityUncommon: boolean, pityRare: boolean): string
	if pityRare then
		return "rare"
	end
	if pityUncommon then
		-- 70% uncommon, 20% rare, 10% epic
		local roll = math.random(1, 100)
		if roll <= 70 then return "uncommon" end
		if roll <= 90 then return "rare" end
		return "epic"
	end

	local total = 0
	for _, weight in Config.RARITY_WEIGHTS do
		total += weight
	end

	local roll = math.random(1, total)
	local cumulative = 0
	for rarity, weight in Config.RARITY_WEIGHTS do
		cumulative += weight
		if roll <= cumulative then
			return rarity
		end
	end
	return "common"
end

-- Generate a random fragment of given rarity, biased toward player's element
function FragmentDropper._generateFragment(rarity: string, elementBias: string?): any
	local candidates = {}
	for _, frag in FragmentData.All do
		if frag.rarity == rarity or (rarity == "uncommon" and frag.rarity == "common") or (rarity == "rare" and (frag.rarity == "uncommon" or frag.rarity == "common")) or (rarity == "epic" and frag.rarity ~= "legendary") then
			-- Filter to at least the minimum rarity
			if frag.rarity == rarity or (rarity == "uncommon" and frag.rarity == "common") then
				-- Accept exact rarity or lower within band
			end
			-- For simplicity: filter to exact rarity, or include common if asking for uncommon+
			if frag.rarity == rarity then
				table.insert(candidates, frag)
			elseif rarity == "uncommon" and frag.rarity == "common" then
				table.insert(candidates, frag)
			end
		end
	end

	if #candidates == 0 then
		-- Fallback: any fragment
		for _, frag in FragmentData.All do
			table.insert(candidates, frag)
		end
	end

	-- Bias toward player's most-used element (2x weight)
	if elementBias then
		local biased = {}
		for _, frag in candidates do
			table.insert(biased, frag)
			if frag.element == elementBias then
				table.insert(biased, frag) -- double weight
			end
		end
		candidates = biased
	end

	return candidates[math.random(1, #candidates)]
end

-- Drop fragments for wave completion
function FragmentDropper:dropForWave(player: Player, waveNumber: number): { any }
	local drops = {}
	local pityUncommon = self.dryStreak >= Config.PITY_UNCOMMON_AFTER
	local pityRare = self.rareDryStreak >= Config.PITY_RARE_AFTER

	for i = 1, Config.FRAGMENT_DROP_PER_WAVE do
		local rarity = self._rollRarity(pityUncommon, pityRare)
		local fragment = self._generateFragment(rarity, self.elementBias[player.UserId])

		if fragment then
			table.insert(drops, fragment)
		end
	end

	-- Guarantee at least 1 fragment from the element used most
	if self.elementBias[player.UserId] and #drops > 0 then
		local biasElement = self.elementBias[player.UserId]
		local hasBiasElement = false
		for _, drop in drops do
			if drop.element == biasElement then
				hasBiasElement = true
				break
			end
		end
		if not hasBiasElement then
			-- Replace first drop with element-biased one
			local biasedFrags = FragmentData.GetByElement(biasElement)
			if #biasedFrags > 0 then
				drops[1] = biasedFrags[math.random(1, #biasedFrags)]
			end
		end
	end

	-- Update pity counters
	local gotUncommon = false
	local gotRare = false
	for _, drop in drops do
		if drop.rarity == "uncommon" or drop.rarity == "rare" or drop.rarity == "epic" or drop.rarity == "legendary" then
			gotUncommon = true
		end
		if drop.rarity == "rare" or drop.rarity == "epic" or drop.rarity == "legendary" then
			gotRare = true
		end
	end

	if gotUncommon then
		self.dryStreak = 0
	else
		self.dryStreak += 1
	end

	if gotRare then
		self.rareDryStreak = 0
	else
		self.rareDryStreak += 1
	end

	-- Track waves survived
	if not self.playerWaves[player.UserId] then
		self.playerWaves[player.UserId] = 0
	end
	self.playerWaves[player.UserId] += 1

	return drops
end

-- Roll for fragment drop on enemy kill (5% chance per kill)
function FragmentDropper:dropForKill(player: Player): any?
	if math.random() > Config.FRAGMENT_DROP_CHANCE then
		return nil
	end

	local rarity = self._rollRarity(false, false)
	return self._generateFragment(rarity, self.elementBias[player.UserId])
end

-- Generate pack fragments (for crystal shop)
function FragmentDropper:generatePack(packType: string): { any }
	local packConfig = Config.CRYSTAL_PACKS[packType]
	if not packConfig then
		warn("[FragmentDropper] Unknown pack type: " .. tostring(packType))
		return {}
	end

	local fragments = {}
	for i = 1, packConfig.fragments do
		local minRarity = packConfig.minRarity
		-- Last fragment is guaranteed min rarity, rest are random
		local rarity
		if i == packConfig.fragments then
			rarity = minRarity
		else
			-- Random roll, but at least common
			rarity = self._rollRarity(false, false)
		end
		local fragment = self._generateFragment(rarity, nil)
		if fragment then
			table.insert(fragments, fragment)
		end
	end

	return fragments
end

-- Reset per-run state
function FragmentDropper:reset()
	self.dryStreak = 0
	self.rareDryStreak = 0
	self.playerKills = {}
	self.playerWaves = {}
	self.elementBias = {}
end

return FragmentDropper