-- SpellAssembler.luau — Assembles 4 rune fragments into a spell, computes stats with v2 balance
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))
local ElementData = require(ReplicatedStorage:WaitForChild("ElementData"))

local SpellAssembler = {}

-- Compute a spell from 4 fragment IDs
function SpellAssembler.assemble(fragmentIds: { string }): any?
	-- Need exactly 4 fragments: shape, element, power, modifier
	if #fragmentIds ~= 4 then
		warn("[SpellAssembler] Need 4 fragments, got " .. #fragmentIds)
		return nil
	end

	local fragments = {}
	local slotsFilled = {}

	for _, fragId in fragmentIds do
		local frag = FragmentData.ById[fragId]
		if not frag then
			warn("[SpellAssembler] Unknown fragment: " .. fragId)
			return nil
		end
		if slotsFilled[frag.slot] then
			warn("[SpellAssembler] Duplicate slot: " .. frag.slot)
			return nil
		end
		slotsFilled[frag.slot] = true
		fragments[frag.slot] = frag
	end

	-- Validate all slots filled
	for _, slot in Config.FRAGMENT_SLOTS do
		if not fragments[slot] then
			warn("[SpellAssembler] Missing slot: " .. slot)
			return nil
		end
	end

	local shape = fragments.shape
	local element = fragments.element
	local power = fragments.power
	local modifier = fragments.modifier

	-- Get shape stats from Config
	local shapeId = shape.id:match("_shape_(.+)$")
	local shapeStats = shapeId and Config.SHAPE_MULTIPLIERS[shapeId] or Config.SHAPE_MULTIPLIERS.bolt

	-- Compute rarity multiplier from power fragment
	local rarityMult = Config.RARITY_MULTIPLIERS[power.rarity] or 1.0

	-- Compute final damage
	local baseDamage = Config.SPELL_BASE_DAMAGE
	local powerMult = power.properties and power.properties.multiplier or 1.0
	local shapeMult = shapeStats.damage
	local damage = math.floor(baseDamage * powerMult * shapeMult * rarityMult)

	-- Compute cooldown
	local baseCooldown = Config.SPELL_BASE_COOLDOWN
	local shapeCooldown = shapeStats.cooldown or 1.0
	local cooldown = baseCooldown * shapeCooldown

	-- Compute range
	local baseRange = Config.SPELL_BASE_RANGE
	local shapeRange = shapeStats.range or 1.0
	local range = math.floor(baseRange * shapeRange)

	-- Compute effect from modifier
	local effect = modifier.properties and modifier.properties.effect or "none"

	-- Get element info
	local elemInfo = ElementData.Elements[element.element or "fire"]

	-- Build computed spell
	local spell = {
		id = element.element .. "_" .. (shapeId or "bolt") .. "_" .. (power.id:match("_(.+)$") or "basic") .. "_" .. (modifier.id:match("_(.+)$") or "none"),
		name = elemInfo and elemInfo.name or "Unknown" .. " " .. (shapeId or "Spell"),
		element = element.element,
		damageType = elemInfo and elemInfo.damageType or "pure",
		damage = damage,
		cooldown = cooldown,
		range = range,
		effect = effect,
		rarity = power.rarity,
		rarityMultiplier = rarityMult,
		shape = shapeId or "bolt",
		targeting = shapeStats.targeting or "projectile",
		ticks = shapeStats.ticks, -- for beam
		projectiles = shapeStats.projectiles, -- for orbit
		bounces = shapeStats.bounces, -- for chain
		color = elemInfo and elemInfo.color or Color3.fromRGB(255, 255, 255),
		secondaryColor = elemInfo and elemInfo.secondaryColor or Color3.fromRGB(200, 200, 200),
		computed = {
			damage = damage,
			effect = effect,
			damageType = elemInfo and elemInfo.damageType or "pure",
			shape = shapeId or "bolt",
		},
		fragmentIds = fragmentIds,
	}

	return spell
end

-- Create a starter spell for new players
function SpellAssembler.createStarterSpell(): any
	-- Fire bolt: common fire element + bolt shape + common fire power + split modifier
	local elementFrag = FragmentData.ById["fire_element"]
	local shapeFrag = FragmentData.ById["fire_shape_bolt"]
	local powerFrag = FragmentData.ById["fire_power_ember"]
	local modifierFrag = FragmentData.ById["fire_mod_split"]

	if not elementFrag or not shapeFrag or not powerFrag or not modifierFrag then
		-- Fallback: just use IDs directly without FragmentData lookup
		return SpellAssembler.assemble({
			"fire_element",
			"fire_shape_bolt",
			"fire_power_ember",
			"fire_mod_split",
		})
	end

	return SpellAssembler.assemble({
		elementFrag.id,
		shapeFrag.id,
		powerFrag.id,
		modifierFrag.id,
	})
end

return SpellAssembler