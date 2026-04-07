// CraftRecipeDef.swift
// 鑄造配方靜態定義
//   V1：3 部位 × 2 稀有度 = 6 個配方（永遠可見）
//   V2-1：3 區域 × 4 部位 = 12 個配方（需首通對應樓層才顯示）
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
    /// nil = V1 配方，永遠可見；非 nil = 需首通對應樓層（DungeonProgressionService.isFloorCleared）
    let unlockedByFloorKey: String?

    init(
        key: String, name: String, slot: EquipmentSlot, rarity: EquipmentRarity,
        durationSeconds: Int, requiredMaterials: [MaterialRequirement],
        goldCost: Int, outputEquipmentKey: String, unlockedByFloorKey: String? = nil
    ) {
        self.key = key; self.name = name; self.slot = slot; self.rarity = rarity
        self.durationSeconds = durationSeconds; self.requiredMaterials = requiredMaterials
        self.goldCost = goldCost; self.outputEquipmentKey = outputEquipmentKey
        self.unlockedByFloorKey = unlockedByFloorKey
    }

    var durationDisplay: String {
        let minutes = durationSeconds / 60
        return "\(minutes) 分鐘"
    }
}

// MARK: - 靜態資料

extension CraftRecipeDef {

    static let all: [CraftRecipeDef] = v1Recipes + v2Recipes

    static let v1Recipes: [CraftRecipeDef] = [

        // ── 普通裝備 ─────────────────────────────────────────────────
        CraftRecipeDef(
            key:               "recipe_common_weapon",
            name:              "鑄造普通武器",
            slot:              .weapon,
            rarity:            .common,
            durationSeconds:   8 * 60,  // 8 分鐘
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
            durationSeconds:   10 * 60, // 10 分鐘（首次特快 → 30 秒）
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
            durationSeconds:   5 * 60,  // 5 分鐘
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
            durationSeconds:   15 * 60, // 15 分鐘
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
            durationSeconds:   20 * 60, // 20 分鐘
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
            durationSeconds:   12 * 60, // 12 分鐘
            requiredMaterials: [
                MaterialRequirement(material: .ore,          amount: 2),
                MaterialRequirement(material: .crystalShard, amount: 2),
            ],
            goldCost:          80,
            outputEquipmentKey: "refined_accessory"
        ),
    ]

    // MARK: - V2-1 配方（按解鎖樓層分組查詢）


    /// 過濾出已解鎖配方（V1 全顯示；V2-1 需首通對應樓層）
    static func available(isCleared: (String) -> Bool) -> [CraftRecipeDef] {
        all.filter { recipe in
            guard let floorKey = recipe.unlockedByFloorKey else { return true }
            return isCleared(floorKey)
        }
    }

    static func find(key: String) -> CraftRecipeDef? {
        all.first { $0.key == key }
    }
}

// MARK: - V2-1 配方靜態資料

private extension CraftRecipeDef {

