-- GameInit.server.luau — Entry point: wires all systems, auto-starts defense with hardcoded fire-bolt spell
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ServerScriptService = game:GetService("ServerScriptService")
local SpellAssembler = require(ServerScriptService:WaitForChild("SpellAssembler"))
local CombatEngine = require(ServerScriptService:WaitForChild("CombatEngine"))
local EnemySpawner = require(ServerScriptService:WaitForChild("EnemySpawner"))
local WaveSystem = require(ServerScriptService:WaitForChild("WaveSystem"))

-- Initialize systems
local combatEngine = CombatEngine.new()
local enemySpawner = EnemySpawner.new()
local waveSystem = WaveSystem.new()

waveSystem:setSystems(enemySpawner, combatEngine, SpellAssembler)

-- Create battle platform
local platform = Instance.new("Part")
platform.Name = "BattlePlatform"
platform.Size = Vector3.new(Config.PLATFORM_SIZE, 1, Config.PLATFORM_SIZE)
platform.Position = Vector3.new(0, 0, 0)
platform.Anchored = true
platform.Color = Color3.fromRGB(40, 40, 60)
platform.Material = Enum.Material.SmoothPlastic
platform.Parent = workspace

-- Create wizard spawn point
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "WizardSpawn"
spawnLocation.Size = Vector3.new(6, 1, 6)
spawnLocation.Position = Vector3.new(0, 0.5, 0)
spawnLocation.Anchored = true
spawnLocation.CanCollide = false
spawnLocation.Transparency = 0.5
spawnLocation.Color = Color3.fromRGB(100, 200, 255)
spawnLocation.Parent = workspace

-- Enemy attack loop — enemies damage wizards they reach
local function startEnemyAttackLoop()
    task.spawn(function()
        while waveSystem:isGameActive() do
            local alive = enemySpawner:getAliveEnemies()
            for _, player in Players:GetPlayers() do
                local wizard = player.Character
                if wizard then
                    local wizardPos = wizard:GetPivot().Position
                    for _, enemy in alive do
                        if enemy and enemy.Parent then
                            local enemyPos = enemy:GetPivot().Position
                            local dist = (enemyPos - wizardPos).Magnitude
                            local attackRange = enemy:GetAttribute("AttackRange") or 5
                            if dist < attackRange then
                                -- Enemy attacks wizard
                                local hp = player:GetAttribute("HP") or 0
                                local dmg = enemy:GetAttribute("Damage") or 5
                                local newHP = math.max(0, hp - dmg)
                                player:SetAttribute("HP", newHP)

                                -- Update HUD
                                Remotes.UpdateHUD:FireClient(player, {
                                    hp = newHP,
                                    maxHP = player:GetAttribute("MaxHP") or 100,
                                })

                                -- Knock back enemy slightly
                                local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
                                if humanoid then
                                    humanoid:MoveTo(enemyPos + (enemyPos - wizardPos).Unit * 3)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(1) -- Attack every second
        end
    end)
end

-- Setup player
local function onPlayerAdded(player: Player)
    -- Set player attributes
    player:SetAttribute("HP", Config.WIZARD_START_HP)
    player:SetAttribute("MaxHP", Config.WIZARD_START_HP)
    player:SetAttribute("Crystals", 0)

    -- Create starter spell
    local starterSpell = SpellAssembler.createStarterSpell()
    if starterSpell then
        player:SetAttribute("EquippedSpell", "fire_bolt")
        waveSystem:addPlayer(player, starterSpell)
    end

    -- Create wizard character
    player.CharacterAdded:Connect(function(character)
        -- Tag wizard
        character:SetAttribute("IsWizard", true)

        -- Give wizard a staff (visual)
        local staff = Instance.new("Part")
        staff.Name = "Staff"
        staff.Size = Vector3.new(0.3, 4, 0.3)
        staff.Color = Color3.fromRGB(139, 90, 43)
        staff.Material = Enum.Material.Wood
        staff.Anchored = false
        staff.CanCollide = false
        staff.Parent = character

        local staffWeld = Instance.new("WeldConstraint")
        staffWeld.Part0 = character:WaitForChild("HumanoidRootPart")
        staffWeld.Part1 = staff
        staffWeld.Parent = staff

        -- Position staff to the right
        staff.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(1.5, 0, 0)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in game
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

-- Auto-start after a brief delay
task.delay(5, function()
    print("[Spellforge] Auto-starting defense!")
    waveSystem:start()
    startEnemyAttackLoop()
end)

print("[Spellforge] GameInit loaded — auto-start in 5 seconds")