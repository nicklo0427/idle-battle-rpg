import Foundation

struct MonsterDefinition {
    let key: String
    let name: String
    let atk: Int
    let def: Int
    let hp: Int
    let goldDrop: ClosedRange<Int>
    let dropChance: Double
    let possibleDrops: [String]  // equipment definition keys
}

struct ZoneDefinition {
    let id: String
    let name: String
    let flavorText: String
    let minTeamPower: Int
    let battlesPerHour: Int
    let goldPerBattle: ClosedRange<Int>
    let monsterPool: [MonsterDefinition]
    let unlockCost: Int
    let icon: String  // SF Symbol
}

let zoneDefinitions: [ZoneDefinition] = [
    ZoneDefinition(
        id: "Z01",
        name: "Sunlit Meadows",
        flavorText: "Rolling hills, tall grass, and weak enemies. A safe place to begin.",
        minTeamPower: 0,
        battlesPerHour: 20,
        goldPerBattle: 2...5,
        monsterPool: [
            MonsterDefinition(key: "slime",  name: "Slime",  atk: 5,  def: 2,  hp: 30,  goldDrop: 1...3, dropChance: 0.05, possibleDrops: ["worn_dagger"]),
            MonsterDefinition(key: "goblin", name: "Goblin", atk: 8,  def: 3,  hp: 45,  goldDrop: 2...5, dropChance: 0.08, possibleDrops: ["leather_cap", "worn_dagger"]),
        ],
        unlockCost: 0,
        icon: "sun.max.fill"
    ),
    ZoneDefinition(
        id: "Z02",
        name: "Whispering Forest",
        flavorText: "Ancient trees muffle sound. Something watches between the trunks.",
        minTeamPower: 150,
        battlesPerHour: 16,
        goldPerBattle: 6...12,
        monsterPool: [
            MonsterDefinition(key: "wolf",       name: "Shadow Wolf",  atk: 14, def: 5,  hp: 80,  goldDrop: 4...8,  dropChance: 0.10, possibleDrops: ["iron_sword", "chainmail"]),
            MonsterDefinition(key: "troll",      name: "Mossy Troll",  atk: 18, def: 10, hp: 130, goldDrop: 8...14, dropChance: 0.12, possibleDrops: ["iron_sword", "tower_shield"]),
            MonsterDefinition(key: "darksprite", name: "Dark Sprite",  atk: 20, def: 3,  hp: 60,  goldDrop: 5...10, dropChance: 0.09, possibleDrops: ["mage_robe", "focus_ring"]),
        ],
        unlockCost: 500,
        icon: "tree.fill"
    ),
    ZoneDefinition(
        id: "Z03",
        name: "Ruined Mines",
        flavorText: "The ore ran dry centuries ago. Now only monsters mine here — for flesh.",
        minTeamPower: 400,
        battlesPerHour: 12,
        goldPerBattle: 15...28,
        monsterPool: [
            MonsterDefinition(key: "golem",    name: "Stone Golem",   atk: 28, def: 22, hp: 220, goldDrop: 12...20, dropChance: 0.14, possibleDrops: ["steel_blade", "plate_armor"]),
            MonsterDefinition(key: "orc",      name: "Orc Warlord",   atk: 35, def: 12, hp: 180, goldDrop: 15...25, dropChance: 0.13, possibleDrops: ["steel_blade", "war_helmet"]),
            MonsterDefinition(key: "ironshade", name: "Ironshade",    atk: 40, def: 8,  hp: 140, goldDrop: 10...18, dropChance: 0.11, possibleDrops: ["shadow_cloak", "swift_boots"]),
        ],
        unlockCost: 2000,
        icon: "mountain.2.fill"
    ),
    ZoneDefinition(
        id: "Z04",
        name: "Abyssal Sanctuary",
        flavorText: "No light reaches here. Heroes that venture in often do not return.",
        minTeamPower: 900,
        battlesPerHour: 8,
        goldPerBattle: 35...65,
        monsterPool: [
            MonsterDefinition(key: "demon",    name: "Void Demon",    atk: 60, def: 25, hp: 350, goldDrop: 30...55, dropChance: 0.18, possibleDrops: ["obsidian_sword", "abyss_armor"]),
            MonsterDefinition(key: "wraith",   name: "Ancient Wraith", atk: 70, def: 10, hp: 280, goldDrop: 35...60, dropChance: 0.17, possibleDrops: ["void_staff", "ghost_ring"]),
            MonsterDefinition(key: "archfiend", name: "Archfiend",    atk: 80, def: 30, hp: 420, goldDrop: 50...80, dropChance: 0.20, possibleDrops: ["chaos_blade", "demon_plate"]),
        ],
        unlockCost: 8000,
        icon: "moon.fill"
    ),
]

func zoneDefinition(for id: String) -> ZoneDefinition? {
    zoneDefinitions.first { $0.id == id }
}
