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
waveSystem:setSystems(enemySpawner, combatEngine, SpellAssembler, fragmentDropper, crystalManager)
crystalManager:setFragmentDropper(fragmentDropper)
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
									-- Player died — notify for co-op revive
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

-- Boss special attack loop
local function startBossAttackLoop()
	task.spawn(function()
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

-- Setup player
local function onPlayerAdded(player: Player)
	-- Load persistent data
	local data = dataManager:loadData(player)

	-- Set player attributes
	local maxHP = data.maxHPUnlocked and 120 or 100
	player:SetAttribute("HP", maxHP) -- Start at full HP
	player:SetAttribute("MaxHP", maxHP)
	player:SetAttribute("Crystals", data.crystals or 0)

	-- Create starter spell
	local starterSpell = SpellAssembler.createStarterSpell()
	if starterSpell then
		player:SetAttribute("EquippedSpell", "fire_bolt")
		waveSystem:addPlayer(player, starterSpell)
	end

	-- Set element bias
	fragmentDropper:setElementBias(player, "fire")

	-- Create wizard character
	player.CharacterAdded:Connect(function(character)
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

		staff.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(1.5, 0, 0)
	end)

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

	-- Handle spell assembly
	Remotes.AssembleSpell.OnServerEvent:Connect(function(requestingPlayer, fragmentIds)
		if requestingPlayer == player and typeof(fragmentIds) == "table" then
			local spell = SpellAssembler.assemble(fragmentIds)
			if spell then
				player:SetAttribute("EquippedSpell", spell.id)
				waveSystem.players[player.UserId].spell = spell
				Remotes.SpellAssembled:FireClient(player, spell)

				-- Update element bias
				coopManager:setPlayerElement(player, spell.element)
			end
		end
	end)
end

-- Handle player removal
Players.PlayerRemoving:Connect(function(player)
	dataManager:onPlayerRemoving(player)
end)

-- Handle players already in game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Auto-start after a brief delay
task.delay(5, function()
	print("[Spellforge v2] Auto-starting defense!")
	waveSystem:start()
	startEnemyAttackLoop()
	startBossAttackLoop()
	dataManager:startAutoSave()
end)

print("[Spellforge v2] GameInit loaded — auto-start in 5 seconds")