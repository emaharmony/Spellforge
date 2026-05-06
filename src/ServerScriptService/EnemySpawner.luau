-- EnemySpawner.luau — Spawn waves of basic enemies toward wizard
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner.new()
    local self = setmetatable({}, EnemySpawner)
    self.spawnedEnemies = {}
    self.spawnCounter = 0
    self.spawnFolder = Instance.new("Folder")
    self.spawnFolder.Name = "Enemies"
    self.spawnFolder.Parent = workspace
    return self
end

function EnemySpawner:spawnEnemy(enemyType: string, targetPosition: Vector3): Instance?
    local data = EnemyData.Types[enemyType]
    if not data then
        warn("[EnemySpawner] Unknown enemy type: " .. enemyType)
        return nil
    end

    self.spawnCounter += 1
    local enemy = Instance.new("Model")
    enemy.Name = data.name .. "_" .. self.spawnCounter

    -- Create primary part
    local part = Instance.new("Part")
    part.Name = "HumanoidRootPart"
    part.Size = data.size
    part.Color = data.color
    part.Material = Enum.Material.Neon
    part.Anchored = false
    part.CanCollide = true
    part.Parent = enemy

    -- Create head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(data.size.X * 0.8, data.size.Y * 0.3, data.size.Z * 0.8)
    head.Color = Color3.fromRGB(
        math.min(255, data.color.R * 255 + 40),
        math.min(255, data.color.G * 255 + 40),
        math.min(255, data.color.B * 255 + 40)
    )
    head.Material = Enum.Material.Neon
    head.Anchored = false
    head.CanCollide = true
    head.Parent = enemy

    -- Weld head to root
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = head
    weld.Parent = head

    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = data.hp
    humanoid.Health = data.hp
    humanoid.WalkSpeed = data.speed
    humanoid.Parent = enemy

    -- Set attributes for game systems
    enemy:SetAttribute("HP", data.hp)
    enemy:SetAttribute("MaxHP", data.hp)
    enemy:SetAttribute("Damage", data.damage)
    enemy:SetAttribute("AttackRange", data.attackRange)
    enemy:SetAttribute("AttackCooldown", data.attackCooldown)
    enemy:SetAttribute("CrystalDrop", data.crystalDrop)
    enemy:SetAttribute("EnemyType", enemyType)
    enemy:SetAttribute("Speed", data.speed)

    -- Position at random spawn point around the arena edge
    local angle = math.random() * math.pi * 2
    local radius = Config.PLATFORM_SIZE * 0.6
    local spawnPos = Vector3.new(
        math.cos(angle) * radius,
        5,
        math.sin(angle) * radius
    )
    part.CFrame = CFrame.new(spawnPos)
    head.CFrame = part.CFrame * CFrame.new(0, data.size.Y * 0.35, 0)

    enemy.PrimaryPart = part
    enemy.Parent = self.spawnFolder

    -- Make enemy walk toward target
    humanoid:MoveTo(targetPosition)

    -- Store reference
    table.insert(self.spawnedEnemies, enemy)

    -- Clean up on death
    enemy:GetAttributeChangedSignal("HP"):Connect(function()
        local hp = enemy:GetAttribute("HP")
        if hp and hp <= 0 then
            -- Flash and remove
            for _, p in enemy:GetDescendants() do
                if p:IsA("BasePart") then
                    p.Transparency = 0.5
                end
            end
        end
    end)

    return enemy
end

function EnemySpawner:spawnWave(waveNumber: number, targetPosition: Vector3): { Instance }
    local enemies = {}
    local count = Config.WAVE_BASE_ENEMIES + (waveNumber - 1) * Config.WAVE_ENEMY_INCREMENT

    -- Mix enemy types based on wave
    local types = EnemyData.GetAll()

    for i = 1, count do
        local enemyType
        if waveNumber <= 2 then
            -- Early waves: mostly walkers
            enemyType = math.random() < 0.7 and "walker" or "runner"
        elseif waveNumber <= 4 then
            -- Mid waves: mix of all
            local roll = math.random()
            if roll < 0.4 then
                enemyType = "walker"
            elseif roll < 0.75 then
                enemyType = "runner"
            else
                enemyType = "tank"
            end
        else
            -- Late waves: harder mix
            local roll = math.random()
            if roll < 0.3 then
                enemyType = "walker"
            elseif roll < 0.6 then
                enemyType = "runner"
            else
                enemyType = "tank"
            end
        end

        -- Stagger spawns
        task.delay(i * 0.5, function()
            local enemy = self:spawnEnemy(enemyType, targetPosition)
            if enemy then
                table.insert(enemies, enemy)
            end
        end)
    end

    return enemies
end

function EnemySpawner:getAliveEnemies(): { Instance }
    local alive = {}
    for _, enemy in self.spawnedEnemies do
        if enemy and enemy.Parent then
            local hp = enemy:GetAttribute("HP")
            if hp and hp > 0 then
                table.insert(alive, enemy)
            end
        end
    end
    return alive
end

function EnemySpawner:clearAll()
    for _, enemy in self.spawnedEnemies do
        if enemy and enemy.Parent then
            enemy:Destroy()
        end
    end
    self.spawnedEnemies = {}
end

return EnemySpawner