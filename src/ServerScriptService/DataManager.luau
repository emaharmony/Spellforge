-- DataManager.luau — Data persistence (stub for M1, full in M3)
local DataManager = {}
DataManager.__index = DataManager

function DataManager.new()
	return setmetatable({}, DataManager)
end

function DataManager:saveData(_player: Player)
	-- M3: DataStore persistence
end

function DataManager:loadData(_player: Player)
	-- M3: DataStore persistence
end

return DataManager