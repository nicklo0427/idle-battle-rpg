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

    static let all: [CraftRecipeDef] = v1Recipes + v2Recipes + v7Recipes + v8Recipes

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

        // ── 沉落王城（45–90 分鐘）───────────────────────────────────────

        CraftRecipeDef(
            key:               "recipe_sunken_city_accessory",
            name:              "鑄造沉紋護符",
            slot:              .accessory,
            rarity:            .refined,
            durationSeconds:   45 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenRuneShard,  amount: 3),
                MaterialRequirement(material: .ancientFragment,   amount: 2),
            ],
            goldCost:          500,
            outputEquipmentKey: "sunken_city_accessory",
            unlockedByFloorKey: "sunken_floor_1"
        ),
        CraftRecipeDef(
            key:               "recipe_sunken_city_armor",
            name:              "鑄造深淵溺甲",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   60 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .abyssalCrystalDrop, amount: 3),
                MaterialRequirement(material: .ancientFragment,      amount: 2),
            ],
            goldCost:          700,
            outputEquipmentKey: "sunken_city_armor",
            unlockedByFloorKey: "sunken_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_sunken_city_offhand",
            name:              "鑄造沉冕王徽",
            slot:              .offhand,
            rarity:            .refined,
            durationSeconds:   75 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .drownedCrownFragment, amount: 3),
                MaterialRequirement(material: .ancientFragment,       amount: 2),
            ],
            goldCost:          900,
            outputEquipmentKey: "sunken_city_offhand",
            unlockedByFloorKey: "sunken_floor_3"
        ),
        CraftRecipeDef(
            key:               "recipe_sunken_city_weapon",
            name:              "鑄造沉王裂水刃",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   90 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenKingSeal,       amount: 1),
                MaterialRequirement(material: .drownedCrownFragment, amount: 1),
                MaterialRequirement(material: .ancientFragment,       amount: 3),
            ],
            goldCost:          1500,
            outputEquipmentKey: "sunken_city_weapon",
            unlockedByFloorKey: "sunken_floor_4"
        ),
    ]
}

// MARK: - V8-1 稀有/史詩配方靜態資料

private extension CraftRecipeDef {

    static let v8Recipes: [CraftRecipeDef] = rareRecipes + epicRecipes

    // ── 稀有套組（靈火套裝）：沉沒之城 floor 2 清關後解鎖 ────────────────
    static let rareRecipes: [CraftRecipeDef] = [

        CraftRecipeDef(
            key:               "recipe_rare_weapon",
            name:              "鑄造靈火劍",
            slot:              .weapon,
            rarity:            .rare,
            durationSeconds:   90 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenRuneShard, amount: 3),
                MaterialRequirement(material: .spiritHerb,     amount: 8),
            ],
            goldCost:           2500,
            outputEquipmentKey: "rare_weapon",
            unlockedByFloorKey: "sunken_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_rare_armor",
            name:              "鑄造深淵重甲",
            slot:              .armor,
            rarity:            .rare,
            durationSeconds:   90 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .abyssalCrystalDrop, amount: 3),
                MaterialRequirement(material: .abyssFish,          amount: 8),
            ],
            goldCost:           2500,
            outputEquipmentKey: "rare_armor",
            unlockedByFloorKey: "sunken_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_rare_offhand",
            name:              "鑄造古木戰盾",
            slot:              .offhand,
            rarity:            .rare,
            durationSeconds:   75 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .drownedCrownFragment, amount: 2),
                MaterialRequirement(material: .ancientWood,          amount: 12),
            ],
            goldCost:           2000,
            outputEquipmentKey: "rare_offhand",
            unlockedByFloorKey: "sunken_floor_2"
        ),
        CraftRecipeDef(
            key:               "recipe_rare_accessory",
            name:              "鑄造深海護符",
            slot:              .accessory,
            rarity:            .rare,
            durationSeconds:   75 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenKingSeal, amount: 1),
                MaterialRequirement(material: .abyssFish,      amount: 5),
                MaterialRequirement(material: .spiritHerb,     amount: 5),
            ],
            goldCost:           3000,
            outputEquipmentKey: "rare_accessory",
            unlockedByFloorKey: "sunken_floor_2"
        ),
    ]

    // ── 史詩套組（永恆套裝）：沉沒之城 Boss（floor 4）清關後解鎖 ──────────
    // 原料跨三系統：沉城 Boss 素材 + V7 採集素材 + V7-4 頂級農作物
    static let epicRecipes: [CraftRecipeDef] = [

        CraftRecipeDef(
            key:               "recipe_epic_weapon",
            name:              "鑄造永恆刃",
            slot:              .weapon,
            rarity:            .epic,
            durationSeconds:   120 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenKingSeal, amount: 2),
                MaterialRequirement(material: .spiritGrainTop, amount: 3),
                MaterialRequirement(material: .spiritHerb,     amount: 10),
            ],
            goldCost:           5000,
            outputEquipmentKey: "epic_weapon",
            unlockedByFloorKey: "sunken_floor_4"
        ),
        CraftRecipeDef(
            key:               "recipe_epic_armor",
            name:              "鑄造神域護甲",
            slot:              .armor,
            rarity:            .epic,
            durationSeconds:   120 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenKingSeal, amount: 2),
                MaterialRequirement(material: .fruitTop,       amount: 3),
                MaterialRequirement(material: .abyssFish,      amount: 10),
            ],
            goldCost:           5000,
            outputEquipmentKey: "epic_armor",
            unlockedByFloorKey: "sunken_floor_4"
        ),
        CraftRecipeDef(
            key:               "recipe_epic_offhand",
            name:              "鑄造虛空之盾",
            slot:              .offhand,
            rarity:            .epic,
            durationSeconds:   110 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .drownedCrownFragment, amount: 4),
                MaterialRequirement(material: .wheatTop,             amount: 5),
                MaterialRequirement(material: .ancientWood,          amount: 15),
            ],
            goldCost:           4000,
            outputEquipmentKey: "epic_offhand",
            unlockedByFloorKey: "sunken_floor_4"
        ),
        CraftRecipeDef(
            key:               "recipe_epic_accessory",
            name:              "鑄造深淵聖環",
            slot:              .accessory,
            rarity:            .epic,
            durationSeconds:   120 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .sunkenKingSeal, amount: 3),
                MaterialRequirement(material: .spiritGrainTop, amount: 5),
                MaterialRequirement(material: .abyssFish,      amount: 8),
                MaterialRequirement(material: .spiritHerb,     amount: 8),
            ],
            goldCost:           6000,
            outputEquipmentKey: "epic_accessory",
            unlockedByFloorKey: "sunken_floor_4"
        ),
    ]
}

