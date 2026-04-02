// EquipmentDef.swift
// 裝備部位、稀有度 enum + 所有裝備的靜態屬性定義
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 裝備部位

enum EquipmentSlot: String, CaseIterable, Codable {
    case weapon    = "weapon"
    case armor     = "armor"
    case accessory = "accessory"
    case offhand   = "offhand"   // V2-1：副手（通用 slot，不做職業分化）

    var displayName: String {
        switch self {
        case .weapon:    return "武器"
        case .armor:     return "防具"
        case .accessory: return "飾品"
        case .offhand:   return "副手"
        }
    }

    var icon: String {
        switch self {
        case .weapon:    return "🗡️"
        case .armor:     return "🛡️"
        case .accessory: return "💍"
        case .offhand:   return "🔰"
        }
    }
}

// MARK: - 裝備稀有度

enum EquipmentRarity: String, CaseIterable, Codable {
    case common  = "common"
    case refined = "refined"

    var displayName: String {
        switch self {
        case .common:  return "普通"
        case .refined: return "精良"
        }
    }
}

// MARK: - 裝備靜態定義

struct EquipmentDef {
    let key: String
    let name: String
    let slot: EquipmentSlot
    let rarity: EquipmentRarity
    let atkBonus: Int
    let defBonus: Int
    let hpBonus: Int

    /// 是否可透過鑄造師製作（破舊短劍是初始裝備，不可鑄造）
    var isCraftable: Bool { key != AppConstants.Initial.startingWeaponKey }
}

// MARK: - 靜態資料

extension EquipmentDef {

    static let all: [EquipmentDef] = [

        // ── 初始裝備（不可鑄造）──────────────────────────────────────
        EquipmentDef(
            key:      "rusty_sword",
            name:     "破舊短劍",
            slot:     .weapon,
            rarity:   .common,
            atkBonus: 12,
            defBonus: 0,
            hpBonus:  0
        ),

        // ── 普通裝備（可鑄造）────────────────────────────────────────
        EquipmentDef(
            key:      "common_weapon",
            name:     "普通武器",
            slot:     .weapon,
            rarity:   .common,
            atkBonus: 18,
            defBonus: 0,
            hpBonus:  0
        ),
        EquipmentDef(
            key:      "common_armor",
            name:     "普通防具",
            slot:     .armor,
            rarity:   .common,
            atkBonus: 0,
            defBonus: 8,
            hpBonus:  20
        ),
        EquipmentDef(
            key:      "common_accessory",
            name:     "普通飾品",
            slot:     .accessory,
            rarity:   .common,
            atkBonus: 4,
            defBonus: 2,
            hpBonus:  8
        ),

        // ── 精良裝備（可鑄造）────────────────────────────────────────
        EquipmentDef(
            key:      "refined_weapon",
            name:     "精良武器",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 32,
            defBonus: 0,
            hpBonus:  0
        ),
        EquipmentDef(
            key:      "refined_armor",
            name:     "精良防具",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 16,
            hpBonus:  40
        ),
        EquipmentDef(
            key:      "refined_accessory",
            name:     "精良飾品",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 8,
            defBonus: 8,
            hpBonus:  20
        ),

        // ── V2-1 荒野邊境套裝：邊境生存者套裝 ────────────────────────
        // TODO: 數值待平衡工單調整，目前為設計佔位值
        EquipmentDef(
            key:      "wildland_accessory",
            name:     "前哨護符",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 5,
            defBonus: 2,
            hpBonus:  12
        ),
        EquipmentDef(
            key:      "wildland_armor",
            name:     "荒徑皮甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 12,
            hpBonus:  28
        ),
        EquipmentDef(
            key:      "wildland_offhand",
            name:     "裂角臂扣",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 8,
            hpBonus:  18
        ),
        EquipmentDef(
            key:      "wildland_weapon",
            name:     "裂牙獵刃",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 24,
            defBonus: 0,
            hpBonus:  0
        ),

        // ── V2-1 廢棄礦坑套裝：礦脈工匠套裝 ─────────────────────────
        EquipmentDef(
            key:      "mine_accessory",
            name:     "礦燈墜飾",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 9,
            defBonus: 4,
            hpBonus:  18
        ),
        EquipmentDef(
            key:      "mine_armor",
            name:     "脈鐵工作甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 20,
            hpBonus:  46
        ),
        EquipmentDef(
            key:      "mine_offhand",
            name:     "承脈護架",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 14,
            hpBonus:  28
        ),
        EquipmentDef(
            key:      "mine_weapon",
            name:     "吞岩重鑿",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 40,
            defBonus: 0,
            hpBonus:  0
        ),

        // ── V2-1 古代遺跡套裝：遺跡守誓套裝 ─────────────────────────
        EquipmentDef(
            key:      "ruins_accessory",
            name:     "守誓印環",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 13,
            defBonus: 6,
            hpBonus:  25
        ),
        EquipmentDef(
            key:      "ruins_armor",
            name:     "碑紋誓甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 30,
            hpBonus:  68
        ),
        EquipmentDef(
            key:      "ruins_offhand",
            name:     "前殿聖徽",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 20,
            hpBonus:  40
        ),
        EquipmentDef(
            key:      "ruins_weapon",
            name:     "王誓聖刃",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 58,
            defBonus: 0,
            hpBonus:  0
        ),
    ]

    static func find(key: String) -> EquipmentDef? {
        all.first { $0.key == key }
    }
}
