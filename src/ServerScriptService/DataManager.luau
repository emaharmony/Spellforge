-- DataManager.luau — Data persistence for Spellforge (DataStore)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local MAX_HP_UPGRADE_COST = 150 -- Phase 3 SF-111: one-time 120 HP upgrade

local Remotes_MaxHPChanged = Remotes.MaxHPChanged

local DataManager = {}
DataManager.__index = DataManager

function DataManager.new()
	local self = setmetatable({}, DataManager)
	-- Unpublished/local places can't access DataStore ("You must publish
	-- this place..."). Fall back to session-only persistence instead of
	-- killing the whole server init chain.
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("SpellforgePlayerData")
	end)
	self.store = ok and store or nil
	if not self.store then
		warn("[Spellforge] DataManager: DataStore unavailable — running session-only (progress will not survive restarts)")
	end
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

	local success, data = false, nil
	if self.store then
		success, data = pcall(function()
			return self.store:GetAsync(key)
		end)
	end

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
	if self.getFragmentsSnapshot then
		-- Phase 2: fragments persist from the server-truth inventory
		local snapshot = self.getFragmentsSnapshot(player)
		if snapshot then
			data.fragments = snapshot
		end
	end

	if not self.store then return end
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
function DataManager:recordRunCompletion(player: Player, wavesCompleted: number, victory: boolean, kills: number?)
	local data = self.cache[player.UserId]
	if not data then return end

	data.totalRuns += 1
	data.totalWavesCompleted += wavesCompleted
	if wavesCompleted > data.bestWave then
		data.bestWave = wavesCompleted
	end
	if kills and kills > 0 then
		data.totalKills += kills
	end
	if victory then
		data.bossesDefeated += 1
	end

	-- Unlock 120 HP after first full run
	if victory and not data.maxHPUnlocked then
		data.maxHPUnlocked = true
		player:SetAttribute("MaxHP", 120)
		Remotes_MaxHPChanged:FireClient(player, true)
	end

	self:saveData(player)
end

-- Purchase the one-time Max HP upgrade (Phase 3 SF-111).
-- Returns true on success; false + reason on failure.
function DataManager:buyMaxHPUpgrade(player: Player): (boolean, string?)
	local data = self.cache[player.UserId]
	if not data then return false, "no_data" end
	if data.maxHPUnlocked then
		return false, "already_owned"
	end

	local crystals = player:GetAttribute("Crystals") or 0
	if crystals < MAX_HP_UPGRADE_COST then
		return false, "not_enough_crystals"
	end

	player:SetAttribute("Crystals", crystals - MAX_HP_UPGRADE_COST)
	data.maxHPUnlocked = true
	player:SetAttribute("MaxHP", 120)

	self:saveData(player)
	return true
end

-- Clean up on player leave
function DataManager:onPlayerRemoving(player: Player)
	self:saveData(player)
	self.cache[player.UserId] = nil
end

-- Spell persistence (Phase 3 SF-110): store the equipped spell's recipe
-- (fragmentIds) so rejoin can rebuild it without re-charging fragments.
function DataManager:saveEquippedSpell(player: Player, spell: any)
	local data = self.cache[player.UserId]
	if not data then return end
	if spell and typeof(spell.fragmentIds) == "table" and #spell.fragmentIds == 4 then
		data.equippedSpell = { fragmentIds = spell.fragmentIds, id = spell.id }
	else
		data.equippedSpell = nil
	end
	self:saveData(player)
end

function DataManager:getBestWave(player: Player): number
	local data = self.cache[player.UserId]
	if not data then return 0 end
	return data.bestWave or 0
end

function DataManager:getSavedSpell(player: Player): any?
	local data = self.cache[player.UserId]
	if not data or not data.equippedSpell then return nil end
	local saved = data.equippedSpell
	if typeof(saved) == "table" and typeof(saved.fragmentIds) == "table" and #saved.fragmentIds == 4 then
		return saved.fragmentIds
	end
	return nil
end

return DataManager