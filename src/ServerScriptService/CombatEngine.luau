-- CombatEngine.luau — Spell resolution, damage calculation, effect application
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local CombatEngine = {}
CombatEngine.__index = CombatEngine

function CombatEngine.new()
    local self = setmetatable({}, CombatEngine)
    self.activeEffects = {} -- enemy id -> { effect, endTime }
    self.castCooldowns = {} -- player id -> lastCastTime
    return self
end

function CombatEngine:canCast(player: Player): boolean
    local lastCast = self.castCooldowns[player.UserId]
    if not lastCast then return true end
    local spell = player:GetAttribute("EquippedSpell")
    if not spell then return false end
    -- Cooldown is stored in spell data; use base cooldown for now
    return tick() - lastCast >= Config.SPELL_BASE_COOLDOWN
end

function CombatEngine:castSpell(player: Player, spell: any, targets: { Instance })
    if not self:canCast(player) then return end
    self.castCooldowns[player.UserId] = tick()

    for _, target in targets do
        if target and target:GetAttribute("HP") then
            self:applyDamage(target, spell.computed.damage, player)
            self:applyEffect(target, spell.computed.effect, spell.computed.damageType)
        end
    end

    -- Notify clients
    Remotes.SpellFired:FireAllClients(player, spell.computed)
end

function CombatEngine:applyDamage(enemy: Instance, damage: number, _sourcePlayer: Player)
    local currentHP = enemy:GetAttribute("HP") or 0
    local newHP = math.max(0, currentHP - damage)
    enemy:SetAttribute("HP", newHP)

    Remotes.EnemyDamaged:FireAllClients(enemy, damage, newHP)

    if newHP <= 0 then
        self:onEnemyDeath(enemy)
    end
end

function CombatEngine:applyEffect(enemy: Instance, effect: string?, damageType: string)
    if not effect then return end

    local duration = 3 -- default effect duration
    local effectData = {
        effect = effect,
        startTime = tick(),
        endTime = tick() + duration,
        damageType = damageType,
    }

    self.activeEffects[enemy:GetDebugId()] = effectData

    -- Apply immediate effects
    if effect == "slow" then
        local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed * 0.5
            task.delay(duration, function()
                if humanoid and humanoid.Parent then
                    humanoid.WalkSpeed = humanoid.WalkSpeed * 2
                end
            end)
        end
    elseif effect == "stun" then
        local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            local origSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
            task.delay(1, function()
                if humanoid and humanoid.Parent then
                    humanoid.WalkSpeed = origSpeed
                end
            end)
        end
    elseif effect == "split" then
        -- Split effect: main projectile already hit, this just marks for VFX
    elseif effect == "pierce" then
        -- Pierce: handled in targeting (no removal after first hit)
    elseif effect == "homing" then
        -- Homing: handled in projectile logic
    elseif effect == "chain" then
        -- Chain: handled in targeting (bounces to next)
    end

    -- DoT for burn/poison damage types
    if damageType == "burn" or damageType == "poison" then
        local dotDamage = 2
        local ticks = 3
        for i = 1, ticks do
            task.delay(i, function()
                if enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                    local hp = enemy:GetAttribute("HP") - dotDamage
                    enemy:SetAttribute("HP", math.max(0, hp))
                    if hp <= 0 then
                        self:onEnemyDeath(enemy)
                    end
                end
            end)
        end
    end
end

function CombatEngine:onEnemyDeath(enemy: Instance)
    -- Award crystals to all players
    local Players = game:GetService("Players")
    local crystalReward = enemy:GetAttribute("CrystalDrop") or 1
    for _, player in Players:GetPlayers() do
        local currentCrystals = player:GetAttribute("Crystals") or 0
        player:SetAttribute("Crystals", currentCrystals + crystalReward)
    end

    -- Remove enemy after brief delay
    task.delay(0.5, function()
        if enemy and enemy.Parent then
            enemy:Destroy()
        end
    end)
end

function CombatEngine:autoTarget(player: Player, spell: any, enemies: { Instance }): { Instance }
    local wizard = player.Character
    if not wizard then return {} end

    local wizardPos = wizard:GetPivot().Position
    local targeting = spell.computed.targeting
    local range = spell.computed.range * Config.SPELL_CAST_RANGE

    local targets = {}

    if targeting == "projectile" or targeting == "chain" then
        -- Find nearest enemy in range
        local nearest = nil
        local nearestDist = math.huge
        for _, enemy in enemies do
            if enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                local dist = (enemy:GetPivot().Position - wizardPos).Magnitude
                if dist < range and dist < nearestDist then
                    nearest = enemy
                    nearestDist = dist
                end
            end
        end
        if nearest then
            table.insert(targets, nearest)
            -- Chain: add up to 2 more nearby enemies
            if targeting == "chain" then
                local chainCount = 0
                for _, enemy in enemies do
                    if enemy ~= nearest and enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                        local distToNearest = (enemy:GetPivot().Position - nearest:GetPivot().Position).Magnitude
                        if distToNearest < 20 and chainCount < 2 then
                            table.insert(targets, enemy)
                            chainCount += 1
                        end
                    end
                end
            end
        end
    elseif targeting == "aoe" or targeting == "nova" then
        -- Hit all enemies in range
        for _, enemy in enemies do
            if enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                local dist = (enemy:GetPivot().Position - wizardPos).Magnitude
                if dist < range * 0.5 then -- AOE has shorter range
                    table.insert(targets, enemy)
                end
            end
        end
    elseif targeting == "beam" then
        -- Hit nearest enemy (beam focuses on one target)
        local nearest = nil
        local nearestDist = math.huge
        for _, enemy in enemies do
            if enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                local dist = (enemy:GetPivot().Position - wizardPos).Magnitude
                if dist < range and dist < nearestDist then
                    nearest = enemy
                    nearestDist = dist
                end
            end
        end
        if nearest then
            table.insert(targets, nearest)
        end
    elseif targeting == "orbit" then
        -- Hit all nearby enemies
        for _, enemy in enemies do
            if enemy and enemy.Parent and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 then
                local dist = (enemy:GetPivot().Position - wizardPos).Magnitude
                if dist < 15 then -- Close range for orbit
                    table.insert(targets, enemy)
                end
            end
        end
    end

    return targets
end

return CombatEngine