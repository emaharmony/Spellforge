-- SpellforgeUI.client.luau — Spell crafting UI with drag-and-drop fragments
-- Phase 2: Full crafting screen, fragment inventory, spell assembly

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))
local ElementData = require(ReplicatedStorage:WaitForChild("ElementData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SpellforgeUI = {}

-- State
local fragments = {} -- player's fragment inventory: { id = count }
local equippedSpell = nil -- currently equipped spell data
local assemblySlots = { shape = nil, element = nil, power = nil, modifier = nil }
local screenGui = nil
local isOpen = false

-- Colors
local COLORS = {
	bg = Color3.fromRGB(20, 20, 35),
	panel = Color3.fromRGB(30, 30, 50),
	surface = Color3.fromRGB(40, 40, 65),
	slot = Color3.fromRGB(50, 50, 80),
	slotEmpty = Color3.fromRGB(35, 35, 55),
	slotHover = Color3.fromRGB(70, 70, 100),
	accent = Color3.fromRGB(100, 200, 255),
	gold = Color3.fromRGB(255, 215, 0),
	success = Color3.fromRGB(76, 175, 80),
	error = Color3.fromRGB(244, 67, 54),
	text = Color3.fromRGB(240, 240, 255),
	textMuted = Color3.fromRGB(150, 150, 180),
	rarity = {
		common = Color3.fromRGB(180, 180, 180),
		uncommon = Color3.fromRGB(100, 200, 100),
		rare = Color3.fromRGB(100, 150, 255),
		epic = Color3.fromRGB(200, 100, 255),
		legendary = Color3.fromRGB(255, 215, 0),
	},
	element = {
		fire = Color3.fromRGB(255, 87, 34),
		ice = Color3.fromRGB(100, 200, 255),
		lightning = Color3.fromRGB(255, 255, 100),
		shadow = Color3.fromRGB(120, 50, 180),
		nature = Color3.fromRGB(76, 175, 80),
		arcane = Color3.fromRGB(233, 30, 99),
	},
}

-- Font references
local FONT_HEADER = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham
local FONT_SMALL = Enum.Font.Gotham

local TEXT_TITLE = 24
local TEXT_HEADER = 18
local TEXT_BODY = 14
local TEXT_SMALL = 12

-----------------------------------------------------------------------
-- UI Construction
-----------------------------------------------------------------------

local function createScreenGui()
	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellforgeCrafting"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main container (centered)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 800, 0, 600)
	container.Position = UDim2.new(0.5, -400, 0.5, -300)
	container.BackgroundColor3 = COLORS.bg
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = COLORS.accent
	containerStroke.Thickness = 2
	containerStroke.Transparency = 0.5
	containerStroke.Parent = container

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = COLORS.panel
	titleBar.BorderSizePixel = 0
	titleBar.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "✦ Spellforge ✦"
	titleLabel.Font = FONT_HEADER
	titleLabel.TextSize = TEXT_TITLE
	titleLabel.TextColor3 = COLORS.gold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = COLORS.error
	closeBtn.Text = "✕"
	closeBtn.Font = FONT_BODY
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = COLORS.text
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		SpellforgeUI.close()
	end)

	-- Content area (below title)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -50)
	content.Position = UDim2.new(0, 0, 0, 50)
	content.BackgroundTransparency = 1
	content.Parent = container

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 16)
	contentPadding.PaddingBottom = UDim.new(0, 16)
	contentPadding.PaddingLeft = UDim.new(0, 16)
	contentPadding.PaddingRight = UDim.new(0, 16)
	contentPadding.Parent = content

	-- Left: Fragment Inventory
	local inventoryPanel = Instance.new("Frame")
	inventoryPanel.Name = "InventoryPanel"
	inventoryPanel.Size = UDim2.new(0.45, 0, 1, 0)
	inventoryPanel.BackgroundColor3 = COLORS.panel
	inventoryPanel.BorderSizePixel = 0
	inventoryPanel.Parent = content

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 8)
	invCorner.Parent = inventoryPanel

	local invHeader = Instance.new("TextLabel")
	invHeader.Size = UDim2.new(1, 0, 0, 30)
	invHeader.BackgroundTransparency = 1
	invHeader.Text = "Fragments"
	invHeader.Font = FONT_HEADER
	invHeader.TextSize = TEXT_HEADER
	invHeader.TextColor3 = COLORS.text
	invHeader.Parent = inventoryPanel

	-- Fragment grid (scrollable)
	local fragmentScroll = Instance.new("ScrollingFrame")
	fragmentScroll.Name = "FragmentGrid"
	fragmentScroll.Size = UDim2.new(1, -16, 1, -40)
	fragmentScroll.Position = UDim2.new(0, 8, 0, 35)
	fragmentScroll.BackgroundTransparency = 1
	fragmentScroll.ScrollBarThickness = 4
	fragmentScroll.ScrollBarColor3 = COLORS.accent
	fragmentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	fragmentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	fragmentScroll.Parent = inventoryPanel

	local fragmentLayout = Instance.new("UIGridLayout")
	fragmentLayout.CellSize = UDim2.new(0, 85, 0, 100)
	fragmentLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	fragmentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	fragmentLayout.Parent = fragmentScroll

	-- Right: Assembly + Preview
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.52, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.48, 0, 0, 0)
	rightPanel.BackgroundTransparency = 1
	rightPanel.Parent = content

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.Padding = UDim.new(0, 12)
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Parent = rightPanel

	-- Assembly area
	local assemblyPanel = Instance.new("Frame")
	assemblyPanel.Name = "AssemblyPanel"
	assemblyPanel.Size = UDim2.new(1, 0, 0, 240)
	assemblyPanel.BackgroundColor3 = COLORS.panel
	assemblyPanel.BorderSizePixel = 0
	assemblyPanel.LayoutOrder = 1
	assemblyPanel.Parent = rightPanel

	local asmCorner = Instance.new("UICorner")
	asmCorner.CornerRadius = UDim.new(0, 8)
	asmCorner.Parent = assemblyPanel

	local asmHeader = Instance.new("TextLabel")
	asmHeader.Size = UDim2.new(1, 0, 0, 30)
	asmHeader.BackgroundTransparency = 1
	asmHeader.Text = "Assembly"
	asmHeader.Font = FONT_HEADER
	asmHeader.TextSize = TEXT_HEADER
	asmHeader.TextColor3 = COLORS.text
	asmHeader.Parent = assemblyPanel

	-- 4 assembly slots
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "SlotsContainer"
	slotsContainer.Size = UDim2.new(1, -16, 0, 140)
	slotsContainer.Position = UDim2.new(0, 8, 0, 35)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.Parent = assemblyPanel

	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	slotsLayout.Padding = UDim.new(0, 8)
	slotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	slotsLayout.Parent = slotsContainer

	-- Create 4 slots
	for i, slotName in Config.FRAGMENT_SLOTS do
		local slot = Instance.new("Frame")
		slot.Name = slotName .. "Slot"
		slot.Size = UDim2.new(0, 120, 0, 140)
		slot.BackgroundColor3 = COLORS.slotEmpty
		slot.BorderSizePixel = 0
		slot.LayoutOrder = i
		slot.Parent = slotsContainer

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 8)
		slotCorner.Parent = slot

		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = COLORS.accent
		slotStroke.Thickness = 2
		slotStroke.Transparency = 0.5
		slotStroke.Parent = slot

		-- Slot label
		local slotLabel = Instance.new("TextLabel")
		slotLabel.Name = "SlotLabel"
		slotLabel.Size = UDim2.new(1, 0, 0, 24)
		slotLabel.Position = UDim2.new(0, 0, 1, -28)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = slotName:sub(1, 1):upper() .. slotName:sub(2)
		slotLabel.Font = FONT_SMALL
		slotLabel.TextSize = TEXT_SMALL
		slotLabel.TextColor3 = COLORS.textMuted
		slotLabel.Parent = slot

		-- Drop hint
		local dropHint = Instance.new("TextLabel")
		dropHint.Name = "DropHint"
		dropHint.Size = UDim2.new(1, 0, 1, -24)
		dropHint.BackgroundTransparency = 1
		dropHint.Text = "Drop\n" .. slotName:sub(1, 1):upper() .. slotName:sub(2)
		dropHint.Font = FONT_SMALL
		dropHint.TextSize = TEXT_SMALL
		dropHint.TextColor3 = COLORS.textMuted
		dropHint.TextTransparency = 0.5
		dropHint.Parent = slot
	end

	-- Spell preview
	local previewPanel = Instance.new("Frame")
	previewPanel.Name = "PreviewPanel"
	previewPanel.Size = UDim2.new(1, 0, 0, 180)
	previewPanel.BackgroundColor3 = COLORS.panel
	previewPanel.BorderSizePixel = 0
	previewPanel.LayoutOrder = 2
	previewPanel.Parent = rightPanel

	local prevCorner = Instance.new("UICorner")
	prevCorner.CornerRadius = UDim.new(0, 8)
	prevCorner.Parent = previewPanel

	local prevHeader = Instance.new("TextLabel")
	prevHeader.Size = UDim2.new(1, 0, 0, 30)
	prevHeader.BackgroundTransparency = 1
	prevHeader.Text = "Spell Preview"
	prevHeader.Font = FONT_HEADER
	prevHeader.TextSize = TEXT_HEADER
	prevHeader.TextColor3 = COLORS.text
	prevHeader.Parent = previewPanel

	-- Stats display
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "Stats"
	statsFrame.Size = UDim2.new(1, -16, 1, -40)
	statsFrame.Position = UDim2.new(0, 8, 0, 35)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = previewPanel

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Padding = UDim.new(0, 4)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = statsFrame

	-- Assemble button
	local assembleBtn = Instance.new("TextButton")
	assembleBtn.Name = "AssembleButton"
	assembleBtn.Size = UDim2.new(1, 0, 0, 45)
	assembleBtn.BackgroundColor3 = COLORS.success
	assembleBtn.Text = "✦ Assemble Spell ✦"
	assembleBtn.Font = FONT_HEADER
	assembleBtn.TextSize = TEXT_HEADER
	assembleBtn.TextColor3 = COLORS.text
	assembleBtn.BorderSizePixel = 0
	assembleBtn.AutoButtonColor = true
	assembleBtn.LayoutOrder = 3
	assembleBtn.Parent = rightPanel

	local asmBtnCorner = Instance.new("UICorner")
	asmBtnCorner.CornerRadius = UDim.new(0, 8)
	asmBtnCorner.Parent = assembleBtn

	assembleBtn.Activated:Connect(function()
		SpellforgeUI:assembleSpell()
	end)

	-- Start hidden
	screenGui.Enabled = false
	return screenGui
