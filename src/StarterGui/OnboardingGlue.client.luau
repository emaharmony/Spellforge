-- OnboardingGlue.client.luau — Phase 5 (SF-130/131/132).
-- 1. BossWarning banner (wave 10) — remote fired by WaveSystem on boss spawn.
-- 2. First-join instruction card — shows until the player finishes wave 1.
-- 3. C keybind toggles the crafting UI (SpellforgeUI.toggle exists, was unwired).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Boss warning banner (SF-130)
local bossGui = Instance.new("ScreenGui")
bossGui.Name = "BossWarningGui"
bossGui.ResetOnSpawn = false
bossGui.DisplayOrder = 50
bossGui.Parent = playerGui

local bossBanner = Instance.new("TextLabel")
bossBanner.Name = "BossBanner"
bossBanner.Size = UDim2.new(0, 480, 0, 64)
bossBanner.Position = UDim2.new(0.5, -240, 0.12, 0)
bossBanner.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
bossBanner.BackgroundTransparency = 0.05
bossBanner.TextColor3 = Color3.fromRGB(255, 180, 60)
bossBanner.Font = Enum.Font.GothamBlack
bossBanner.TextScaled = true
bossBanner.Text = ""
bossBanner.Visible = false
bossBanner.Parent = bossGui

local bossCorner = Instance.new("UICorner")
bossCorner.CornerRadius = UDim.new(0, 12)
bossCorner.Parent = bossBanner

local bossStroke = Instance.new("UIStroke")
bossStroke.Color = Color3.fromRGB(255, 120, 40)
bossStroke.Thickness = 3
bossStroke.Parent = bossBanner

Remotes.BossWarning.OnClientEvent:Connect(function(info)
	if typeof(info) ~= "table" then return end
	local name = info.name or "The Colossus"
	bossBanner.Text = "⚠ BOSS INBOUND: " .. string.upper(name) .. " ⚠"
	bossBanner.Visible = true
	task.delay(4, function()
		bossBanner.Visible = false
	end)
end)

-- First-join instruction card (SF-131) — until the first wave completes
local joinGui = Instance.new("ScreenGui")
joinGui.Name = "OnboardingCard"
joinGui.ResetOnSpawn = false
joinGui.DisplayOrder = 40
joinGui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 360, 0, 150)
card.Position = UDim2.new(0.5, -180, 0.72, 0)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
card.BackgroundTransparency = 0.05
card.Parent = joinGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(100, 160, 255)
cardStroke.Thickness = 2
cardStroke.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 220, 120)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Text = "WIZARD, WELCOME"
title.Parent = card

local body = Instance.new("TextLabel")
body.Name = "Body"
body.Size = UDim2.new(1, -20, 0, 90)
body.Position = UDim2.new(0, 10, 0, 44)
body.BackgroundTransparency = 1
body.TextColor3 = Color3.fromRGB(230, 230, 240)
body.Font = Enum.Font.Gotham
body.TextWrapped = true
body.TextSize = 16
body.TextXAlignment = Enum.TextXAlignment.Left
body.Text = "Survive 10 waves. Your staff fires on its own.\nCraft stronger spells between waves — press C.\nFragments drop from every kill."
body.Parent = card

Remotes.WaveComplete.OnClientEvent:Connect(function(wave)
	if wave == 1 then
		joinGui:Destroy()
		-- Harness restarts can leave stale welcome cards from prior sessions
		for _, other in playerGui:GetChildren() do
			if other.Name == "OnboardingCard" and other ~= joinGui then
				other:Destroy()
			end
		end
	end
end)