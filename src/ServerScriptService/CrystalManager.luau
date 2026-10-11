-- CrystalManager.luau — Crystal currency with shop purchases and healing
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local CrystalManager = {}
CrystalManager.__index = CrystalManager

function CrystalManager.new()
	local self = setmetatable({}, CrystalManager)
	self.fragmentDropper = nil
	self.fragmentInventory = nil -- set via setFragmentInventory (Phase 2: server truth)
	return self
end

function CrystalManager:setFragmentInventory(fragmentInventory: any)
	self.fragmentInventory = fragmentInventory
end

function CrystalManager:setFragmentDropper(fragmentDropper: any)
	self.fragmentDropper = fragmentDropper
end

function CrystalManager:awardCrystals(player: Player, amount: number)
	local current = player:GetAttribute("Crystals") or 0
	player:SetAttribute("Crystals", current + amount)
	Remotes.UpdateHUD:FireClient(player, {
		crystals = current + amount,
	})
end

function CrystalManager:spendCrystals(player: Player, amount: number): boolean
	local current = player:GetAttribute("Crystals") or 0
	if current < amount then
		return false -- not enough crystals
	end
	player:SetAttribute("Crystals", current - amount)
	Remotes.UpdateHUD:FireClient(player, {
		crystals = current - amount,
	})
	return true
end

function CrystalManager:getCrystals(player: Player): number
	return player:GetAttribute("Crystals") or 0
end

-- Heal the player using crystals
function CrystalManager:healPlayer(player: Player): boolean
	local crystals = player:GetAttribute("Crystals") or 0
	if crystals < Config.CRYSTAL_HEAL_COST then
		return false
	end

	local hp = player:GetAttribute("HP") or 0
	local maxHP = player:GetAttribute("MaxHP") or 100
	if hp >= maxHP then
		return false -- already full
	end

	-- Spend crystals
	player:SetAttribute("Crystals", crystals - Config.CRYSTAL_HEAL_COST)

	-- Heal
	local newHP = math.min(hp + Config.CRYSTAL_HEAL_AMOUNT, maxHP)
	player:SetAttribute("HP", newHP)

	Remotes.UpdateHUD:FireClient(player, {
		hp = newHP,
		maxHP = maxHP,
		crystals = crystals - Config.CRYSTAL_HEAL_COST,
	})

	return true
end

-- Buy a fragment pack: validate → spend once → generate → record to server inventory
function CrystalManager:buyPack(player: Player, packType: string): { any }?
	local packConfig = Config.CRYSTAL_PACKS[packType]
	if not packConfig then
		warn("[CrystalManager] Unknown pack type: " .. tostring(packType))
		return nil
	end

	if not self.fragmentDropper then
		warn("[CrystalManager] No dropper wired; refusing purchase")
		return nil
	end

	-- Generate FIRST, then spend — an empty pack can never eat crystals
	local fragments = self.fragmentDropper:generatePack(packType)
	if #fragments == 0 then
		return nil
	end

	if not self:spendCrystals(player, packConfig.cost) then
		return nil -- not enough crystals
	end

	if self.fragmentInventory then
		for _, frag in fragments do
			if frag and frag.id then
				self.fragmentInventory:addFragment(player, frag.id, 1)
			end
		end
	end

	return fragments
end

-- Initialize player data
function CrystalManager:initPlayer(player: Player)
	player:SetAttribute("Crystals", 0)
	player:SetAttribute("HP", Config.WIZARD_START_HP)
	player:SetAttribute("MaxHP", Config.WIZARD_START_HP)
end

-- Setup remote handlers
function CrystalManager:setupRemotes()
	Remotes.BuyPack.OnServerEvent:Connect(function(player: Player, packType: string)
		if typeof(packType) ~= "string" then return end
		if not Config.CRYSTAL_PACKS[packType] then return end

		local packConfig = Config.CRYSTAL_PACKS[packType]
		local fragments = self:buyPack(player, packType)
		if fragments then
			for _, frag in fragments do
				Remotes.FragmentReceived:FireClient(player, frag)
			end
			Remotes.ShopResult:FireClient(player, true, {
				pack = packType,
				cost = packConfig.cost,
				fragments = #fragments,
			})
		else
			local reason = self:getCrystals(player) < packConfig.cost and "not_enough_crystals" or "unavailable"
			Remotes.ShopResult:FireClient(player, false, {
				pack = packType,
				cost = packConfig.cost,
				reason = reason,
			})
		end
	end)
end

return CrystalManager