-- DefenseHUD.client.luau — Wave counter, wizard HP, crystal count
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DefenseHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Wave display
local waveFrame = Instance.new("Frame")
waveFrame.Name = "WaveFrame"
waveFrame.Size = UDim2.new(0, 200, 0, 40)
waveFrame.Position = UDim2.new(0.5, -100, 0, 10)
waveFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
waveFrame.BorderSizePixel = 2
waveFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
waveFrame.Parent = screenGui

local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Size = UDim2.new(1, 0, 1, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveLabel.Font = Enum.Font.GothamBold
waveLabel.TextSize = 20
waveLabel.Text = "Waiting..."
waveLabel.Parent = waveFrame

-- HP bar
local hpFrame = Instance.new("Frame")
hpFrame.Name = "HPFrame"
hpFrame.Size = UDim2.new(0, 200, 0, 20)
hpFrame.Position = UDim2.new(0, 10, 1, -30)
hpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
hpFrame.BorderSizePixel = 1
hpFrame.Parent = screenGui

local hpFill = Instance.new("Frame")
hpFill.Name = "HPFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpFrame

local hpLabel = Instance.new("TextLabel")
hpLabel.Name = "HPLabel"
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 14
hpLabel.Text = "100/100"
hpLabel.Parent = hpFrame

-- Crystal counter
local crystalFrame = Instance.new("Frame")
crystalFrame.Name = "CrystalFrame"
crystalFrame.Size = UDim2.new(0, 120, 0, 30)
crystalFrame.Position = UDim2.new(1, -130, 0, 10)
crystalFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
crystalFrame.BorderSizePixel = 1
crystalFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
crystalFrame.Parent = screenGui

local crystalLabel = Instance.new("TextLabel")
crystalLabel.Name = "CrystalLabel"
crystalLabel.Size = UDim2.new(1, 0, 1, 0)
crystalLabel.BackgroundTransparency = 1
crystalLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
crystalLabel.Font = Enum.Font.GothamBold
crystalLabel.TextSize = 16
crystalLabel.Text = "💎 0"
crystalLabel.Parent = crystalFrame

-- Game status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 300, 0, 50)
statusLabel.Position = UDim2.new(0.5, -150, 0.4, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 36
statusLabel.Text = ""
statusLabel.TextStrokeTransparency = 0.5
statusLabel.Visible = false
statusLabel.Parent = screenGui

-- Event handlers
Remotes.WaveStart.OnClientEvent:Connect(function(wave: number, maxWaves: number)
    waveLabel.Text = string.format("Wave %d / %d", wave, maxWaves)
    statusLabel.Text = string.format("Wave %d!", wave)
    statusLabel.Visible = true
    task.delay(2, function()
        statusLabel.Visible = false
    end)
end)

Remotes.WaveComplete.OnClientEvent:Connect(function(wave: number)
    waveLabel.Text = string.format("Wave %d Complete!", wave)
    statusLabel.Text = "Wave Clear!"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Visible = true
    task.delay(2, function()
        statusLabel.Visible = false
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end)

Remotes.GameOver.OnClientEvent:Connect(function(reason: string)
    if reason == "victory" then
        statusLabel.Text = "🎉 Victory! 🎉"
        statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        statusLabel.Text = "💀 Defeated! 💀"
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
    statusLabel.Visible = true
end)

Remotes.UpdateHUD.OnClientEvent:Connect(function(data: any)
    if data.wave then
        waveLabel.Text = string.format("Wave %d / %d", data.wave, data.maxWaves or 5)
    end
    if data.hp and data.maxHP then
        local pct = data.hp / data.maxHP
        hpFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
        hpFill.BackgroundColor3 = if pct > 0.5
            then Color3.fromRGB(0, 200, 100)
            elseif pct > 0.25
                then Color3.fromRGB(255, 200, 0)
                else Color3.fromRGB(255, 50, 50)
        hpLabel.Text = string.format("%d / %d", math.ceil(data.hp), data.maxHP)
    end
    if data.crystals then
        crystalLabel.Text = string.format("💎 %d", data.crystals)
    end
end)

-- Update HP bar from player attributes
local function updateHPFromPlayer()
    local hp = player:GetAttribute("HP") or 100
    local maxHP = player:GetAttribute("MaxHP") or 100
    local pct = hp / maxHP
    hpFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
    hpFill.BackgroundColor3 = if pct > 0.5
        then Color3.fromRGB(0, 200, 100)
        elseif pct > 0.25
            then Color3.fromRGB(255, 200, 0)
            else Color3.fromRGB(255, 50, 50)
    hpLabel.Text = string.format("%d / %d", math.ceil(hp), maxHP)
end

player:GetAttributeChangedSignal("HP"):Connect(updateHPFromPlayer)
player:GetAttributeChangedSignal("MaxHP"):Connect(updateHPFromPlayer)
player:GetAttributeChangedSignal("Crystals"):Connect(function()
    crystalLabel.Text = string.format("💎 %d", player:GetAttribute("Crystals") or 0)
end)

return nil