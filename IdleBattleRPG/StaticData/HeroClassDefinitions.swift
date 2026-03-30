import Foundation

struct HeroClassDefinition {
    let key: String
    let displayName: String
    let baseATK: Int
    let baseDEF: Int
    let baseHP: Int
    let baseSPD: Int
    let icon: String  // SF Symbol name
    let description: String
}

let heroClassDefinitions: [HeroClassDefinition] = [
    HeroClassDefinition(key: "warrior",   displayName: "Warrior",   baseATK: 18, baseDEF: 12, baseHP: 120, baseSPD: 8,  icon: "shield.fill",              description: "A balanced fighter with solid defense."),
    HeroClassDefinition(key: "mage",      displayName: "Mage",      baseATK: 25, baseDEF: 5,  baseHP: 80,  baseSPD: 10, icon: "sparkles",                  description: "Glass cannon. Devastating offense, fragile body."),
    HeroClassDefinition(key: "rogue",     displayName: "Rogue",     baseATK: 20, baseDEF: 8,  baseHP: 95,  baseSPD: 16, icon: "eye.slash.fill",            description: "Swift and cunning. Strikes before the enemy can react."),
    HeroClassDefinition(key: "ranger",    displayName: "Ranger",    baseATK: 22, baseDEF: 7,  baseHP: 100, baseSPD: 14, icon: "target",                    description: "Precise at range. Consistent damage output."),
    HeroClassDefinition(key: "paladin",   displayName: "Paladin",   baseATK: 15, baseDEF: 18, baseHP: 140, baseSPD: 6,  icon: "cross.circle.fill",         description: "Holy tank. Absorbs damage to protect the party."),
    HeroClassDefinition(key: "berserker", displayName: "Berserker", baseATK: 30, baseDEF: 4,  baseHP: 110, baseSPD: 9,  icon: "flame.fill",                description: "Pure destruction. Low defense, maximum carnage."),
    HeroClassDefinition(key: "cleric",    displayName: "Cleric",    baseATK: 12, baseDEF: 10, baseHP: 130, baseSPD: 7,  icon: "heart.fill",                description: "Support fighter. Keeps the party alive longer."),
    HeroClassDefinition(key: "assassin",  displayName: "Assassin",  baseATK: 28, baseDEF: 5,  baseHP: 85,  baseSPD: 20, icon: "bolt.fill",                 description: "Fastest in the party. First to strike, first to die."),
]

func heroClassDefinition(for key: String) -> HeroClassDefinition? {
    heroClassDefinitions.first { $0.key == key }
}
