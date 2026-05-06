-- FragmentDropper.luau — Fragment drops based on wave performance (stub for M1, full in M3)
local FragmentDropper = {}

function FragmentDropper.new()
    return setmetatable({}, FragmentDropper)
end

function FragmentDropper:dropForPlayer(_player: Player, _waveNumber: number)
    -- Full implementation in M3 (economy)
    -- M1: no drops, hardcoded spell
end

return FragmentDropper