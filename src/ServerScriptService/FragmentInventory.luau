-- FragmentInventory.luau — Player fragment collection with slot tracking and lookup
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local FragmentInventory = {}
FragmentInventory.__index = FragmentInventory

function FragmentInventory.new()
	local self = setmetatable({}, FragmentInventory)
	self.inventories = {} -- player id -> { fragmentId = count }
	self.equippedSpells = {} -- player id -> spell data
	return self
end

function FragmentInventory:getFragments(player: Player): { [string]: number }
	return self.inventories[player.UserId] or {}
end

function FragmentInventory:addFragment(player: Player, fragmentId: string, count: number?)
	if not self.inventories[player.UserId] then
		self.inventories[player.UserId] = {}
	end
	local c = count or 1
	self.inventories[player.UserId][fragmentId] = (self.inventories[player.UserId][fragmentId] or 0) + c
	return self.inventories[player.UserId][fragmentId]
end

function FragmentInventory:removeFragment(player: Player, fragmentId: string, count: number?): boolean
	if not self.inventories[player.UserId] then return false end
	local current = self.inventories[player.UserId][fragmentId] or 0
	local c = count or 1
	if current < c then return false end
	self.inventories[player.UserId][fragmentId] = current - c
	if self.inventories[player.UserId][fragmentId] <= 0 then
		self.inventories[player.UserId][fragmentId] = nil
	end
	return true
end

function FragmentInventory:hasFragment(player: Player, fragmentId: string, count: number?): boolean
	if not self.inventories[player.UserId] then return false end
	return (self.inventories[player.UserId][fragmentId] or 0) >= (count or 1)
end

function FragmentInventory:hasAllFragments(player: Player, fragmentIds: { string }): boolean
	for _, fragId in fragmentIds do
		if not self:hasFragment(player, fragId) then
			return false
		end
	end
	return true
end

-- Remove multiple fragments at once (for spell assembly)
function FragmentInventory:removeFragments(player: Player, fragmentIds: { string }): boolean
	-- First check all are available
	for _, fragId in fragmentIds do
		if not self:hasFragment(player, fragId) then
			return false
		end
	end
	-- Then remove all
	for _, fragId in fragmentIds do
		self:removeFragment(player, fragId)
	end
	return true
end

function FragmentInventory:getFragmentsBySlot(player: Player, slot: string): { string }
	local result = {}
	local inv = self.inventories[player.UserId] or {}
	local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))
	for fragId, count in inv do
		if count > 0 then
			local frag = FragmentData.ById[fragId]
			if frag and frag.slot == slot then
				table.insert(result, fragId)
			end
		end
	end
	return result
end

function FragmentInventory:getFragmentsByElement(player: Player, element: string): { string }
	local result = {}
	local inv = self.inventories[player.UserId] or {}
	local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))
	for fragId, count in inv do
		if count > 0 then
			local frag = FragmentData.ById[fragId]
			if frag and frag.element == element then
				table.insert(result, fragId)
			end
		end
	end
	return result
end

function FragmentInventory:getTotalFragmentCount(player: Player): number
	local total = 0
	local inv = self.inventories[player.UserId] or {}
	for _, count in inv do
		total += count
	end
	return total
end

function FragmentInventory:clearInventory(player: Player)
	self.inventories[player.UserId] = {}
end

function FragmentInventory:equipSpell(player: Player, spellData: any)
	self.equippedSpells[player.UserId] = spellData
	player:SetAttribute("EquippedSpell", spellData.id)
end

function FragmentInventory:getEquippedSpell(player: Player): any
	return self.equippedSpells[player.UserId]
end

return FragmentInventory