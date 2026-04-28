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
    case common    = "common"
    case refined   = "refined"
    case rare      = "rare"       // V8-1 稀有
    case epic      = "epic"       // V8-1 史詩
    case legendary = "legendary"  // V8+ 傳說（預留）
    case mythic    = "mythic"     // V8+ 神話（預留）

    var displayName: String {
        switch self {
        case .common:    return "普通"
        case .refined:   return "精良"
        case .rare:      return "稀有"
        case .epic:      return "史詩"
        case .legendary: return "傳說"
        case .mythic:    return "神話"
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
            atkRange: 24...36   // Boss 掉落浮動範圍；下限 = 鑄造 +2，最高 72 power
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
            atkRange: 42...56   // Boss 掉落浮動範圍；下限 = 鑄造 +2，最高 112 power
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
            atkRange: 64...84   // Boss 掉落浮動範圍；下限 = 鑄造 +2，最高 168 power（Farming 最高目標）
        ),

        // ── V4-3 沉落王城套裝：沉城深淵套裝 ──────────────────────────
        // 設計目標：ruins ×1.28 比例。4 件全套鑄造版戰力約 +532。
        // 全套 + Lv.20 全 ATK（+60）≈ 592，對應 F1 推薦戰力 530，勝率約 66%。
        EquipmentDef(
            key:      "sunken_city_accessory",
            name:     "沉紋護符",
            slot:     .accessory,
            rarity:   .refined,
            atkBonus: 20,   // power: 20×2 + 10×1.5 + 35 = 90
            defBonus: 10,
            hpBonus:  35
        ),
        EquipmentDef(
            key:      "sunken_city_armor",
            name:     "深淵溺甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,    // power: 44×1.5 + 96 = 162
            defBonus: 44,
            hpBonus:  96
        ),
        EquipmentDef(
            key:      "sunken_city_offhand",
            name:     "沉冕王徽",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,    // power: 28×1.5 + 56 = 98
            defBonus: 28,
            hpBonus:  56
        ),
        EquipmentDef(
            key:      "sunken_city_weapon",
            name:     "沉王裂水刃",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 80,   // 鑄造固定值，power 160
            defBonus: 0,
            hpBonus:  0,
            atkRange: 82...108  // Boss 掉落浮動範圍；下限 = 鑄造 +2，最高 216 power
        ),

        // ── V8-1 稀有套組（靈火套裝）────────────────────────────────────────
        // 設計：沉沒之城素材 + V7 採集素材合鑄，需清沉沒之城 floor 2
        // 戰力約為沉城精良套裝 ×1.35
        EquipmentDef(
            key:      "rare_weapon",
            name:     "靈火劍",
            slot:     .weapon,
            rarity:   .rare,
            atkBonus: 110,  // power 220  (沉城武器 160 → 此件 → 史詩 290)
            defBonus: 0,
            hpBonus:  0
        ),
        EquipmentDef(
            key:      "rare_armor",
            name:     "深淵重甲",
            slot:     .armor,
            rarity:   .rare,
            atkBonus: 0,    // power: 58×1.5 + 130 = 217  (沉城 162 → 此件 → 史詩 292)
            defBonus: 58,
            hpBonus:  130
        ),
        EquipmentDef(
            key:      "rare_offhand",
            name:     "古木戰盾",
            slot:     .offhand,
            rarity:   .rare,
            atkBonus: 0,    // power: 38×1.5 + 75 = 132  (沉城 98 → 此件 → 史詩 175)
            defBonus: 38,
            hpBonus:  75
        ),
        EquipmentDef(
            key:      "rare_accessory",
            name:     "深海護符",
            slot:     .accessory,
            rarity:   .rare,
            atkBonus: 28,   // power: 28×2 + 14×1.5 + 48 = 125  (沉城 90 → 此件 → 史詩 165)
            defBonus: 14,
            hpBonus:  48
        ),

        // ── V8-1 史詩套組（永恆套裝）────────────────────────────────────────
        // 設計：沉沒之城 Boss 素材 + V7 採集素材 + 頂級農作物，需清沉沒之城 Boss
        // 戰力約為稀有套裝 ×1.32，終局目標裝備
        EquipmentDef(
            key:      "epic_weapon",
            name:     "永恆刃",
            slot:     .weapon,
            rarity:   .epic,
            atkBonus: 145,  // power 290
            defBonus: 0,
            hpBonus:  0
        ),
        EquipmentDef(
            key:      "epic_armor",
            name:     "神域護甲",
            slot:     .armor,
            rarity:   .epic,
            atkBonus: 0,    // power: 78×1.5 + 175 = 292
            defBonus: 78,
            hpBonus:  175
        ),
        EquipmentDef(
            key:      "epic_offhand",
            name:     "虛空之盾",
            slot:     .offhand,
            rarity:   .epic,
            atkBonus: 0,    // power: 50×1.5 + 100 = 175
            defBonus: 50,
            hpBonus:  100
        ),
        EquipmentDef(
            key:      "epic_accessory",
            name:     "深淵聖環",
            slot:     .accessory,
            rarity:   .epic,
            atkBonus: 37,   // power: 37×2 + 20×1.5 + 65 = 169
            defBonus: 20,
            hpBonus:  65
        ),

        // ── V7-2 採集系裝備 ──────────────────────────────────────────────
        // 設計：用採集者帶回的素材鑄造，填補地下城套裝之間的戰力空隙
        // gather_talisman：草藥 + 鮮魚，無解鎖門檻（基礎採集素材）
        //   power: 6×2 + 4×1.5 + 16 = 34  (V1 common 19 → 此件 → wildland 36)
        EquipmentDef(
            key:      "gather_talisman",
            name:     "草藥護身符",
            slot:     .accessory,
            rarity:   .common,
            atkBonus: 6,
            defBonus: 4,
            hpBonus:  16
        ),
        // gather_shield：古木 + 精煉礦石，需通關廢棄礦坑菁英
        //   power: 20×1.5 + 46 = 76  (mine_offhand 58 → 此件 → ruins_offhand 77)
        EquipmentDef(
            key:      "gather_shield",
            name:     "古木護盾",
            slot:     .offhand,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 20,
            hpBonus:  46
        ),
        // gather_armor：靈草 + 古木，需通關廢棄礦坑菁英
        //   power: 30×1.5 + 68 = 113  (mine_armor 91 → 此件 → ruins_armor 126)
        EquipmentDef(
            key:      "gather_armor",
            name:     "靈草護甲",
            slot:     .armor,
            rarity:   .refined,
            atkBonus: 0,
            defBonus: 30,
            hpBonus:  68
        ),
        // gather_spear：深淵魚 + 精煉礦石 + 靈草，需通關廢棄礦坑菁英
        //   power: 52×2 = 104  (mine_weapon 80 → 此件 → ruins_weapon 124)
        EquipmentDef(
            key:      "gather_spear",
            name:     "深淵魚叉",
            slot:     .weapon,
            rarity:   .refined,
            atkBonus: 52,
            defBonus: 0,
            hpBonus:  0
        ),
    ]

    static func find(key: String) -> EquipmentDef? {
        all.first { $0.key == key }
    }
}