end

-----------------------------------------------------------------------
-- Fragment Inventory Rendering
-----------------------------------------------------------------------

local function updateFragmentGrid()
	if not screenGui then return end
	local grid = screenGui:FindFirstChild("Container/Content/InventoryPanel/FragmentGrid", true)
	if not grid then return end

	-- Clear existing
	for _, child in grid:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Add fragments
	local order = 0
	for fragId, count in fragments do
		if count <= 0 then continue end
		local fragData = FragmentData.ById[fragId]
		if not fragData then continue end

		local fragBtn = Instance.new("TextButton")
		fragBtn.Name = "Frag_" .. fragId
		fragBtn.Size = UDim2.new(0, 85, 0, 100)
		fragBtn.BackgroundColor3 = COLORS.slot
		fragBtn.BorderSizePixel = 0
		fragBtn.LayoutOrder = order
		fragBtn.Text = ""
		fragBtn.AutoButtonColor = false
		fragBtn.Parent = grid

		local fragCorner = Instance.new("UICorner")
		fragCorner.CornerRadius = UDim.new(0, 6)
		fragCorner.Parent = fragBtn

		-- Element color accent
		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(1, 0, 0, 4)
		accentBar.BackgroundColor3 = COLORS.element[fragData.element] or COLORS.accent
		accentBar.BorderSizePixel = 0
		accentBar.Parent = fragBtn

		-- Fragment name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -4, 0, 40)
		nameLabel.Position = UDim2.new(0, 2, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = fragData.description or fragId
		nameLabel.Font = FONT_SMALL
		nameLabel.TextSize = 10
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextWrapped = true
		nameLabel.Parent = fragBtn

		-- Rarity label
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 16)
		rarityLabel.Position = UDim2.new(0, 0, 1, -22)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = fragData.rarity or "common"
		rarityLabel.Font = FONT_SMALL
		rarityLabel.TextSize = 10
		rarityLabel.TextColor3 = COLORS.rarity[fragData.rarity] or COLORS.textMuted
		rarityLabel.Parent = fragBtn

		-- Count
		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, 0, 0, 16)
		countLabel.Position = UDim2.new(0, 0, 1, -38)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "×" .. count
		countLabel.Font = FONT_BODY
		countLabel.TextSize = 12
		countLabel.TextColor3 = COLORS.text
		countLabel.Parent = fragBtn

		-- Click to place in assembly slot
		fragBtn.Activated:Connect(function()
			SpellforgeUI:placeFragment(fragId)
		end)

		order += 1
	end
