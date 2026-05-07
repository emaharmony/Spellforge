-- FragmentInventory.luau — Player fragment collection (stub for M1, full implementation in M2)
local FragmentInventory = {}
FragmentInventory.__index = FragmentInventory

function FragmentInventory.new()
    local self = setmetatable({}, FragmentInventory)
    self.inventories = {} -- player id -> { fragment ids }
    return self
end

function FragmentInventory:getFragments(player: Player): { string }
    return self.inventories[player.UserId] or {}
end

function FragmentInventory:addFragment(player: Player, fragmentId: string)
    if not self.inventories[player.UserId] then
        self.inventories[player.UserId] = {}
    end
    table.insert(self.inventories[player.UserId], fragmentId)
end

return FragmentInventory