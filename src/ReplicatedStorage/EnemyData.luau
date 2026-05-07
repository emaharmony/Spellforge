-- EnemyData.luau — 3 basic enemy types for M1
local EnemyData = {}

EnemyData.Types = {
    walker = {
        id = "walker",
        name = "Shadow Walker",
        hp = 30,
        speed = 8,
        damage = 5,
        attackRange = 5,
        attackCooldown = 1.0,
        crystalDrop = 1,
        color = Color3.fromRGB(80, 80, 100),
        size = Vector3.new(3, 5, 3),
        description = "Slow but steady, walks toward wizard",
    },
    runner = {
        id = "runner",
        name = "Glow Sprinter",
        hp = 15,
        speed = 16,
        damage = 3,
        attackRange = 4,
        attackCooldown = 0.8,
        crystalDrop = 1,
        color = Color3.fromRGB(255, 100, 150),
        size = Vector3.new(2, 4, 2),
        description = "Fast and fragile, reaches wizard quickly",
    },
    tank = {
        id = "tank",
        name = "Stone Golem",
        hp = 80,
        speed = 4,
        damage = 10,
        attackRange = 6,
        attackCooldown = 2.0,
        crystalDrop = 3,
        color = Color3.fromRGB(100, 100, 110),
        size = Vector3.new(5, 7, 5),
        description = "Slow and tough, takes many hits",
    },
}

function EnemyData.GetById(id: string): any
    return EnemyData.Types[id]
end

function EnemyData.GetAll(): { string }
    local ids = {}
    for id, _ in EnemyData.Types do
        table.insert(ids, id)
    end
    return ids
end

return EnemyData