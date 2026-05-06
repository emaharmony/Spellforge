-- ElementData.luau — Element color families and VFX references
local ElementData = {}

ElementData.Elements = {
    fire = {
        id = "fire",
        name = "Fire",
        color = Color3.fromRGB(255, 87, 34),
        secondaryColor = Color3.fromRGB(255, 152, 0),
        damageType = "burn",
        vfx = {
            projectile = "rbxassetid://fire_projectile",
            impact = "rbxassetid://fire_impact",
            aura = "rbxassetid://fire_aura",
        },
        description = "Burns enemies over time",
    },
    ice = {
        id = "ice",
        name = "Ice",
        color = Color3.fromRGB(100, 200, 255),
        secondaryColor = Color3.fromRGB(200, 240, 255),
        damageType = "slow",
        vfx = {
            projectile = "rbxassetid://ice_projectile",
            impact = "rbxassetid://ice_impact",
            aura = "rbxassetid://ice_aura",
        },
        description = "Slows and freezes enemies",
    },
    lightning = {
        id = "lightning",
        name = "Lightning",
        color = Color3.fromRGB(255, 255, 100),
        secondaryColor = Color3.fromRGB(255, 255, 200),
        damageType = "instant",
        vfx = {
            projectile = "rbxassetid://lightning_projectile",
            impact = "rbxassetid://lightning_impact",
            aura = "rbxassetid://lightning_aura",
        },
        description = "Instant damage, chains between enemies",
    },
    shadow = {
        id = "shadow",
        name = "Shadow",
        color = Color3.fromRGB(120, 50, 180),
        secondaryColor = Color3.fromRGB(80, 30, 120),
        damageType = "lifesteal",
        vfx = {
            projectile = "rbxassetid://shadow_projectile",
            impact = "rbxassetid://shadow_impact",
            aura = "rbxassetid://shadow_aura",
        },
        description = "Steals life from enemies",
    },
    nature = {
        id = "nature",
        name = "Nature",
        color = Color3.fromRGB(76, 175, 80),
        secondaryColor = Color3.fromRGB(139, 195, 74),
        damageType = "poison",
        vfx = {
            projectile = "rbxassetid://nature_projectile",
            impact = "rbxassetid://nature_impact",
            aura = "rbxassetid://nature_aura",
        },
        description = "Poisons enemies over time",
    },
    arcane = {
        id = "arcane",
        name = "Arcane",
        color = Color3.fromRGB(233, 30, 99),
        secondaryColor = Color3.fromRGB(255, 215, 0),
        damageType = "pure",
        vfx = {
            projectile = "rbxassetid://arcane_projectile",
            impact = "rbxassetid://arcane_impact",
            aura = "rbxassetid://arcane_aura",
        },
        description = "Pure damage, no special effect",
    },
}

return ElementData