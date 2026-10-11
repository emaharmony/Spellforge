-- WaveRestUI.client.luau — Wave rest phase: results, shop, crafting, ready-up
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WaveRestUI = {}

local screenGui = nil
local isOpen = false
local ready = false

-- Colors (matching SpellforgeUI theme)
local COLORS = {
	bg = Color3.fromRGB(20, 20, 35),
	panel = Color3.fromRGB(30, 30, 50),
	surface = Color3.fromRGB(40, 40, 65),
	accent = Color3.fromRGB(100, 200, 255),
	gold = Color3.fromRGB(255, 215, 0),
	success = Color3.fromRGB(76, 175, 80),
	error = Color3.fromRGB(244, 67, 54),
	text = Color3.fromRGB(240, 240, 255),
	textMuted = Color3.fromRGB(150, 150, 180),
}

local FONT_HEADER = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham
local TEXT_TITLE = 24
local TEXT_HEADER = 18
local TEXT_BODY = 14

local function createUI()
	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WaveRestUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Full-screen overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.Parent = screenGui

	-- Main panel (centered, top area)
	local panel = Instance.new("Frame")
	panel.Name = "MainPanel"
	panel.Size = UDim2.new(0, 600, 0, 400)
	panel.Position = UDim2.new(0.5, -300, 0.3, -200)
	panel.BackgroundColor3 = COLORS.panel
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = COLORS.gold
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = panel

	-- Wave result title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "WaveTitle"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Wave Complete!"
	titleLabel.Font = FONT_HEADER
	titleLabel.TextSize = TEXT_TITLE
	titleLabel.TextColor3 = COLORS.gold
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = panel

	-- Crystals earned
	local crystalLabel = Instance.new("TextLabel")
	crystalLabel.Name = "CrystalsEarned"
	crystalLabel.Size = UDim2.new(1, 0, 0, 30)
	crystalLabel.BackgroundTransparency = 1
	crystalLabel.Text = "💎 +0 crystals"
	crystalLabel.Font = FONT_HEADER
	crystalLabel.TextSize = TEXT_HEADER
	crystalLabel.TextColor3 = COLORS.gold
	crystalLabel.LayoutOrder = 2
	crystalLabel.Parent = panel

	-- Timer
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(1, 0, 0, 50)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "15"
	timerLabel.Font = FONT_HEADER
	timerLabel.TextSize = 36
	timerLabel.TextColor3 = COLORS.accent
	timerLabel.LayoutOrder = 3
	timerLabel.Parent = panel

	-- Shop section
	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(1, 0, 0, 120)
	shopFrame.BackgroundColor3 = COLORS.surface
	shopFrame.BorderSizePixel = 0
	shopFrame.LayoutOrder = 4
	shopFrame.Parent = panel

	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 8)
	shopCorner.Parent = shopFrame

	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 8)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopFrame

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, 0, 0, 24)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "Crystal Shop"
	shopTitle.Font = FONT_HEADER
	shopTitle.TextSize = TEXT_HEADER
	shopTitle.TextColor3 = COLORS.text
	shopTitle.LayoutOrder = 1
	shopTitle.Parent = shopFrame

	-- Minor Pack button
	local minorPackBtn = Instance.new("TextButton")
	minorPackBtn.Name = "MinorPack"
	minorPackBtn.Size = UDim2.new(0.48, 0, 0, 36)
	minorPackBtn.BackgroundColor3 = COLORS.accent
	minorPackBtn.Text = "Minor Pack (50💎) — 3 frags"
	minorPackBtn.Font = FONT_BODY
	minorPackBtn.TextSize = TEXT_BODY
	minorPackBtn.TextColor3 = COLORS.text
	minorPackBtn.BorderSizePixel = 0
	minorPackBtn.LayoutOrder = 2
	minorPackBtn.Parent = shopFrame

	local minorCorner = Instance.new("UICorner")
	minorCorner.CornerRadius = UDim.new(0, 6)
	minorCorner.Parent = minorPackBtn

	minorPackBtn.Activated:Connect(function()
		Remotes.BuyPack:FireServer("minor")
	end)

	-- Major Pack button
	local majorPackBtn = Instance.new("TextButton")
	majorPackBtn.Name = "MajorPack"
	majorPackBtn.Size = UDim2.new(0.48, 0, 0, 36)
	majorPackBtn.BackgroundColor3 = COLORS.gold
	majorPackBtn.Text = "Major Pack (150💎) — 5 frags"
	majorPackBtn.Font = FONT_BODY
	majorPackBtn.TextSize = TEXT_BODY
	majorPackBtn.TextColor3 = Color3.fromRGB(30, 30, 50)
	majorPackBtn.BorderSizePixel = 0
	majorPackBtn.LayoutOrder = 3
	majorPackBtn.Parent = shopFrame

	local majorCorner = Instance.new("UICorner")
	majorCorner.CornerRadius = UDim.new(0, 6)
	majorCorner.Parent = majorPackBtn

	majorPackBtn.Activated:Connect(function()
		Remotes.BuyPack:FireServer("major")
	end)

	-- Heal button
	local healBtn = Instance.new("TextButton")
	healBtn.Name = "HealButton"
	healBtn.Size = UDim2.new(1, 0, 0, 36)
	healBtn.BackgroundColor3 = COLORS.success
	healBtn.Text = "❤️ Heal 30 HP (20💎)"
	healBtn.Font = FONT_BODY
	healBtn.TextSize = TEXT_BODY
	healBtn.TextColor3 = COLORS.text
	healBtn.BorderSizePixel = 0
	healBtn.LayoutOrder = 4
	healBtn.Parent = shopFrame

	local healCorner = Instance.new("UICorner")
	healCorner.CornerRadius = UDim.new(0, 6)
	healCorner.Parent = healBtn

	healBtn.Activated:Connect(function()
		Remotes.HealWithCrystals:FireServer()
	end)

	-- Open Crafting button
	local craftBtn = Instance.new("TextButton")
	craftBtn.Name = "CraftButton"
	craftBtn.Size = UDim2.new(1, 0, 0, 40)
	craftBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
	craftBtn.Text = "✦ Open Spellforge ✦"
	craftBtn.Font = FONT_HEADER
	craftBtn.TextSize = TEXT_HEADER
	craftBtn.TextColor3 = COLORS.text
	craftBtn.BorderSizePixel = 0
	craftBtn.LayoutOrder = 5
	craftBtn.Parent = panel

	local craftCorner = Instance.new("UICorner")
	craftCorner.CornerRadius = UDim.new(0, 8)
	craftCorner.Parent = craftBtn

	craftBtn.Activated:Connect(function()
		local SpellforgeUI = require(ReplicatedStorage:FindFirstChild("SpellforgeUI", true))
		if SpellforgeUI then
			SpellforgeUI.open()
		end
	end)

	-- Ready Up button
	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyButton"
	readyBtn.Size = UDim2.new(1, 0, 0, 50)
	readyBtn.BackgroundColor3 = COLORS.success
	readyBtn.Text = "✓ Ready Up"
	readyBtn.Font = FONT_HEADER
	readyBtn.TextSize = TEXT_TITLE
	readyBtn.TextColor3 = COLORS.text
	readyBtn.BorderSizePixel = 0
	readyBtn.LayoutOrder = 6
	readyBtn.Parent = panel

	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, 8)
	readyCorner.Parent = readyBtn

	readyBtn.Activated:Connect(function()
		ready = true
		readyBtn.Text = "✓ Ready!"
		readyBtn.BackgroundColor3 = COLORS.textMuted
		readyBtn.Active = false
		Remotes.ReadyUp:FireServer()
	end)

	-- Start hidden
	screenGui.Enabled = false
	return screenGui