    static let v2Recipes: [CraftRecipeDef] = [

        // ── 荒野邊境（5–15 分鐘）────────────────────────────────────────

        CraftRecipeDef(
            key:               "recipe_wildland_accessory",
            name:              "鑄造前哨護符",
            slot:              .accessory,
            rarity:            .refined,
            durationSeconds:   5 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .oldPostBadge, amount: 2),
                MaterialRequirement(material: .wood,         amount: 3),
            ],
            goldCost:          30,
            outputEquipmentKey: "wildland_accessory",
            unlockedByFloorKey: "wildland_floor_1"
        ),
        CraftRecipeDef(
            key:               "recipe_wildland_armor",
            name:              "鑄造荒徑皮甲",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   8 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .driedHideBundle, amount: 2),
                MaterialRequirement(material: .hide,            amount: 2),
            ],
            goldCost:          50,
            outputEquipmentKey: "wildland_armor",
            unlockedByFloorKey: "wildland_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_wildland_offhand",
            name:              "鑄造裂角臂扣",
            slot:              .offhand,
            rarity:            .refined,
            durationSeconds:   10 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .splitHornBone, amount: 2),
                MaterialRequirement(material: .ore,           amount: 2),
            ],
            goldCost:          80,
            outputEquipmentKey: "wildland_offhand",
            unlockedByFloorKey: "wildland_floor_3"
        ),
        CraftRecipeDef(
            key:               "recipe_wildland_weapon",
            name:              "鑄造裂牙獵刃",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   15 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .riftFangRoyalBadge, amount: 1),
                MaterialRequirement(material: .oldPostBadge,        amount: 1),
                MaterialRequirement(material: .wood,                amount: 3),
            ],
            goldCost:          150,
            outputEquipmentKey: "wildland_weapon",
            unlockedByFloorKey: "wildland_floor_4"
        ),

        // ── 廢棄礦坑（15–30 分鐘）───────────────────────────────────────

        CraftRecipeDef(
            key:               "recipe_mine_accessory",
            name:              "鑄造礦燈墜飾",
            slot:              .accessory,
            rarity:            .refined,
            durationSeconds:   15 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .mineLampCopperClip, amount: 2),
                MaterialRequirement(material: .ore,                amount: 3),
            ],
            goldCost:          80,
            outputEquipmentKey: "mine_accessory",
            unlockedByFloorKey: "mine_floor_1"
        ),
        CraftRecipeDef(
            key:               "recipe_mine_armor",
            name:              "鑄造脈鐵工作甲",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   20 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .tunnelIronClip, amount: 2),
                MaterialRequirement(material: .ore,            amount: 3),
            ],
            goldCost:          130,
            outputEquipmentKey: "mine_armor",
            unlockedByFloorKey: "mine_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_mine_offhand",
            name:              "鑄造承脈護架",
            slot:              .offhand,
            rarity:            .refined,
            durationSeconds:   25 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .veinStoneSlab, amount: 2),
                MaterialRequirement(material: .wood,          amount: 3),
            ],
            goldCost:          200,
            outputEquipmentKey: "mine_offhand",
            unlockedByFloorKey: "mine_floor_3"
        ),
        CraftRecipeDef(
            key:               "recipe_mine_weapon",
            name:              "鑄造吞岩重鑿",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   30 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .stoneSwallowCore, amount: 1),
                MaterialRequirement(material: .veinStoneSlab,    amount: 1),
                MaterialRequirement(material: .ore,              amount: 4),
            ],
            goldCost:          350,
            outputEquipmentKey: "mine_weapon",
            unlockedByFloorKey: "mine_floor_4"
        ),

        // ── 古代遺跡（30–60 分鐘）───────────────────────────────────────

        CraftRecipeDef(
            key:               "recipe_ruins_accessory",
            name:              "鑄造守誓印環",
            slot:              .accessory,
            rarity:            .refined,
            durationSeconds:   30 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .relicSealRing,  amount: 2),
                MaterialRequirement(material: .ancientFragment, amount: 1),
            ],
            goldCost:          200,
            outputEquipmentKey: "ruins_accessory",
            unlockedByFloorKey: "ruins_floor_1"
        ),
        CraftRecipeDef(
            key:               "recipe_ruins_armor",
            name:              "鑄造碑紋誓甲",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   40 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .oathInscriptionShard, amount: 2),
                MaterialRequirement(material: .hide,                 amount: 3),
            ],
            goldCost:          320,
            outputEquipmentKey: "ruins_armor",
            unlockedByFloorKey: "ruins_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_ruins_offhand",
            name:              "鑄造前殿聖徽",
            slot:              .offhand,
            rarity:            .refined,
            durationSeconds:   50 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .foreShrineClip, amount: 2),
                MaterialRequirement(material: .ancientFragment, amount: 1),
            ],
            goldCost:          480,
            outputEquipmentKey: "ruins_offhand",
            unlockedByFloorKey: "ruins_floor_3"
        ),
        CraftRecipeDef(
            key:               "recipe_ruins_weapon",
            name:              "鑄造王誓聖刃",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   60 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .ancientKingCore, amount: 1),
                MaterialRequirement(material: .foreShrineClip,  amount: 1),
                MaterialRequirement(material: .ancientFragment,  amount: 2),
            ],
            goldCost:          800,
            outputEquipmentKey: "ruins_weapon",
            unlockedByFloorKey: "ruins_floor_4"
        ),
    ]
}
