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
    /// Boss 武器專用浮動 ATK 範圍；nil = 固定數值（非 Boss 武器）
    let atkRange: ClosedRange<Int>?

    /// 是否可透過鑄造師製作（破舊短劍是初始裝備，不可鑄造）
    var isCraftable: Bool { key != AppConstants.Initial.startingWeaponKey }

    /// 是否為 Boss 武器（有浮動 ATK 範圍）
    var isBossWeapon: Bool { atkRange != nil }

    init(
        key: String, name: String, slot: EquipmentSlot, rarity: EquipmentRarity,
        atkBonus: Int, defBonus: Int, hpBonus: Int,
        atkRange: ClosedRange<Int>? = nil
    ) {
        self.key = key; self.name = name; self.slot = slot; self.rarity = rarity
        self.atkBonus = atkBonus; self.defBonus = defBonus; self.hpBonus = hpBonus
        self.atkRange = atkRange
    }
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

        // ── V2-1 荒野邊境套裝：邊境生存者套裝 ──────────────────────────
        // 設計目標：每件介於 V1 普通（≈87 全套）與 V1 精良（≈176 全套）之間；
        //           4 件全套戰力目標 ≈ 184（含副手）略高於 V1 精良 3 件。
        EquipmentDef(
            key:      "wildland_accessory",
            name:     "前哨護符",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 8,    // power: 8×2 + 4×1.5 + 14 = 36  (普通 19 → 36 → 精良 48)
            defBonus: 4,
            hpBonus:  14
        ),
        EquipmentDef(
            key:      "wildland_armor",
            name:     "荒徑皮甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,    // power: 16×1.5 + 38 = 62  (普通 32 → 62 → 精良 64)
            defBonus: 16,
            hpBonus:  38
        ),
        EquipmentDef(
            key:      "wildland_offhand",
            name:     "裂角臂扣",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,    // power: 12×1.5 + 24 = 42  (副手新部位)
            defBonus: 12,
            hpBonus:  24
        ),
        EquipmentDef(
            key:      "wildland_weapon",
            name:     "裂牙獵刃",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 22,   // 鑄造固定值，power 44 (普通 36 → 44 → 精良 64)
            defBonus: 0,
            hpBonus:  0,
            atkRange: 18...30   // Boss 掉落浮動範圍；最高 60 power，略低於精良 64
        ),

        // ── V2-1 廢棄礦坑套裝：礦脈工匠套裝 ──────────────────────────
        // 設計目標：≈ V1 精良裝備水準，部分顯著超越；4 件全套戰力目標 ≈ 282。
        EquipmentDef(
            key:      "mine_accessory",
            name:     "礦燈墜飾",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 12,   // power: 12×2 + 6×1.5 + 20 = 53  (≈ 精良 48，略超)
            defBonus: 6,
            hpBonus:  20
        ),
        EquipmentDef(
            key:      "mine_armor",
            name:     "脈鐵工作甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,    // power: 24×1.5 + 55 = 91  (顯著超過精良 64)
            defBonus: 24,
            hpBonus:  55
        ),
        EquipmentDef(
            key:      "mine_offhand",
            name:     "承脈護架",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,    // power: 16×1.5 + 34 = 58
            defBonus: 16,
            hpBonus:  34
        ),
        EquipmentDef(
            key:      "mine_weapon",
            name:     "吞岩重鑿",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 40,   // 鑄造固定值，power 80 (顯著超過精良 64)
            defBonus: 0,
            hpBonus:  0,
            atkRange: 34...48   // Boss 掉落浮動範圍；最高 96 power
        ),

        // ── V2-1 古代遺跡套裝：遺跡守誓套裝 ──────────────────────────
        // 設計目標：最終裝備層；4 件全套鑄造版戰力目標 ≈ 399。
        // 全套 + Lv.10 全 ATK（+54）≈ 453，對應 Boss 推薦戰力 410，勝率約 64%。
        EquipmentDef(
            key:      "ruins_accessory",
            name:     "守誓印環",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 16,   // power: 16×2 + 8×1.5 + 28 = 72
            defBonus: 8,
            hpBonus:  28
        ),
        EquipmentDef(
            key:      "ruins_armor",
            name:     "碑紋誓甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,    // power: 34×1.5 + 75 = 126
            defBonus: 34,
            hpBonus:  75
        ),
        EquipmentDef(
            key:      "ruins_offhand",
            name:     "前殿聖徽",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,    // power: 22×1.5 + 44 = 77
            defBonus: 22,
            hpBonus:  44
        ),
        EquipmentDef(
            key:      "ruins_weapon",
            name:     "王誓聖刃",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 62,   // 鑄造固定值，power 124
            defBonus: 0,
            hpBonus:  0,
            atkRange: 54...72   // Boss 掉落浮動範圍；最高 144 power（Farming 最高目標）
        ),
    ]

    static func find(key: String) -> EquipmentDef? {
        all.first { $0.key == key }
    }
}
