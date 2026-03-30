import Foundation

enum EquipmentRarity: String, CaseIterable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"

    var color: String {
        switch self {
        case .common: return "gray"
        case .rare:   return "blue"
        case .epic:   return "purple"
        }
    }
}

enum EquipmentSlot: String {
    case weapon = "Weapon"
    case armor  = "Armor"
}

struct EquipmentDefinition {
    let key: String
    let name: String
    let slot: EquipmentSlot
    let rarity: EquipmentRarity
    let atkBonus: Int
    let defBonus: Int
    let hpBonus: Int
    let icon: String  // SF Symbol
}

let equipmentDefinitions: [EquipmentDefinition] = [
    // COMMON WEAPONS
    EquipmentDefinition(key: "worn_dagger",    name: "Worn Dagger",      slot: .weapon, rarity: .common, atkBonus: 4,  defBonus: 0,  hpBonus: 0,  icon: "knife"),
    EquipmentDefinition(key: "iron_sword",     name: "Iron Sword",       slot: .weapon, rarity: .common, atkBonus: 8,  defBonus: 0,  hpBonus: 0,  icon: "knife.fill"),
    EquipmentDefinition(key: "short_bow",      name: "Short Bow",        slot: .weapon, rarity: .common, atkBonus: 7,  defBonus: 0,  hpBonus: 0,  icon: "arrow.right.circle"),
    EquipmentDefinition(key: "wooden_staff",   name: "Wooden Staff",     slot: .weapon, rarity: .common, atkBonus: 6,  defBonus: 0,  hpBonus: 5,  icon: "wand.and.stars"),

    // RARE WEAPONS
    EquipmentDefinition(key: "steel_blade",    name: "Steel Blade",      slot: .weapon, rarity: .rare,   atkBonus: 16, defBonus: 0,  hpBonus: 0,  icon: "knife.fill"),
    EquipmentDefinition(key: "shadow_cloak",   name: "Shadow Blade",     slot: .weapon, rarity: .rare,   atkBonus: 18, defBonus: 0,  hpBonus: 0,  icon: "bolt.fill"),
    EquipmentDefinition(key: "mage_wand",      name: "Mage Wand",        slot: .weapon, rarity: .rare,   atkBonus: 22, defBonus: 0,  hpBonus: 0,  icon: "wand.and.rays"),
    EquipmentDefinition(key: "void_staff",     name: "Void Staff",       slot: .weapon, rarity: .rare,   atkBonus: 20, defBonus: 0,  hpBonus: 10, icon: "sparkle"),

    // EPIC WEAPONS
    EquipmentDefinition(key: "obsidian_sword", name: "Obsidian Sword",   slot: .weapon, rarity: .epic,   atkBonus: 35, defBonus: 0,  hpBonus: 0,  icon: "flame.fill"),
    EquipmentDefinition(key: "chaos_blade",    name: "Chaos Blade",      slot: .weapon, rarity: .epic,   atkBonus: 40, defBonus: 0,  hpBonus: 0,  icon: "bolt.circle.fill"),

    // COMMON ARMOR
    EquipmentDefinition(key: "leather_cap",    name: "Leather Cap",      slot: .armor,  rarity: .common, atkBonus: 0,  defBonus: 4,  hpBonus: 10, icon: "shield"),
    EquipmentDefinition(key: "chainmail",      name: "Chainmail",        slot: .armor,  rarity: .common, atkBonus: 0,  defBonus: 8,  hpBonus: 15, icon: "shield.fill"),
    EquipmentDefinition(key: "mage_robe",      name: "Mage Robe",        slot: .armor,  rarity: .common, atkBonus: 3,  defBonus: 4,  hpBonus: 8,  icon: "person.fill"),

    // RARE ARMOR
    EquipmentDefinition(key: "plate_armor",    name: "Plate Armor",      slot: .armor,  rarity: .rare,   atkBonus: 0,  defBonus: 18, hpBonus: 30, icon: "shield.lefthalf.filled"),
    EquipmentDefinition(key: "tower_shield",   name: "Tower Shield",     slot: .armor,  rarity: .rare,   atkBonus: 0,  defBonus: 22, hpBonus: 20, icon: "shield.righthalf.filled"),
    EquipmentDefinition(key: "war_helmet",     name: "War Helmet",       slot: .armor,  rarity: .rare,   atkBonus: 4,  defBonus: 15, hpBonus: 25, icon: "helm"),
    EquipmentDefinition(key: "swift_boots",    name: "Swift Boots",      slot: .armor,  rarity: .rare,   atkBonus: 0,  defBonus: 10, hpBonus: 20, icon: "figure.run"),
    EquipmentDefinition(key: "focus_ring",     name: "Focus Ring",       slot: .armor,  rarity: .rare,   atkBonus: 6,  defBonus: 6,  hpBonus: 6,  icon: "circle.hexagongrid"),
    EquipmentDefinition(key: "ghost_ring",     name: "Ghost Ring",       slot: .armor,  rarity: .rare,   atkBonus: 8,  defBonus: 5,  hpBonus: 15, icon: "circle.dotted"),

    // EPIC ARMOR
    EquipmentDefinition(key: "abyss_armor",    name: "Abyss Armor",      slot: .armor,  rarity: .epic,   atkBonus: 0,  defBonus: 40, hpBonus: 60, icon: "shield.fill"),
    EquipmentDefinition(key: "demon_plate",    name: "Demon Plate",      slot: .armor,  rarity: .epic,   atkBonus: 10, defBonus: 35, hpBonus: 50, icon: "flame.circle.fill"),
]

func equipmentDefinition(for key: String) -> EquipmentDefinition? {
    equipmentDefinitions.first { $0.key == key }
}