end

-----------------------------------------------------------------------
-- Assembly Logic
-----------------------------------------------------------------------

function SpellforgeUI:placeFragment(fragId: string)
	local fragData = FragmentData.ById[fragId]
	if not fragData then return end

	-- Place in the correct slot
	local slot = fragData.slot
	if assemblySlots[slot] then
		-- Already occupied — swap
		local oldFrag = assemblySlots[slot]
		-- Return old fragment to inventory
		fragments[oldFrag] = (fragments[oldFrag] or 0) + 1
	end

	assemblySlots[slot] = fragId
	fragments[fragId] = (fragments[fragId] or 1) - 1
	if fragments[fragId] <= 0 then
		fragments[fragId] = nil
	end

	self:updateAssemblyDisplay()
	self:updatePreview()
	updateFragmentGrid()
end

function SpellforgeUI:removeFromSlot(slotName: string)
	local fragId = assemblySlots[slotName]
	if not fragId then return end

	-- Return fragment to inventory
	fragments[fragId] = (fragments[fragId] or 0) + 1
	assemblySlots[slotName] = nil

	self:updateAssemblyDisplay()
	self:updatePreview()
	updateFragmentGrid()
end

function SpellforgeUI:updateAssemblyDisplay()
	if not screenGui then return end
	local container = screenGui:FindFirstChild("Container", true)
	if not container then return end

	for _, slotName in Config.FRAGMENT_SLOTS do
		local slotFrame = container:FindFirstChild(slotName .. "Slot", true)
		if slotFrame then
			local fragId = assemblySlots[slotName]
			local dropHint = slotFrame:FindFirstChild("DropHint")

			if fragId then
				local fragData = FragmentData.ById[fragId]
				if fragData then
					slotFrame.BackgroundColor3 = COLORS.element[fragData.element] or COLORS.slot
					if dropHint then
						dropHint.Text = fragData.description or fragId
						dropHint.TextColor3 = COLORS.text
						dropHint.TextTransparency = 0
					end
				end
			else
				slotFrame.BackgroundColor3 = COLORS.slotEmpty
				if dropHint then
					dropHint.Text = "Drop\n" .. slotName:sub(1, 1):upper() .. slotName:sub(2)
					dropHint.TextColor3 = COLORS.textMuted
					dropHint.TextTransparency = 0.5
				end
			end
		end
	end
