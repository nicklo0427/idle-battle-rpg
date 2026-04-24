// PotionDef.swift
// 藥水配方靜態定義（製藥師 NPC 使用）

import Foundation

struct PotionDef {
    let key: String
    let name: String
    let icon: String
    let ingredients: [(material: MaterialType, amount: Int)]
    let goldCost: Int
    let brewMinutes: Int
    let healPercent: Double   // 回復比例，對 heroMaxHp

    var consumableType: ConsumableType {
        switch key {
        case "small_potion":  return .smallPotion
        case "medium_potion": return .mediumPotion
        default: fatalError("Unknown potion key: \(key)")
        }
    }

    var brewDurationDisplay: String {
        let h = brewMinutes / 60
        let m = brewMinutes % 60
        if h > 0 && m > 0 { return "\(h) 小時 \(m) 分" }
        if h > 0           { return "\(h) 小時" }
        return "\(m) 分鐘"
    }

    static let all: [PotionDef] = [
        PotionDef(
            key:          "small_potion",
            name:         "小型藥水",
            icon:         "🧪",
            ingredients:  [(.wheat, 5), (.vegetable, 3)],
            goldCost:     50,
            brewMinutes:  20,
            healPercent:  0.30
        ),
        PotionDef(
            key:          "medium_potion",
            name:         "中型藥水",
            icon:         "⚗️",
            ingredients:  [(.fruit, 3), (.spiritGrain, 2)],
            goldCost:     100,
            brewMinutes:  40,
            healPercent:  0.60
        ),
    ]

    static func find(_ key: String) -> PotionDef? {
        all.first { $0.key == key }
    }
}
