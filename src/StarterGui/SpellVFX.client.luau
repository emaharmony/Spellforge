-- SpellVFX.client.luau — Phase 4: combat readability.
-- Listens for SpellFired and draws a visible spell streak from the caster's
-- staff to each target, colored by the spell's element. No damage logic here —
-- the server is truth; this is pure presentation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

-- How the streak is drawn per shape. Everything is anchored, collisionless,
-- non-casting shadow (light emission only via PointLight on impact).
local STREAK_LIFETIME = 0.35
local STREAK_THICKNESS = 0.35

local function staffTip(character: Model): Vector3?
	local staff = character:FindFirstChild("Staff", true)
	if staff and staff:IsA("BasePart") then
		-- top of the 4-stud staff
		return staff.Position + Vector3.new(0, 2, 0)
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		return hrp.Position + Vector3.new(0, 2, 0)
	end
	return nil
end

local function makeStreak(from: Vector3, to: Vector3, color: Color3, secondary: Color3)
	local dist = (to - from).Magnitude
	if dist < 1 then return end

	local part = Instance.new("Part")
	part.Name = "SpellStreak"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.new(STREAK_THICKNESS, STREAK_THICKNESS, dist)
	part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
	part.Transparency = 0.1

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 2
	light.Range = 8
	light.Parent = part

	part.Parent = workspace

	-- fade out, then clean up
	local tween = TweenService:Create(
		part,
		TweenInfo.new(STREAK_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1 }
	)
	tween:Play()
	Debris:AddItem(part, STREAK_LIFETIME + 0.05)
end

local function makeImpactBurst(at: Vector3, color: Color3)
	local burst = Instance.new("Part")
	burst.Name = "SpellImpact"
	burst.Shape = Enum.PartType.Ball
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.CastShadow = false
	burst.Material = Enum.Material.Neon
	burst.Color = color
	burst.Size = Vector3.new(1, 1, 1)
	burst.Position = at
	burst.Transparency = 0.1
	burst.Parent = workspace

	local grow = TweenService:Create(
		burst,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(3, 3, 3), Transparency = 1 }
	)
	grow:Play()
	Debris:AddItem(burst, 0.3)
end

Remotes.SpellFired.OnClientEvent:Connect(function(caster, computed, targetPositions)
	if typeof(caster) ~= "Instance" or not caster:IsA("Player") then return end
	if typeof(computed) ~= "table" then return end
	if typeof(targetPositions) ~= "table" then return end

	local character = caster.Character
	local origin = character and staffTip(character)
	if not origin then return end

	local color = computed.color or Color3.fromRGB(255, 87, 34)
	local secondary = computed.secondaryColor or color

	for _, targetPos in targetPositions do
		if typeof(targetPos) == "Vector3" then
			makeStreak(origin, targetPos, color, secondary)
			makeImpactBurst(targetPos, secondary)
		end
	end
end)