end

-- Update timer
local timerThread = nil
local function startTimer(duration: number)
	if timerThread then
		task.cancel(timerThread)
	end

	timerThread = task.spawn(function()
		local endTime = tick() + duration
		while tick() < endTime do
			local remaining = math.ceil(endTime - tick())
			local timerLabel = screenGui and screenGui:FindFirstChild("MainPanel/Timer", true)
			if timerLabel then
				timerLabel.Text = tostring(remaining)
			end
			task.wait(0.5)
		end
		-- Time's up
		local timerLabel = screenGui and screenGui:FindFirstChild("MainPanel/Timer", true)
		if timerLabel then
			timerLabel.Text = "0"
		end
	end)
end

function WaveRestUI.open(data: any)
	if not screenGui then createUI() end

	-- Update crystal display
	if data then
		local crystalLabel = screenGui:FindFirstChild("MainPanel/CrystalsEarned", true)
		if crystalLabel and data.crystals then
			crystalLabel.Text = string.format("💎 +%d crystals", data.crystals)
		end

		local titleLabel = screenGui:FindFirstChild("MainPanel/WaveTitle", true)
		if titleLabel and data.completedWave then
			titleLabel.Text = string.format("Wave %d Complete!", data.completedWave)
		end
	end

	ready = false
	local readyBtn = screenGui:FindFirstChild("MainPanel/ReadyButton", true)
	if readyBtn then
		readyBtn.Text = "✓ Ready Up"
		readyBtn.BackgroundColor3 = COLORS.success
		readyBtn.Active = true
	end

	screenGui.Enabled = true
	isOpen = true

	-- Start countdown timer
	startTimer(Config.WAVE_REST_TIME)
end

function WaveRestUI.close()
	if screenGui then
		screenGui.Enabled = false
	end
	isOpen = false
	ready = false
	if timerThread then
		task.cancel(timerThread)
	end
end

-----------------------------------------------------------------------
-- Remote Handlers
-----------------------------------------------------------------------

Remotes.WaveComplete.OnClientEvent:Connect(function(wave: number, description: string)
	-- Wave complete — show rest UI
	local crystals = player:GetAttribute("Crystals") or 0
	WaveRestUI.open({
		completedWave = wave,
		crystals = crystals,
		description = description,
	})
end)

Remotes.WaveStart.OnClientEvent:Connect(function(wave: number, maxWaves: number, description: string)
	-- New wave starting — close rest UI
	WaveRestUI.close()
end)

Remotes.GameOver.OnClientEvent:Connect(function(reason: string)
	-- Game over — close rest UI
	WaveRestUI.close()
end)

return WaveRestUI