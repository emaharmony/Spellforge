-- Remotes.luau — RemoteEvent setup for Spellforge v2
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local REMOTE_FOLDER_NAME = "SpellforgeRemotes"

-- Create RemoteEvents
local function ensureRemote(name: string, className: string): Instance
	local container = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
		if not container then
		container = Instance.new("Folder")
		container.Name = REMOTE_FOLDER_NAME
		container.Parent = ReplicatedStorage
	end

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
Remotes.ReadyUp = ensureRemote("ReadyUp", "RemoteEvent")
Remotes.HealWithCrystals = ensureRemote("HealWithCrystals", "RemoteEvent")
Remotes.AssembleSpell = ensureRemote("AssembleSpell", "RemoteEvent")
Remotes.EquipSpell = ensureRemote("EquipSpell", "RemoteEvent")

-- Server → Client
Remotes.WaveStart = ensureRemote("WaveStart", "RemoteEvent")
Remotes.WaveComplete = ensureRemote("WaveComplete", "RemoteEvent")
Remotes.GameOver = ensureRemote("GameOver", "RemoteEvent")
Remotes.UpdateHUD = ensureRemote("UpdateHUD", "RemoteEvent")
Remotes.FragmentReceived = ensureRemote("FragmentReceived", "RemoteEvent")
Remotes.EnemyDamaged = ensureRemote("EnemyDamaged", "RemoteEvent")
Remotes.SpellFired = ensureRemote("SpellFired", "RemoteEvent")
Remotes.RestPhase = ensureRemote("RestPhase", "RemoteEvent")
Remotes.ShopResult = ensureRemote("ShopResult", "RemoteEvent")
Remotes.SpellAssembled = ensureRemote("SpellAssembled", "RemoteEvent")
Remotes.HealResult = ensureRemote("HealResult", "RemoteEvent")
Remotes.BossWarning = ensureRemote("BossWarning", "RemoteEvent")
Remotes.ElementalCombo = ensureRemote("ElementalCombo", "RemoteEvent")

return Remotes