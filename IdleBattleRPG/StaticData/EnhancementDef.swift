// EnhancementDef.swift
// 裝備強化系統靜態規則：等級上限、每級金幣成本、每部位每級加成、拆解退還金幣
// 靜態資料，不進 SwiftData
//
// ── 數值平衡分析（V2-2 Ticket 06）──────────────────────────────────
//
// 玩家基礎（Lv.1 無加點）：ATK=5, DEF=3, HP=20
//
// V1 精良 3 件全套（power 210.5）→ +5 全部（power 348）：增幅 65%
//   礦坑 F4 Boss（推薦 260）：ratio=1.34 → 勝率 75%    ← 可順暢推進
//   遺跡 F1  （推薦 295）：ratio=1.18 → 勝率 63%    ← 進入門檻
//   遺跡 F4 Boss（推薦 410）：ratio=0.85 → 勝率 37%  ← 仍需 V2-1 遺跡裝
//
// 荒野全套 +5 最優 Boss 武器（power 424.5）：
//   遺跡 F4 Boss（推薦 410）：ratio=1.04 → 勝率 55%   ← 極限 Farming 目標
//
// 金幣供需：荒野 Boss 農怪 ≈ 977 金/小時
//   V1 精良 3 件 +5 = 6,000 金 ≈ 6.1 小時（顯著投入但可達）
//   荒野全套 4 件 +5 = 8,000 金 ≈ 8.2 小時
//
// 拆解套利：鑄造→拆解永遠淨虧，Boss 武器無鑄造成本但量由地下城決定，無迴路。
// ───────────────────────────────────────────────────────────────────

import Foundation

// MARK: - 強化成本定義

struct EnhancementCostDef {
    /// 從此等級升到下一等（0→1, 1→2, …, 4→5）
    let fromLevel: Int
    let goldCost: Int
}

// MARK: - 強化加成定義

struct EnhancementBonusDef {
    let slot: EquipmentSlot
    let atkPerLevel: Int
    let defPerLevel: Int
    let hpPerLevel:  Int
}

// MARK: - 強化靜態規則

enum EnhancementDef {

    /// 強化等級上限（+0 到 +8）
    static let maxLevel = 8

    // MARK: 金幣成本（每次強化費用，非累計）

    static let costs: [EnhancementCostDef] = [
        .init(fromLevel: 0, goldCost:  100),
        .init(fromLevel: 1, goldCost:  200),
        .init(fromLevel: 2, goldCost:  350),
        .init(fromLevel: 3, goldCost:  550),
        .init(fromLevel: 4, goldCost:  800),
        // V8-1：+6 / +7 / +8
        .init(fromLevel: 5, goldCost: 1200),
        .init(fromLevel: 6, goldCost: 1800),
        .init(fromLevel: 7, goldCost: 2800),
    ]
    // 累計滿強化費用：+5 = 2,000 金幣；+8 = 7,800 金幣

    // MARK: 每級加成（固定值，非百分比）
    //
    // 武器：每 +1 等 +4 ATK
    // 防具：每 +1 等 +3 DEF, +8 HP
    // 飾品：每 +1 等 +2 ATK, +2 DEF
    // 副手：每 +1 等 +3 DEF, +6 HP

    static let bonuses: [EnhancementBonusDef] = [
        .init(slot: .weapon,    atkPerLevel: 4, defPerLevel: 0, hpPerLevel: 0),
        .init(slot: .armor,     atkPerLevel: 0, defPerLevel: 3, hpPerLevel: 8),
        .init(slot: .accessory, atkPerLevel: 2, defPerLevel: 2, hpPerLevel: 0),
        .init(slot: .offhand,   atkPerLevel: 0, defPerLevel: 3, hpPerLevel: 6),
    ]

    // MARK: 拆解退還金幣
    //
    // key = EquipmentDef.key；查不到表示不可拆解（如 rusty_sword）
    // 強化費用不退還，視為已消耗

    static let disassembleRefunds: [String: Int] = [
        // V1 普通裝備
        "common_weapon":    30,
        "common_armor":     30,
        "common_accessory": 30,
        // V1 精良裝備
        "refined_weapon":    80,
        "refined_armor":     80,
        "refined_accessory": 80,
        // V2-1 荒野邊境
        "wildland_accessory": 60,
        "wildland_armor":     60,
        "wildland_offhand":   60,
        "wildland_weapon":   300,   // Boss 武器
        // V2-1 廢棄礦坑
        "mine_accessory": 120,
        "mine_armor":     120,
        "mine_offhand":   120,
        "mine_weapon":    300,      // Boss 武器
        // V2-1 古代遺跡
        "ruins_accessory": 250,
        "ruins_armor":     250,
        "ruins_offhand":   250,
        "ruins_weapon":    300,     // Boss 武器
        // V4-3 沉沒之城
        "sunken_city_accessory": 400,
        "sunken_city_armor":     400,
        "sunken_city_offhand":   400,
        "sunken_city_weapon":    500,   // Boss 武器
        // V7-2 採集系裝備
        "gather_talisman": 40,
        "gather_shield":   180,
        "gather_armor":    220,
        "gather_spear":    280,
        // V8-1 稀有套組
        "rare_weapon":    500,
        "rare_armor":     500,
        "rare_offhand":   500,
        "rare_accessory": 500,
        // V8-1 史詩套組
        "epic_weapon":    1200,
        "epic_armor":     1200,
        "epic_offhand":   1200,
        "epic_accessory": 1200,
        // rusty_sword：不加入，Service 層查不到即視為不可拆解
    ]

    // MARK: - 便利查詢

    /// 從 `fromLevel` 升一級所需的金幣；`fromLevel` 超出範圍時回傳 `nil`
    static func goldCost(fromLevel: Int) -> Int? {
        costs.first { $0.fromLevel == fromLevel }?.goldCost
    }

    /// 指定部位的每級加成定義
    static func bonus(for slot: EquipmentSlot) -> EnhancementBonusDef? {
        bonuses.first { $0.slot == slot }
    }

    /// 拆解退還金幣；`nil` 表示不可拆解
    static func disassembleRefund(defKey: String) -> Int? {
        disassembleRefunds[defKey]
    }
}
