-- FragmentData.luau — All rune fragment definitions (6 elements × ~9 fragments = 54)
local Config = require(game.ReplicatedStorage:WaitForChild("Config"))

local FragmentData = {}

-- Shape fragments
FragmentData.Shapes = {
    bolt = { slot = "shape", targeting = "projectile", range = 1.0, cooldown = 1.0, description = "Single projectile" },
    nova = { slot = "shape", targeting = "aoe", range = 0.5, cooldown = 1.5, description = "Area explosion around wizard" },
    beam = { slot = "shape", targeting = "beam", range = 1.5, cooldown = 0.8, description = "Continuous beam" },
    orbit = { slot = "shape", targeting = "orbit", range = 0.7, cooldown = 2.0, description = "Orbiting projectiles" },
    chain = { slot = "shape", targeting = "chain", range = 0.8, cooldown = 1.2, description = "Bounces between enemies" },
}

-- Power fragments (per element family)
FragmentData.Powers = {
    ember = { slot = "power", element = "fire", multiplier = 1.0, rarity = "common" },
    inferno = { slot = "power", element = "fire", multiplier = 1.5, rarity = "uncommon" },
    supernova = { slot = "power", element = "fire", multiplier = 2.5, rarity = "rare" },
    frost = { slot = "power", element = "ice", multiplier = 1.0, rarity = "common" },
    blizzard = { slot = "power", element = "ice", multiplier = 1.5, rarity = "uncommon" },
    absolute_zero = { slot = "power", element = "ice", multiplier = 2.5, rarity = "rare" },
    spark = { slot = "power", element = "lightning", multiplier = 1.0, rarity = "common" },
    thunder = { slot = "power", element = "lightning", multiplier = 1.5, rarity = "uncommon" },
    tempest = { slot = "power", element = "lightning", multiplier = 2.5, rarity = "rare" },
    shade = { slot = "power", element = "shadow", multiplier = 1.0, rarity = "common" },
    void = { slot = "power", element = "shadow", multiplier = 1.5, rarity = "uncommon" },
    eclipse = { slot = "power", element = "shadow", multiplier = 2.5, rarity = "rare" },
    thorn = { slot = "power", element = "nature", multiplier = 1.0, rarity = "common" },
    vine = { slot = "power", element = "nature", multiplier = 1.5, rarity = "uncommon" },
    world_tree = { slot = "power", element = "nature", multiplier = 2.5, rarity = "rare" },
    arc_spark = { slot = "power", element = "arcane", multiplier = 1.0, rarity = "common" },
    blast = { slot = "power", element = "arcane", multiplier = 1.5, rarity = "uncommon" },
    singularity = { slot = "power", element = "arcane", multiplier = 2.5, rarity = "rare" },
}

-- Modifier fragments
FragmentData.Modifiers = {
    split = { slot = "modifier", effect = "split", description = "Projectile splits into 3" },
    pierce = { slot = "modifier", effect = "pierce", description = "Passes through enemies" },
    slow = { slot = "modifier", effect = "slow", description = "Slows enemy by 50% for 3s" },
    stun = { slot = "modifier", effect = "stun", description = "Stuns enemy for 1s" },
    homing = { slot = "modifier", effect = "homing", description = "Homes toward nearest enemy" },
    chain_effect = { slot = "modifier", effect = "chain", description = "Effect spreads to nearby enemies" },
}

-- Element-to-shape mapping (which shapes each element can use)
FragmentData.ElementShapes = {
    fire = { "bolt", "nova", "beam" },
    ice = { "bolt", "nova", "orbit" },
    lightning = { "chain", "beam", "bolt" },
    shadow = { "beam", "orbit", "nova" },
    nature = { "bolt", "nova", "orbit" },
    arcane = { "beam", "nova", "chain" },
}

-- Element-to-modifier mapping
FragmentData.ElementModifiers = {
    fire = { "split", "pierce" },
    ice = { "slow", "stun" },
    lightning = { "chain_effect", "homing" },
    shadow = { "pierce", "homing" },
    nature = { "slow", "split" },
    arcane = { "split", "chain_effect" },
}

-- Build full fragment list with IDs
local ElementData = require(game.ReplicatedStorage:WaitForChild("ElementData"))

FragmentData.All = {}

-- Generate element fragments (shape + element combined)
for elemId, elemInfo in ElementData.Elements do
    -- Element base fragment
    table.insert(FragmentData.All, {
        id = elemId .. "_element",
        slot = "element",
        element = elemId,
        rarity = "common",
        properties = {
            damageType = elemInfo.damageType,
        },
        color = elemInfo.color,
        description = elemInfo.name .. " element",
    })

    -- Shape fragments for this element
    for _, shapeId in FragmentData.ElementShapes[elemId] do
        local shape = FragmentData.Shapes[shapeId]
        table.insert(FragmentData.All, {
            id = elemId .. "_shape_" .. shapeId,
            slot = "shape",
            element = elemId,
            rarity = "common",
            properties = {
                targeting = shape.targeting,
            },
            color = elemInfo.color,
            description = elemInfo.name .. " " .. shapeId,
        })
    end

    -- Power fragments
    for powerName, powerDef in FragmentData.Powers do
        if powerDef.element == elemId then
            table.insert(FragmentData.All, {
                id = elemId .. "_power_" .. powerName,
                slot = "power",
                element = elemId,
                rarity = powerDef.rarity,
                properties = {
                    multiplier = powerDef.multiplier,
                },
                color = elemInfo.color,
                description = powerName:gsub("_", " ") .. " power",
            })
        end
    end

    -- Modifier fragments
    for _, modId in FragmentData.ElementModifiers[elemId] do
        local mod = FragmentData.Modifiers[modId]
        table.insert(FragmentData.All, {
            id = elemId .. "_mod_" .. modId,
            slot = "modifier",
            element = elemId,
            rarity = "uncommon",
            properties = {
                effect = mod.effect,
            },
            color = elemInfo.color,
            description = mod.description,
        })
    end
end

-- Lookup by ID
FragmentData.ById = {}
for _, frag in FragmentData.All do
    FragmentData.ById[frag.id] = frag
end

-- Get fragments by slot
function FragmentData.GetBySlot(slot: string): { any }
    local result = {}
    for _, frag in FragmentData.All do
        if frag.slot == slot then
            table.insert(result, frag)
        end
    end
    return result
end

-- Get fragments by element
function FragmentData.GetByElement(element: string): { any }
    local result = {}
    for _, frag in FragmentData.All do
        if frag.element == element then
            table.insert(result, frag)
        end
    end
    return result
end

return FragmentData