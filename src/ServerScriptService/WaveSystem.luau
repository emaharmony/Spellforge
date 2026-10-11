-- WaveSystem.luau — 10-wave defense sequence with deliberate composition, boss wave, and rest phases
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local WaveSystem = {}
WaveSystem.__index = WaveSystem

function WaveSystem.new()
	local self = setmetatable({}, WaveSystem)
	self.currentWave = 0
	self.maxWaves = Config.TOTAL_WAVES
	self.waveActive = false
	self.gameActive = false
	self.players = {}
	self.enemySpawner = nil
	self.combatEngine = nil
	self.spellAssembler = nil
	self.fragmentDropper = nil
	self.crystalManager = nil
	self.fragmentInventory = nil
	self.dataManager = nil
	self.waveThread = nil
	self.runStats = nil -- populated in start(): { kills, crystalsEarned, startedAt }
	self.readyPlayers = {} -- player id -> bool
	self.combatState = {} -- player id -> { inCombat: bool, lastCombatTime: number }
	return self
end

function WaveSystem:setSystems(enemySpawner: any, combatEngine: any, spellAssembler: any, fragmentDropper: any, crystalManager: any, fragmentInventory: any, dataManager: any)
	self.enemySpawner = enemySpawner
	self.combatEngine = combatEngine
	self.spellAssembler = spellAssembler
	self.fragmentDropper = fragmentDropper
	self.crystalManager = crystalManager
	self.fragmentInventory = fragmentInventory
	self.dataManager = dataManager
end

function WaveSystem:addPlayer(player: Player, spell: any)
	self.players[player.UserId] = {
		player = player,
		spell = spell,
	}
	self.combatState[player.UserId] = {
		inCombat = false,
		lastCombatTime = 0,
	}
end

