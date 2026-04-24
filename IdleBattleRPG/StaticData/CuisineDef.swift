// CuisineDef.swift
// 料理配方靜態定義（廚師 NPC 使用）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 料理定義

struct CuisineDef {
    let key: String
    let name: String
    let icon: String
    let ingredients: [(material: MaterialType, amount: Int)]
    let goldCost: Int
    let cookMinutes: Int           // 廚師 Tier 0 基準烹飪時間（分鐘）
    let buffDuration: TimeInterval // 秒；2h=7200, 3h=10800, 4h=14400, 6h=21600
    let atkBonus: Int
    let defBonus: Int
    let hpBonus: Int

    /// 烹飪時間的顯示字串
    var durationDisplay: String {
        if cookMinutes < 60 {
            return "\(cookMinutes) 分"
        } else {
            let h = cookMinutes / 60
            let m = cookMinutes % 60
            return m > 0 ? "\(h) 時 \(m) 分" : "\(h) 小時"
        }
    }

    /// Buff 剩餘時間的顯示字串（傳入到期時間戳）
    static func buffRemainingDisplay(expiresAt: Double) -> String {
        let remaining = expiresAt - Date().timeIntervalSinceReferenceDate
        guard remaining > 0 else { return "已失效" }
        let totalMin = Int(remaining / 60)
        let h = totalMin / 60
        let m = totalMin % 60
        if h > 0 { return "\(h) 小時 \(m) 分" }
        return "\(m) 分鐘"
    }
}

// MARK: - 靜態資料

extension CuisineDef {

    static let all: [CuisineDef] = [

        // ── 初級（以鮮魚為主）──────────────────────────────────────
        CuisineDef(
            key:          "fish_stew",
            name:         "鮮魚燉湯",
            icon:         "🍲",
            ingredients:  [(.freshFish, 5), (.herb, 3)],
            goldCost:     40,
            cookMinutes:  15,
            buffDuration: 7_200,    // 2 小時
            atkBonus:     20,
            defBonus:     0,
            hpBonus:      0
        ),
        CuisineDef(
            key:          "herb_fish_soup",
            name:         "靈草魚湯",
            icon:         "🍵",
            ingredients:  [(.freshFish, 3), (.spiritHerb, 2)],
            goldCost:     80,
            cookMinutes:  25,
            buffDuration: 10_800,   // 3 小時
            atkBonus:     0,
            defBonus:     15,
            hpBonus:      40
        ),

        // ── 進階（以深淵魚為主）──────────────────────────────────────
        CuisineDef(
            key:          "abyss_soup",
            name:         "深淵濃湯",
            icon:         "🫕",
            ingredients:  [(.abyssFish, 4), (.spiritHerb, 3)],
            goldCost:     120,
            cookMinutes:  40,
            buffDuration: 14_400,   // 4 小時
            atkBonus:     40,
            defBonus:     0,
            hpBonus:      0
        ),
        CuisineDef(
            key:          "smoked_abyss_fish",
            name:         "煙燻深淵魚",
            icon:         "🐟",
            ingredients:  [(.abyssFish, 3), (.spiritHerb, 2), (.ancientWood, 2)],
            goldCost:     150,
            cookMinutes:  50,
            buffDuration: 21_600,   // 6 小時
            atkBonus:     0,
            defBonus:     30,
            hpBonus:      60
        ),
    ]

    static func find(_ key: String) -> CuisineDef? {
        all.first { $0.key == key }
    }

    /// 對應的 ConsumableType（snake_case key → camelCase enum）
    var consumableType: ConsumableType? {
        switch key {
        case "fish_stew":         return .fishStew
        case "herb_fish_soup":    return .herbFishSoup
        case "abyss_soup":        return .abyssSoup
        case "smoked_abyss_fish": return .smokedAbyssFish
        default:                  return nil
        }
    }
}
