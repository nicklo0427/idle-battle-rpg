// CraftRecipeDef.swift
// 鑄造配方靜態定義（3 部位 × 2 稀有度 = 6 個配方）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 素材需求（配方用）

struct MaterialRequirement {
    let material: MaterialType
    let amount: Int
}

// MARK: - 鑄造配方定義

struct CraftRecipeDef {
    let key: String
    let name: String
    let slot: EquipmentSlot
    let rarity: EquipmentRarity
    let durationSeconds: Int
    let requiredMaterials: [MaterialRequirement]
    let goldCost: Int
    let outputEquipmentKey: String      // 對應 EquipmentDef.key

    var durationDisplay: String {
        let minutes = durationSeconds / 60
        return "\(minutes) 分鐘"
    }
}

// MARK: - 靜態資料

extension CraftRecipeDef {

    static let all: [CraftRecipeDef] = [

        // ── 普通裝備 ─────────────────────────────────────────────────
        CraftRecipeDef(
            key:               "recipe_common_weapon",
            name:              "鑄造普通武器",
            slot:              .weapon,
            rarity:            .common,
            durationSeconds:   600,     // 10 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .wood, amount: 3),
                MaterialRequirement(material: .ore,  amount: 2),
            ],
            goldCost:          10,
            outputEquipmentKey: "common_weapon"
        ),
        CraftRecipeDef(
            key:               "recipe_common_armor",
            name:              "鑄造普通防具",
            slot:              .armor,
            rarity:            .common,
            durationSeconds:   900,     // 15 分鐘（首次特快 → 30 秒）
            requiredMaterials: [
                MaterialRequirement(material: .wood, amount: 4),
                MaterialRequirement(material: .ore,  amount: 3),
            ],
            goldCost:          10,
            outputEquipmentKey: "common_armor"
        ),
        CraftRecipeDef(
            key:               "recipe_common_accessory",
            name:              "鑄造普通飾品",
            slot:              .accessory,
            rarity:            .common,
            durationSeconds:   1200,    // 20 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .wood, amount: 2),
                MaterialRequirement(material: .ore,  amount: 2),
            ],
            goldCost:          15,
            outputEquipmentKey: "common_accessory"
        ),

        // ── 精良裝備 ─────────────────────────────────────────────────
        CraftRecipeDef(
            key:               "recipe_refined_weapon",
            name:              "鑄造精良武器",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   1800,    // 30 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .wood, amount: 3),
                MaterialRequirement(material: .ore,  amount: 3),
                MaterialRequirement(material: .hide, amount: 2),
            ],
            goldCost:          50,
            outputEquipmentKey: "refined_weapon"
        ),
        CraftRecipeDef(
            key:               "recipe_refined_armor",
            name:              "鑄造精良防具",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   2400,    // 40 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .wood, amount: 4),
                MaterialRequirement(material: .ore,  amount: 4),
                MaterialRequirement(material: .hide, amount: 3),
            ],
            goldCost:          40,
            outputEquipmentKey: "refined_armor"
        ),
        CraftRecipeDef(
            key:               "recipe_refined_accessory",
            name:              "鑄造精良飾品",
            slot:              .accessory,
            rarity:            .refined,
            durationSeconds:   2700,    // 45 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .ore,          amount: 2),
                MaterialRequirement(material: .crystalShard, amount: 2),
            ],
            goldCost:          80,
            outputEquipmentKey: "refined_accessory"
        ),
    ]

    static func find(key: String) -> CraftRecipeDef? {
        all.first { $0.key == key }
    }
}
