-- SpellAssembler.luau — Assembles 4 rune fragments into a spell, computes stats
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local FragmentData = require(ReplicatedStorage:WaitForChild("FragmentData"))
local ElementData = require(ReplicatedStorage:WaitForChild("ElementData"))

local SpellAssembler = {}

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

    -- Compute spell stats
    local rarityMult = Config.RARITY_MULTIPLIERS[power.rarity] or 1.0

    local spell = {
        fragments = fragments,
        computed = {
            damage = Config.SPELL_BASE_DAMAGE * (power.properties.multiplier or 1.0) * rarityMult,
            range = Config.SPELL_BASE_RANGE * (FragmentData.Shapes[shape.id:match("_(.+)$")] or {}).range or 1.0,
            cooldown = Config.SPELL_BASE_COOLDOWN * (FragmentData.Shapes[shape.id:match("_(.+)$")] or {}).cooldown or 1.0,
            targeting = shape.properties.targeting,
            damageType = element.properties.damageType or "pure",
            effect = if modifier.properties.effect ~= nil then modifier.properties.effect else nil,
        },
        element = element.element,
        color = element.color,
    }

    return spell
end

-- Create a hardcoded starter spell (fire bolt) for M1
function SpellAssembler.createStarterSpell(): any
    -- Fire bolt: bolt shape, fire element, ember power, split modifier
    local fragmentIds = {
        "fire_shape_bolt",
        "fire_element",
        "fire_power_ember",
        "fire_mod_split",
    }

    -- Ensure these fragments exist; if not, find alternatives
    local validatedIds = {}
    for _, fragId in fragmentIds do
        if FragmentData.ById[fragId] then
            table.insert(validatedIds, fragId)
        end
    end

    if #validatedIds ~= 4 then
        -- Fallback: pick first of each slot
        local bySlot = {}
        for _, frag in FragmentData.All do
            if not bySlot[frag.slot] then
                bySlot[frag.slot] = frag.id
            end
        end
        validatedIds = {
            bySlot.shape,
            bySlot.element,
            bySlot.power,
            bySlot.modifier,
        }
    end

    return SpellAssembler.assemble(validatedIds)
end

-- Recompute stats when a single fragment is swapped
function SpellAssembler.recompute(spell: any, newFragmentId: string): any?
    local newFrag = FragmentData.ById[newFragmentId]
    if not newFrag then return nil end

    local ids = {}
    for _, slot in Config.FRAGMENT_SLOTS do
        if slot == newFrag.slot then
            table.insert(ids, newFragmentId)
        else
            table.insert(ids, spell.fragments[slot].id)
        end
    end

    return SpellAssembler.assemble(ids)
end

return SpellAssembler