end

function SpellforgeUI:updatePreview()
	if not screenGui then return end
	local statsFrame = screenGui:FindFirstChild("Container/Content/RightPanel/PreviewPanel/Stats", true)
	if not statsFrame then return end

	-- Clear old stats
	for _, child in statsFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Check if all 4 slots filled
	local allFilled = true
	for _, slotName in Config.FRAGMENT_SLOTS do
		if not assemblySlots[slotName] then
			allFilled = false
			break
		end
	end

	if not allFilled then
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, 0, 0, 20)
		hint.BackgroundTransparency = 1
		hint.Text = "Fill all 4 slots to preview your spell"
		hint.Font = FONT_BODY
		hint.TextSize = TEXT_BODY
		hint.TextColor3 = COLORS.textMuted
		hint.Parent = statsFrame
		return
	end

	-- Assemble preview
	local fragmentIds = {}
	for _, slotName in Config.FRAGMENT_SLOTS do
		table.insert(fragmentIds, assemblySlots[slotName])
	end

	local spell = require(ReplicatedStorage.SpellAssembler).assemble(fragmentIds)
	if not spell then
		local err = Instance.new("TextLabel")
		err.Size = UDim2.new(1, 0, 0, 20)
		err.BackgroundTransparency = 1
		err.Text = "⚠ Invalid combination"
		err.Font = FONT_BODY
		err.TextSize = TEXT_BODY
		err.TextColor3 = COLORS.error
		err.Parent = statsFrame
		return
	end

	-- Display spell stats
	local stats = {
		{ "Name", spell.name },
		{ "Element", spell.element },
		{ "Damage", tostring(spell.damage) },
		{ "Cooldown", string.format("%.1fs", spell.cooldown) },
		{ "Range", tostring(spell.range) },
		{ "Shape", spell.shape },
		{ "Effect", spell.effect },
		{ "Rarity", spell.rarity },
	}

	for i, stat in stats do
		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 0, 20)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = FONT_BODY
		statLabel.TextSize = TEXT_BODY
		statLabel.TextColor3 = COLORS.text
		statLabel.TextXAlignment = Enum.TextXAlignment.Left

		if i == 1 then
			statLabel.Text = string.format("  %s: %s", stat[1], stat[2])
		elseif stat[1] == "Rarity" then
			statLabel.Text = string.format("  %s: %s", stat[1], stat[2])
			statLabel.TextColor3 = COLORS.rarity[stat[2]] or COLORS.text
		elseif stat[1] == "Damage" then
			statLabel.Text = string.format("  %s: %s", stat[1], stat[2])
			statLabel.TextColor3 = COLORS.gold
		else
			statLabel.Text = string.format("  %s: %s", stat[1], stat[2])
		end

		statLabel.Parent = statsFrame
	end
