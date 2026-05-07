-- CrystalManager.luau — Crystal currency (stub for M1, full in M3)
local CrystalManager = {}
CrystalManager.__index = CrystalManager

function CrystalManager.new()
    local self = setmetatable({}, CrystalManager)
    return self
end

function CrystalManager:awardCrystals(player: Player, amount: number)
    local current = player:GetAttribute("Crystals") or 0
    player:SetAttribute("Crystals", current + amount)
end

return CrystalManager