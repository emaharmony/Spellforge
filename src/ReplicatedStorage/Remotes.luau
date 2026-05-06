-- Remotes.luau — RemoteEvent setup for Spellforge
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Create RemoteEvents
local function ensureRemote(name: string, className: string): Instance
    local container = ReplicatedStorage:FindFirstChild("Remotes")
        or Instance.new("Folder")
    container.Name = "Remotes"
    container.Parent = ReplicatedStorage

    local remote = container:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = container
    end
    return remote
end

-- Client → Server
Remotes.CastSpell = ensureRemote("CastSpell", "RemoteEvent")
Remotes.SwapFragment = ensureRemote("SwapFragment", "RemoteEvent")
Remotes.BuyPack = ensureRemote("BuyPack", "RemoteEvent")

-- Server → Client
Remotes.WaveStart = ensureRemote("WaveStart", "RemoteEvent")
Remotes.WaveComplete = ensureRemote("WaveComplete", "RemoteEvent")
Remotes.GameOver = ensureRemote("GameOver", "RemoteEvent")
Remotes.UpdateHUD = ensureRemote("UpdateHUD", "RemoteEvent")
Remotes.FragmentReceived = ensureRemote("FragmentReceived", "RemoteEvent")
Remotes.EnemyDamaged = ensureRemote("EnemyDamaged", "RemoteEvent")
Remotes.SpellFired = ensureRemote("SpellFired", "RemoteEvent")

return Remotes