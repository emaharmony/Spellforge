-- CoopManager.luau — Co-op coordination: shared crystals, revives, elemental combos
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local CoopManager = {}
CoopManager.__index = CoopManager

function CoopManager.new()
	local self = setmetatable({}, CoopManager)
	self.activeCombos = {} -- combo id -> { players, element1, element2, endTime }
	self.reviveProgress = {} -- target player id -> { reviver, progress, startTime }
	self.playerElements = {} -- player id -> element
	return self
end

-- Set a player's current element
function CoopManager:setPlayerElement(player: Player, element: string)
	self.playerElements[player.UserId] = element
	self:checkCombo(player)
end

-- Check if any elemental combo is triggered
function CoopManager:checkCombo(player: Player)
	local playerElement = self.playerElements[player.UserId]
	if not playerElement then return end

	for otherUserId, otherElement in self.playerElements do
		if otherUserId ~= player.UserId then
			-- Check if these two elements form a combo
			local combo = self:findCombo(playerElement, otherElement)
			if combo then
				self:activateCombo(player.UserId, otherUserId, combo)
			end
		end
	end
end

-- Find a combo between two elements
function CoopManager:findCombo(element1: string, element2: string): any?
	for _, combo in Config.ELEMENTAL_COMBOS do
		local e1, e2 = combo.elements[1], combo.elements[2]
		if (element1 == e1 and element2 == e2) or (element1 == e2 and element2 == e1) then
			return combo
		end
	end
	return nil
end

-- Activate an elemental combo
function CoopManager:activateCombo(player1Id: number, player2Id: number, combo: any)
	local comboId = player1Id .. "_" .. player2Id

	-- Don't re-activate if already active
	if self.activeCombos[comboId] then return end

	self.activeCombos[comboId] = {
		players = { player1Id, player2Id },
		name = combo.name,
		damageMultiplier = combo.damageMultiplier,
		endTime = tick() + combo.duration,
	}

	-- Notify clients
	Remotes.ElementalCombo:FireAllClients(combo.name, combo.damageMultiplier, combo.duration)

	-- Auto-expire after duration
	task.delay(combo.duration, function()
		self.activeCombos[comboId] = nil
	end)
end

-- Check if a player has an active combo bonus
function CoopManager:getComboMultiplier(playerId: number): number
	local multiplier = 1.0
	for _, combo in self.activeCombos do
		for _, id in combo.players do
			if id == playerId then
				multiplier = math.max(multiplier, combo.damageMultiplier)
			end
		end
	end
	return multiplier
end

-- Start reviving a fallen ally
function CoopManager:startRevive(reviver: Player, target: Player)
	self.reviveProgress[target.UserId] = {
		reviver = reviver,
		progress = 0,
		startTime = tick(),
	}
end

-- Update revive progress (called every frame)
function CoopManager:updateRevives(dt: number)
	local completed = {}

	for targetId, revive in self.reviveProgress do
		revive.progress += dt / Config.COOP_REVIVE_TIME

		if revive.progress >= 1.0 then
			-- Revive complete
			local targetPlayer = game.Players:GetPlayerByUserId(targetId)
			if targetPlayer then
				local maxHP = targetPlayer:GetAttribute("MaxHP") or 100
				local reviveHP = math.floor(maxHP * Config.COOP_REVIVE_HP)
				targetPlayer:SetAttribute("HP", reviveHP)
				Remotes.UpdateHUD:FireClient(targetPlayer, {
					hp = reviveHP,
					maxHP = maxHP,
				})
			end
			table.insert(completed, targetId)
		end
	end

	for _, id in completed do
		self.reviveProgress[id] = nil
	end
end

-- Cancel revive if reviver moves away
function CoopManager:cancelRevive(targetId: number)
	self.reviveProgress[targetId] = nil
end

-- Get revive progress for a target
function CoopManager:getReviveProgress(targetId: number): number
	local revive = self.reviveProgress[targetId]
	if not revive then return 0 end
	return revive.progress
end

-- Reset per-run state
function CoopManager:reset()
	self.activeCombos = {}
	self.reviveProgress = {}
	self.playerElements = {}
end

return CoopManager