// MARK: - V7-2 採集系配方靜態資料

private extension CraftRecipeDef {

    static let v7Recipes: [CraftRecipeDef] = [

        // ── 草藥護身符（飾品，普通，無解鎖門檻）──────────────────────────
        // 使用基礎採集素材，適合中前期補強飾品欄
        CraftRecipeDef(
            key:               "recipe_gather_talisman",
            name:              "鑄造草藥護身符",
            slot:              .accessory,
            rarity:            .common,
            durationSeconds:   20 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .herb,      amount: 12),
                MaterialRequirement(material: .freshFish, amount: 10),
            ],
            goldCost:           50,
            outputEquipmentKey: "gather_talisman"
        ),

        // ── 古木護盾（副手，精良，需通關廢棄礦坑菁英）───────────────────
        // 古木 + 精煉礦石，採集解鎖後可製作，填補礦坑→遺跡副手空隙
        CraftRecipeDef(
            key:               "recipe_gather_shield",
            name:              "鑄造古木護盾",
            slot:              .offhand,
            rarity:            .refined,
            durationSeconds:   35 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .ancientWood, amount: 8),
                MaterialRequirement(material: .refinedOre,  amount: 5),
            ],
            goldCost:           150,
            outputEquipmentKey: "gather_shield",
            unlockedByFloorKey: "mine_floor_4"
        ),

        // ── 靈草護甲（防具，精良，需通關廢棄礦坑菁英）───────────────────
        // 靈草 + 古木，採集高地解鎖後製作，填補礦坑→遺跡防具空隙
        CraftRecipeDef(
            key:               "recipe_gather_armor",
            name:              "鑄造靈草護甲",
            slot:              .armor,
            rarity:            .refined,
            durationSeconds:   50 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .spiritHerb,  amount: 8),
                MaterialRequirement(material: .ancientWood, amount: 6),
            ],
            goldCost:           200,
            outputEquipmentKey: "gather_armor",
            unlockedByFloorKey: "mine_floor_4"
        ),

        // ── 深淵魚叉（武器，精良，需通關廢棄礦坑菁英）───────────────────
        // 深淵魚 + 精煉礦石 + 靈草，高階採集素材，填補礦坑→遺跡武器空隙
        CraftRecipeDef(
            key:               "recipe_gather_spear",
            name:              "鑄造深淵魚叉",
            slot:              .weapon,
            rarity:            .refined,
            durationSeconds:   60 * 60,
            requiredMaterials: [
                MaterialRequirement(material: .abyssFish,  amount: 5),
                MaterialRequirement(material: .refinedOre, amount: 4),
                MaterialRequirement(material: .spiritHerb, amount: 3),
            ],
            goldCost:           250,
            outputEquipmentKey: "gather_spear",
            unlockedByFloorKey: "mine_floor_4"
        ),
    ]
}
