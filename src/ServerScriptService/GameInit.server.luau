-- GameInit.server.luau — Entry point for Spellforge v2: wires all systems, 10-wave defense with crafting and shop
print("[Spellforge v2] GameInit starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ServerScriptService = game:GetService("ServerScriptService")

local SpellAssembler = require(ServerScriptService:WaitForChild("SpellAssembler"))
local CombatEngine = require(ServerScriptService:WaitForChild("CombatEngine"))
local EnemySpawner = require(ServerScriptService:WaitForChild("EnemySpawner"))
local WaveSystem = require(ServerScriptService:WaitForChild("WaveSystem"))
local FragmentDropper = require(ServerScriptService:WaitForChild("FragmentDropper"))
local FragmentInventory = require(ServerScriptService:WaitForChild("FragmentInventory"))
local CrystalManager = require(ServerScriptService:WaitForChild("CrystalManager"))
local CoopManager = require(ServerScriptService:WaitForChild("CoopManager"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))

-- Initialize systems
local combatEngine = CombatEngine.new()
local enemySpawner = EnemySpawner.new()
local waveSystem = WaveSystem.new()
local fragmentDropper = FragmentDropper.new()
local fragmentInventory = FragmentInventory.new()
local crystalManager = CrystalManager.new()
local coopManager = CoopManager.new()
local dataManager = DataManager.new()

-- Wire systems together
waveSystem:setSystems(enemySpawner, combatEngine, SpellAssembler, fragmentDropper, crystalManager, fragmentInventory, dataManager)
combatEngine:setWaveSystem(waveSystem)
crystalManager:setFragmentDropper(fragmentDropper)
crystalManager:setFragmentInventory(fragmentInventory)
dataManager.getFragmentsSnapshot = function(plr: Player)
	return fragmentInventory:getFragments(plr)
end
crystalManager:setupRemotes()

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

-- Health regeneration (out of combat only)
task.spawn(function()
	while true do
		task.wait(1)
		if waveSystem:isGameActive() then
			for _, player in Players:GetPlayers() do
				local inCombat = waveSystem:getCombatState(player)
				if not inCombat then
					local hp = player:GetAttribute("HP") or 0
					local maxHP = player:GetAttribute("MaxHP") or 100
					if hp > 0 and hp < maxHP then
						local newHP = math.min(hp + Config.WIZARD_REGEN_OOC, maxHP)
						player:SetAttribute("HP", newHP)
						Remotes.UpdateHUD:FireClient(player, {
							hp = newHP,
							maxHP = maxHP,
						})
					end
				end
			end
		end
	end
end)

-- Attack loops are per-run: each restarts itself while the run is active/ending.
-- Threads are tracked so a reset can cancel stragglers mid-restart.
local loopThreads = {}

-- Enemy attack loop — enemies damage wizards they reach
local function startEnemyAttackLoop()
	loopThreads.enemy = task.spawn(function()
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

								-- Boss has special attacks
								if enemy:GetAttribute("IsBoss") then
									-- Boss stomp (primary)
									dmg = Config.BOSS.damage_stomp
								end

								local newHP = math.max(0, hp - dmg)
								player:SetAttribute("HP", newHP)

								-- Set player in combat
								waveSystem:setCombatState(player, true)

								Remotes.UpdateHUD:FireClient(player, {
									hp = newHP,
									maxHP = player:GetAttribute("MaxHP") or 100,
								})

								if newHP <= 0 then
									-- Player died — drop the body (respawn in ~5s) + notify
									local humanoid = wizard and wizard:FindFirstChildWhichIsA("Humanoid")
									if humanoid and humanoid.Health > 0 then
										humanoid.Health = 0
									end
									Remotes.GameOver:FireClient(player, "died_waiting_revive")
								end
							end
						end
					end
				end
			end
			task.wait(1)
		end
	end)
end

-- M1 wizard auto-attack loop — the missing piece of the game loop.
-- Nothing called CombatEngine:castSpell, so enemies were unkillable and
-- waves could never complete. Each wizard periodically auto-targets the
-- nearest enemy in spell range and casts. Manual casting is M2.
local function startWizardAttackLoop()
	loopThreads.wizard = task.spawn(function()
		while waveSystem:isGameActive() do
			for _, player in Players:GetPlayers() do
				local playerData = waveSystem.players[player.UserId]
				local spell = playerData and playerData.spell
				if spell and player.Character and (player:GetAttribute("HP") or 0) > 0 then
					local targets = combatEngine:autoTarget(player, spell, enemySpawner:getAliveEnemies())
					if #targets > 0 then
						combatEngine:castSpell(player, spell, targets)
					end
				end
			end
			task.wait(0.25) -- fine tick; castSpell enforces per-player cooldowns
		end
	end)
end

-- Boss special attack loop
local function startBossAttackLoop()
	loopThreads.boss = task.spawn(function()
		while waveSystem:isGameActive() do
			local boss = enemySpawner:getBoss()
			if boss and boss.Parent then
				-- Crystal Rain attack
				local players = Players:GetPlayers()
				for _, player in players do
					if player.Character then
						local pos = player.Character:GetPivot().Position
						local bossPos = boss:GetPivot().Position
						if (pos - bossPos).Magnitude < Config.BOSS.rain_range then
							local hp = player:GetAttribute("HP") or 0
							local totalDmg = Config.BOSS.damage_rain * Config.BOSS.rain_projectiles
							local newHP = math.max(0, hp - totalDmg)
							player:SetAttribute("HP", newHP)
							Remotes.UpdateHUD:FireClient(player, {
								hp = newHP,
								maxHP = player:GetAttribute("MaxHP") or 100,
							})
						end
					end
				end
			end
			task.wait(Config.BOSS.rain_cooldown)
		end
	end)
end

-- Arena walls: keep wizards and enemies on the platform (Phase 1 run integrity)
do
	local half = Config.PLATFORM_SIZE / 2
	local wallThickness = 2
	local wallHeight = 24
	for i, size in {
		Vector3.new(Config.PLATFORM_SIZE + wallThickness * 2, wallHeight, wallThickness), -- north/south
		Vector3.new(wallThickness, wallHeight, Config.PLATFORM_SIZE + wallThickness * 2), -- east/west
	} do
		for sign = -1, 1, 2 do
			local wall = Instance.new("Part")
			wall.Name = "ArenaWall"
			wall.Size = size
			wall.Anchored = true
			wall.Transparency = 1
			-- invisible but solid; CanCollide defaults true
			if i == 1 then
				wall.Position = Vector3.new(0, wallHeight / 2, sign * (half + wallThickness / 2))
			else
				wall.Position = Vector3.new(sign * (half + wallThickness / 2), wallHeight / 2, 0)
			end
			wall.Parent = workspace
		end
	end
end

-- Run restart (Phase 1): PlayAgain → full teardown → fresh run
local function startRun()
	waveSystem:reset()
	combatEngine:resetRun()
	-- Fresh run = everyone at full health (survivors keep crystals/fragments)
	for _, plr in Players:GetPlayers() do
		local maxHP = plr:GetAttribute("MaxHP") or 100
		plr:SetAttribute("HP", maxHP)
		local humanoid = plr.Character and plr.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			plr:LoadCharacter() -- regenerate standing wizards for the new run
		end
	end
	waveSystem:start()
	startEnemyAttackLoop()
	startWizardAttackLoop()
	startBossAttackLoop()
end

Remotes.PlayAgain.OnServerEvent:Connect(function(player)
	-- Any player can trigger restart once the run has ended (prototype co-op etiquette)
	if not waveSystem:isGameActive() then
		print("[Spellforge v2] Restart requested by", player.Name)
		startRun()
	end
end)

-- Setup player
local function onPlayerAdded(player: Player)
	-- Load persistent data
	local data = dataManager:loadData(player)

	-- Set player attributes
	local maxHP = data.maxHPUnlocked and 120 or 100
	player:SetAttribute("HP", maxHP) -- Start at full HP
	player:SetAttribute("MaxHP", maxHP)
	player:SetAttribute("Crystals", data.crystals or 0)

	-- Equip spell: saved recipe wins (rejoin restores the crafted spell,
	-- re-assembled free of charge — fragments were already consumed), else starter.
	local equippedSpell = nil
	local savedRecipe = dataManager:getSavedSpell(player)
	if savedRecipe then
		local rebuilt = SpellAssembler.assemble(savedRecipe)
		if rebuilt then
			equippedSpell = rebuilt
		end
	end
	if not equippedSpell then
		equippedSpell = SpellAssembler.createStarterSpell()
	end
	if equippedSpell then
		player:SetAttribute("EquippedSpell", equippedSpell.id)
		waveSystem:addPlayer(player, equippedSpell)
	end

	-- Seed server inventory from persisted data; new players get the starter kit
	local savedCount = 0
	for fragId, count in pairs(data.fragments or {}) do
		if typeof(fragId) == "string" and typeof(count) == "number" and count > 0 then
			fragmentInventory:addFragment(player, fragId, count)
			savedCount += count
		end
	end
	if savedCount == 0 then
		-- Starter kit: exactly the fragments that make the starter spell re-craftable
		for _, fragId in { "fire_element", "fire_shape_bolt", "fire_power_ember", "fire_mod_split" } do
			fragmentInventory:addFragment(player, fragId, 1)
		end
	end
	fragmentInventory:sync(player)

	-- Set element bias
	fragmentDropper:setElementBias(player, "fire")

	-- Create wizard character
	local function onCharacterAdded(character: Model)
	
		character:SetAttribute("IsWizard", true)
		-- Respawned/rejoined: fresh HP (attribute doesn't reset on death by itself)
		player:SetAttribute("HP", player:GetAttribute("MaxHP") or 100)
		Remotes.UpdateHUD:FireClient(player, {
			hp = player:GetAttribute("MaxHP") or 100,
			maxHP = player:GetAttribute("MaxHP") or 100,
		})

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

		staff.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(1.5, 0, 0)
	end

	-- SF-140a: respawn guarantee. Roblox respawns at SpawnLocation which drifts
	-- (PT-001 saw -9,-9); explicitly place every character on the spawn pad.
	local function placeOnPlatform(character: Model)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			hrp.CFrame = CFrame.new(0, 3, 0)
		end
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character)
		placeOnPlatform(character)
	end)
	if player.Character then
		onCharacterAdded(player.Character)
		placeOnPlatform(player.Character)
	end

	-- Handle heal request
	Remotes.HealWithCrystals.OnServerEvent:Connect(function(requestingPlayer)
		if requestingPlayer == player then
			crystalManager:healPlayer(player)
		end
	end)

	-- Handle ready-up
	Remotes.ReadyUp.OnServerEvent:Connect(function(requestingPlayer)
		if requestingPlayer == player then
			waveSystem:readyUp(player)
		end
	end)

	-- Handle Max HP upgrade purchase (Phase 3 SF-111)
	Remotes.BuyMaxHP.OnServerEvent:Connect(function(requestingPlayer)
		if requestingPlayer == player then
			local ok, reason = dataManager:buyMaxHPUpgrade(player)
			Remotes.ShopResult:FireClient(player, ok, {
				item = "max_hp",
				cost = 150,
				reason = reason,
			})
			if ok then
				-- Refill to the new max so the purchase feels immediate
				local newMax = player:GetAttribute("MaxHP") or 120
				player:SetAttribute("HP", newMax)
				Remotes.UpdateHUD:FireClient(player, {
					hp = newMax,
					maxHP = newMax,
				})
			end
		end
	end)

	-- Handle spell assembly — the economy gate:validate ownership, then deduct
	Remotes.AssembleSpell.OnServerEvent:Connect(function(requestingPlayer, fragmentIds)
		if requestingPlayer ~= player or typeof(fragmentIds) ~= "table" then return end
		if #fragmentIds ~= 4 then return end
		for _, fragId in fragmentIds do
			if typeof(fragId) ~= "string" then return end
		end

		-- Server inventory is truth: player must own every fragment
		if not fragmentInventory:hasAllFragments(player, fragmentIds) then
			Remotes.SpellAssembled:FireClient(player, nil, "missing_fragments")
			return
		end

		local spell = SpellAssembler.assemble(fragmentIds)
		if not spell then
			Remotes.SpellAssembled:FireClient(player, nil, "invalid_recipe")
			return
		end

		-- Consume the four fragments (inventory syncs automatically)
		fragmentInventory:removeFragments(player, fragmentIds)

		player:SetAttribute("EquippedSpell", spell.id)
		waveSystem.players[player.UserId].spell = spell
		Remotes.SpellAssembled:FireClient(player, spell)

		-- Phase 3 SF-110: persist the equipped spell's recipe for rejoin restore
		dataManager:saveEquippedSpell(player, spell)

		-- Update element bias
		coopManager:setPlayerElement(player, spell.element)
	end)
end

-- Handle player removal
Players.PlayerRemoving:Connect(function(player)
	dataManager:onPlayerRemoving(player)
end)

-- Handle joins after startup (was missing: only the "already in game" loop ran,
-- so players joining after script start were never registered as defenders)
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Auto-start after a brief delay
task.delay(5, function()
	print("[Spellforge v2] Auto-starting defense!")
	startRun()
	dataManager:startAutoSave()
end)

print("[Spellforge v2] GameInit loaded — auto-start in 5 seconds")