-- CoopManager.luau — Co-op coordination (stub for M1, full in M3)
local CoopManager = {}
CoopManager.__index = CoopManager

function CoopManager.new()
	return setmetatable({}, CoopManager)
end

return CoopManager