-- Grant a fragment drop: server inventory is truth, notify + sync the client
function WaveSystem:grantFragment(player: Player, frag: any)
	if not (frag and frag.id) then return end
	if self.fragmentInventory then
		self.fragmentInventory:addFragment(player, frag.id, 1)
	else
		-- No inventory wired (shouldn't happen) — still notify for visibility
		Remotes.FragmentReceived:FireClient(player, frag)
	end
end

function WaveSystem:isGameActive(): boolean
	return self.gameActive
end

function WaveSystem:start()
	if self.gameActive then return end
	self.gameActive = true
	self.currentWave = 0
	self.runStats = { kills = 0, crystalsEarned = 0, startedAt = tick() }

	-- Reset systems
	if self.fragmentDropper then
		self.fragmentDropper:reset()
	end

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
	if self.waveThread then
		pcall(task.cancel, self.waveThread)
		self.waveThread = nil
	end
end

-- Ready up system for rest phase
function WaveSystem:readyUp(player: Player)
	self.readyPlayers[player.UserId] = true

	-- Check if all players are ready
	local allReady = true
	for userId, _ in self.players do
		if not self.readyPlayers[userId] then
			allReady = false
			break
		end
	end

	if allReady then
		-- Skip rest phase, start next wave
		-- The rest phase loop checks readyPlayers
	end
end

function WaveSystem:setCombatState(player: Player, inCombat: boolean)
	if self.combatState[player.UserId] then
		self.combatState[player.UserId].inCombat = inCombat
		if inCombat then
			self.combatState[player.UserId].lastCombatTime = tick()
		end
	end
end

function WaveSystem:getCombatState(player: Player): boolean
	local state = self.combatState[player.UserId]
	if not state then return false end
	return state.inCombat
end

function WaveSystem:runWaves()
	for wave = 1, self.maxWaves do
		if not self.gameActive then return end -- defeated/rested mid-run; don't keep firing waves
		self.currentWave = wave
		local composition = Config.WAVE_COMPOSITION[wave]

		-- Notify clients
		Remotes.WaveStart:FireAllClients(wave, self.maxWaves, composition.description)

		-- Set all players to in-combat
		for userId, _ in self.players do
			local state = self.combatState[userId]
			if state then
				state.inCombat = true
				state.lastCombatTime = tick()
			end
		end

		-- Spawn wave
		self.waveActive = true
		self:spawnWave(composition)

		-- Wait for all enemies to be defeated
		self:waitForWaveEnd()

		self.waveActive = false

		-- Set all players to out-of-combat
		for userId, _ in self.players do
			local state = self.combatState[userId]
			if state then
				state.inCombat = false
			end
		end

		-- Award wave completion
		local waveCrystals = Config.CRYSTAL_PER_WAVE_BASE * wave
		if self.runStats then
			self.runStats.crystalsEarned += waveCrystals * #self.players
		end
		for userId, data in self.players do
			if data.player and data.player.Parent then
				if self.crystalManager then
					self.crystalManager:awardCrystals(data.player, waveCrystals)
				end

				-- Drop fragments
				if self.fragmentDropper then
					local drops = self.fragmentDropper:dropForWave(data.player, wave)
					for _, frag in drops do
						self:grantFragment(data.player, frag)
					end
				end

				-- Update HUD
				Remotes.UpdateHUD:FireClient(data.player, {
					wave = wave,
					maxWaves = self.maxWaves,
					crystals = data.player:GetAttribute("Crystals") or 0,
				})
			end
		end

		-- Notify wave complete
		Remotes.WaveComplete:FireAllClients(wave, composition.description)

		-- Rest phase (crafting, shop, ready-up)
		if wave < self.maxWaves then
			self:restPhase(wave)
		end
	end

	-- Victory!
	self:announceGameOver("victory")
end

-- Broadcast end-of-run with stats and reset run state so start() can run again.
function WaveSystem:announceGameOver(reason: string)
	local victory = reason == "victory"
	local wavesCompleted = victory and self.maxWaves or math.max(self.currentWave - 1, 0)
	local kills = self.runStats and self.runStats.kills or 0

	-- Phase 3 SF-110: persist run stats FIRST so isBest is known before the
	-- results screen renders (first full clear announces the Max HP unlock).
	local isFirstFullClear = false
	if self.dataManager then
		for _, data in self.players do
			if data.player and data.player.Parent then
				local prevBest = self.dataManager:getBestWave(data.player)
				self.dataManager:recordRunCompletion(data.player, wavesCompleted, victory, kills)
				if victory and wavesCompleted > prevBest then
					isFirstFullClear = true
				end
			end
		end
	end

	Remotes.GameOver:FireAllClients(reason, {
		wave = math.min(self.currentWave, self.maxWaves),
		maxWaves = self.maxWaves,
		kills = kills,
		crystalsEarned = self.runStats and self.runStats.crystalsEarned or 0,
		victory = victory,
		isBest = isFirstFullClear,
	})

	self.gameActive = false
	self.waveActive = false
end

-- Full reset so a finished run can be replayed (Phase 1 run integrity).
function WaveSystem:reset()
	if self.waveThread then
		task.cancel(self.waveThread)
		self.waveThread = nil
	end
	self:stop()
	self.currentWave = 0
	self.readyPlayers = {}
	self.combatState = {}
	self.runStats = nil
	for _, enemy in self.enemySpawner and self.enemySpawner.spawnedEnemies or {} do
		if enemy and enemy.Parent then
			enemy:Destroy()
		end
	end
	if self.enemySpawner then
		self.enemySpawner.spawnedEnemies = {}
	end
end

-- Track a kill with its crystal credit (called via co-op onEnemyDeath only)
function WaveSystem:recordKill(crystalAmount: number)
	if self.runStats then
		self.runStats.kills += 1
		self.runStats.crystalsEarned += crystalAmount or 0
	end
end

function WaveSystem:spawnWave(composition: any)
	if composition.isBoss then
		-- Boss wave — warn clients BEFORE the spawn (SF-130: remote existed, never fired)
		Remotes.BossWarning:FireAllClients({
			name = "Amber Colossus",
			wave = self.currentWave,
		})
		self.enemySpawner:spawnEnemy("boss", Vector3.new(0, 5, -30))
	else
		-- Regular wave — spawn from edges
		local enemies = composition.enemies
		for enemyType, count in enemies do
			for i = 1, count do
				-- Spawn from random positions around the platform edge
				local angle = math.random() * math.pi * 2
				local radius = Config.PLATFORM_SIZE * 0.45
				local spawnPos = Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
				self.enemySpawner:spawnEnemy(enemyType, spawnPos)
			end
		end
	end
end

function WaveSystem:waitForWaveEnd()
	-- Poll until all enemies are defeated
	while self.waveActive and self.gameActive do
		local aliveCount = self.enemySpawner:getAliveCount()
		if aliveCount == 0 then
			return
		end

		-- Check if any players are dead
		local allDead = true
		for userId, data in self.players do
			if data.player and data.player.Parent then
				local hp = data.player:GetAttribute("HP") or 0
				if hp > 0 then
					allDead = false
				end
			end
		end

		if allDead then
			-- All players dead — game over
			self:announceGameOver("defeated")
			return
		end

		task.wait(0.5)
	end
end

function WaveSystem:restPhase(completedWave: number)
	self.readyPlayers = {}

	local restEndTime = tick() + Config.WAVE_REST_TIME
	Remotes.UpdateHUD:FireAllClients({
		restPhase = true,
		restTime = Config.WAVE_REST_TIME,
		completedWave = completedWave,
		nextWave = completedWave + 1,
	})
	-- Crafting UI auto-opens during rest (SpellforgeUI listens on this)
	Remotes.RestPhase:FireAllClients({
		restPhase = true,
		restTime = Config.WAVE_REST_TIME,
		completedWave = completedWave,
		nextWave = completedWave + 1,
	})

	-- Wait for rest period or all players ready
	while tick() < restEndTime and self.gameActive do
		-- Check if all players are ready
		local allReady = true
		local playerCount = 0
		for userId, _ in self.players do
			playerCount += 1
			if not self.readyPlayers[userId] then
				allReady = false
			end
		end

		if allReady and playerCount > 0 then
			break -- All ready, start next wave early
		end

		task.wait(0.5)
	end

	self.readyPlayers = {}
end

function WaveSystem:onEnemyDeath(enemy: Instance, killedBy: Player?)
	-- Once-per-enemy latch: two casts landing on the same target before its
	-- 0.5s Destroy must not pay double crystals/fragments.
	if enemy:GetAttribute("DeathProcessed") then return end
	enemy:SetAttribute("DeathProcessed", true)

	-- Award crystals
	if killedBy and self.crystalManager then
		local enemyRarity = enemy:GetAttribute("Rarity") or "common"
		local crystalAmount = Config.CRYSTAL_PER_KILL[enemyRarity] or 1

		-- Co-op split: 70% to killer, 30% to others
		local killerCrystals = math.ceil(crystalAmount * Config.COOP_CRYSTAL_SPLIT.killer)
		self.crystalManager:awardCrystals(killedBy, killerCrystals)

		local otherPlayers = {}
		for userId, data in self.players do
			if data.player ~= killedBy and data.player and data.player.Parent then
				table.insert(otherPlayers, data.player)
			end
		end

		if #otherPlayers > 0 then
			local otherShare = math.floor(crystalAmount * Config.COOP_CRYSTAL_SPLIT.others / #otherPlayers)
			if otherShare > 0 then
				for _, otherPlayer in otherPlayers do
					self.crystalManager:awardCrystals(otherPlayer, otherShare)
				end
			end
		end

		-- Fragment drop on kill
		if self.fragmentDropper then
			local fragDrop = self.fragmentDropper:dropForKill(killedBy)
			if fragDrop then
				self:grantFragment(killedBy, fragDrop)
			end
		end

		-- Track kill for element bias
		if self.fragmentDropper then
			self.fragmentDropper:recordKill(killedBy, enemyRarity)
		end

		self:recordKill(crystalAmount)
	end
end

return WaveSystem