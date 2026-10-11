-- RunResultsUI.client.luau — End-of-run results screen with Play Again (Phase 1 run integrity)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RunResultsUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50 -- above HUD and rest UI
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Dim backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui

-- Panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 380, 0, 320)
panel.Position = UDim2.new(0.5, -190, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
panel.BorderSizePixel = 0
panel.Parent = backdrop

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 200, 255)
stroke.Thickness = 2
stroke.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 20)
padding.PaddingBottom = UDim.new(0, 16)
padding.Parent = panel

local function makeLabel(name: string, text: string, size: number, color: Color3, order: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -32, 0, size + 8)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextColor3 = color
	label.Text = text
	label.LayoutOrder = order
	label.Parent = panel
	return label
end

local titleLabel = makeLabel("Title", "", 34, Color3.fromRGB(255, 255, 255), 1)
local subtitleLabel = makeLabel("Subtitle", "", 16, Color3.fromRGB(160, 170, 190), 2)
local statsLabel = makeLabel("Stats", "", 18, Color3.fromRGB(220, 225, 235), 3)

-- Play Again button
local playAgainBtn = Instance.new("TextButton")
playAgainBtn.Name = "PlayAgain"
playAgainBtn.Size = UDim2.new(1, -32, 0, 52)
playAgainBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 110)
playAgainBtn.Text = "▶  Play Again"
playAgainBtn.Font = Enum.Font.GothamBold
playAgainBtn.TextSize = 22
playAgainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgainBtn.BorderSizePixel = 0
playAgainBtn.LayoutOrder = 4
playAgainBtn.Parent = panel

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = playAgainBtn

playAgainBtn.Activated:Connect(function()
	Remotes.PlayAgain:FireServer()
	-- Server restarts the run; WaveStart closes this screen
end)

local hint = makeLabel("Hint", "anyone can restart the run", 12, Color3.fromRGB(120, 130, 150), 5)

Remotes.GameOver.OnClientEvent:Connect(function(reason: string, stats: any)
	-- Only run-level endings open the results screen; "died_waiting_revive"
	-- is a personal death notice (co-op: waiting for the run to end).
	if reason ~= "victory" and reason ~= "defeated" then
		return
	end
	stats = stats or {}

	-- SF-140b: run ended — close the rest/crafting panels so they don't
	-- overlap the results screen (PT-001: Wave Complete + Defeated both up)
	local playerGui = script.Parent
	for _, name in { "WaveRestUI", "SpellforgeCrafting" } do
		local gui = playerGui:FindFirstChild(name, true)
		if gui and gui:IsA("ScreenGui") then
			gui.Enabled = false
		end
	end

	local isNewBest = stats.victory == true and stats.isBest == true
	local waveReached = tostring(stats.wave or "?")
	if reason == "victory" then
		titleLabel.Text = "🎉 Victory!"
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		subtitleLabel.Text = "all " .. tostring(stats.maxWaves or 10) .. " waves cleared"
		if isNewBest then
			subtitleLabel.Text = "first full clear — Max HP 120 unlocked!"
		end
		stroke.Color = Color3.fromRGB(255, 215, 0)
	else
		titleLabel.Text = "💀 Defeated"
		titleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		subtitleLabel.Text = "fell on wave " .. waveReached
		stroke.Color = Color3.fromRGB(255, 80, 80)
	end
	statsLabel.Text = string.format(
		"Wave %s / %s   •   %d kills   •   +%d 💎",
		waveReached,
		tostring(stats.maxWaves or 10),
		stats.kills or 0,
		stats.crystalsEarned or 0
	)
	playAgainBtn.Active = true
	playAgainBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 110)
	playAgainBtn.Text = "▶  Play Again"
	screenGui.Enabled = true
end)

Remotes.WaveStart.OnClientEvent:Connect(function()
	screenGui.Enabled = false
end)

return nil