end

function SpellforgeUI:assembleSpell()
	local fragmentIds = {}
	for _, slotName in Config.FRAGMENT_SLOTS do
		if not assemblySlots[slotName] then
			-- Not all slots filled
			return
		end
		table.insert(fragmentIds, assemblySlots[slotName])
	end

	-- Send to server
	Remotes.AssembleSpell:FireServer(fragmentIds)

	-- Clear assembly slots
	for _, slotName in Config.FRAGMENT_SLOTS do
		assemblySlots[slotName] = nil
	end

	self:updateAssemblyDisplay()
	self:updatePreview()
	updateFragmentGrid()
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

function SpellforgeUI.open()
	if not screenGui then
		createScreenGui()
	end
	screenGui.Enabled = true
	isOpen = true
	updateFragmentGrid()
end

function SpellforgeUI.close()
	if screenGui then
		screenGui.Enabled = false
	end
	isOpen = false

	-- Return any fragments in assembly slots back to inventory
	for _, slotName in Config.FRAGMENT_SLOTS do
		if assemblySlots[slotName] then
			local fragId = assemblySlots[slotName]
			fragments[fragId] = (fragments[fragId] or 0) + 1
			assemblySlots[slotName] = nil
		end
	end
end

function SpellforgeUI.toggle()
	if isOpen then
		SpellforgeUI.close()
	else
		SpellforgeUI.open()
	end
end

function SpellforgeUI.addFragment(fragId: string, count: number)
	fragments[fragId] = (fragments[fragId] or 0) + (count or 1)
	if isOpen then
		updateFragmentGrid()
	end
end

function SpellforgeUI.setFragments(fragList: { [string]: number })
	fragments = fragList
	if isOpen then
		updateFragmentGrid()
	end
end

-----------------------------------------------------------------------
-- Remote Handlers
-----------------------------------------------------------------------

Remotes.FragmentReceived.OnClientEvent:Connect(function(fragData: any)
	if typeof(fragData) == "table" and fragData.id then
		SpellforgeUI.addFragment(fragData.id, 1)
	end
end)

Remotes.SpellAssembled.OnClientEvent:Connect(function(spellData: any)
	equippedSpell = spellData
	-- Could show a notification here
end)

Remotes.RestPhase.OnClientEvent:Connect(function(data: any)
	-- Auto-open crafting during rest phase
	if data and data.restPhase then
		SpellforgeUI.open()
	end
end)

return SpellforgeUI