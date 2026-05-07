-- WaveSystem.luau — 5-wave defense sequence with difficulty ramp
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local WaveSystem = {}
WaveSystem.__index = WaveSystem

function WaveSystem.new()
    local self = setmetatable({}, WaveSystem)
    self.currentWave = 0
    self.maxWaves = Config.WAVE_COUNT
    self.waveActive = false
    self.gameActive = false
    self.players = {}
    self.enemySpawner = nil
    self.combatEngine = nil
    self.spellAssembler = nil
    self.waveThread = nil
    return self
end

function WaveSystem:setSystems(enemySpawner: any, combatEngine: any, spellAssembler: any)
    self.enemySpawner = enemySpawner
    self.combatEngine = combatEngine
    self.spellAssembler = spellAssembler
end

function WaveSystem:addPlayer(player: Player, spell: any)
    self.players[player.UserId] = {
        player = player,
        spell = spell,
    }
end

function WaveSystem:start()
    if self.gameActive then return end
    self.gameActive = true
    self.currentWave = 0
    self.waveThread = task.spawn(function()
        self:runWaves()
    end)
end

function WaveSystem:stop()
    self.gameActive = false
    self.waveActive = false
    if self.enemySpawner then
        self.enemySpawner:clearAll()
    end
end

function WaveSystem:runWaves()
    for wave = 1, self.maxWaves do
        if not self.gameActive then break end

        self.currentWave = wave
        self.waveActive = true

        -- Notify clients
        Remotes.WaveStart:FireAllClients(wave, self.maxWaves)

        -- Get wizard position (center of platform)
        local targetPos = Vector3.new(0, 5, 0)

        -- Spawn wave enemies
        if self.enemySpawner then
            self.enemySpawner:spawnWave(wave, targetPos)
        end

        -- Wait for all enemies to be defeated
        local waveTimeout = 120 -- 2 minute timeout per wave
        local startTime = tick()

        while self.gameActive and self.waveActive do
            local alive = self.enemySpawner and self.enemySpawner:getAliveEnemies() or {}

            if #alive == 0 then
                -- Wave complete!
                self.waveActive = false

                -- Award crystals
                local Players = game:GetService("Players")
                for _, player in Players:GetPlayers() do
                    local current = player:GetAttribute("Crystals") or 0
                    player:SetAttribute("Crystals", current + Config.CRYSTAL_PER_WAVE)
                end

                Remotes.WaveComplete:FireAllClients(wave)
                break
            end

            -- Check wizard HP — if any wizard is dead, game over
            for _, player in game:GetService("Players"):GetPlayers() do
                local hp = player:GetAttribute("HP") or 0
                if hp <= 0 then
                    self.gameActive = false
                    Remotes.GameOver:FireAllClients("wizards_defeated")
                    return
                end
            end

            -- Auto-cast spells for all players
            for _, playerData in self.players do
                local player = playerData.player
                local spell = playerData.spell
                if player.Character and player.Character.Parent and spell then
                    local targets = self.combatEngine:autoTarget(player, spell, alive)
                    if #targets > 0 then
                        self.combatEngine:castSpell(player, spell, targets)
                    end
                end
            end

            -- Timeout check
            if tick() - startTime > waveTimeout then
                self.waveActive = false
                break
            end

            task.wait(0.5)
        end

        -- Rest period between waves
        if self.gameActive and wave < self.maxWaves then
            task.wait(Config.WAVE_REST_TIME)
        end
    end

    -- All waves complete
    if self.gameActive then
        Remotes.GameOver:FireAllClients("victory")
    end
end

function WaveSystem:getCurrentWave(): number
    return self.currentWave
end

function WaveSystem:isGameActive(): boolean
    return self.gameActive
end

return WaveSystem