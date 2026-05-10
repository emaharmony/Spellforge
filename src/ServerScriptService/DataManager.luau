-- DataManager.luau — Data persistence for Spellforge (DataStore)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataManager = {}
DataManager.__index = DataManager

function DataManager.new()
	local self = setmetatable({}, DataManager)
	self.store = DataStoreService:GetDataStore("SpellforgePlayerData")
	self.cache = {} -- player id -> data
	return self
end

-- Default data for new players
function DataManager.getDefaultData(): { [string]: any }
	return {
		crystals = 0,
		totalWavesCompleted = 0,
		totalRuns = 0,
		bestWave = 0,
		fragments = {}, -- { id = count }
		spells = {}, -- { spell id = true }
		equippedSpell = nil,
		maxHPUnlocked = false,
		totalKills = 0,
		bossesDefeated = 0,
		lastSave = os.time(),
	}
end

-- Load player data from DataStore
function DataManager:loadData(player: Player)
	local key = "player_" .. player.UserId

	local success, data = pcall(function()
		return self.store:GetAsync(key)
	end)

	if success and data then
		self.cache[player.UserId] = data
		-- Apply to player attributes
		player:SetAttribute("Crystals", data.crystals or 0)
		if data.maxHPUnlocked then
			player:SetAttribute("MaxHP", 120)
		else
			player:SetAttribute("MaxHP", 100)
		end
		return data
	else
		-- New player
		local default = DataManager.getDefaultData()
		self.cache[player.UserId] = default
		player:SetAttribute("Crystals", 0)
		player:SetAttribute("MaxHP", 100)
		return default
	end
end

-- Save player data to DataStore
function DataManager:saveData(player: Player)
	local data = self.cache[player.UserId]
	if not data then return end

	data.crystals = player:GetAttribute("Crystals") or 0
	data.lastSave = os.time()

	local key = "player_" .. player.UserId
	pcall(function()
		self.store:SetAsync(key, data)
	end)
end

-- Auto-save loop (every 30 seconds)
function DataManager:startAutoSave()
	task.spawn(function()
		while true do
			task.wait(30)
			for _, player in Players:GetPlayers() do
				self:saveData(player)
			end
		end
	end)
end

-- Update progress after a run
function DataManager:recordRunCompletion(player: Player, wavesCompleted: number, victory: boolean)
	local data = self.cache[player.UserId]
	if not data then return end

	data.totalRuns += 1
	data.totalWavesCompleted += wavesCompleted
	if wavesCompleted > data.bestWave then
		data.bestWave = wavesCompleted
	end

	-- Unlock 120 HP after first full run
	if victory and not data.maxHPUnlocked then
		data.maxHPUnlocked = true
		player:SetAttribute("MaxHP", 120)
	end

	self:saveData(player)
end

-- Clean up on player leave
function DataManager:onPlayerRemoving(player: Player)
	self:saveData(player)
	self.cache[player.UserId] = nil
end

return DataManager