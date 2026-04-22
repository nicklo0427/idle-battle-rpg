// GatherLocationDef.swift
// 採集地點靜態定義
// 靜態資料，不進 SwiftData

import Foundation

struct GatherLocationDef {
    let key:             String
    let name:            String
    let role:            GathererRole
    /// 可選時長（秒），由短到長排列，UI 以此為選項
    let durationOptions: [Int]
    let outputMaterial:  MaterialType
    let outputRange:     ClosedRange<Int>
    /// 每回合基礎時長（秒）；採集輸出縮放依此計算
    let shortestDuration: Int
    /// 需要通關的 Boss 樓層 key（nil = 初始可用）
    let requiredBossFloorKey: String?
}

extension GatherLocationDef {

    static let all: [GatherLocationDef] = [

        // MARK: 伐木工地點

        GatherLocationDef(
            key:              "forest",
            name:             "森林",
            role:             .woodcutter,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .wood,
            outputRange:      3...6,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: nil
        ),
        GatherLocationDef(
            key:              "misty_jungle",
            name:             "霧靄叢林",
            role:             .woodcutter,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .wood,
            outputRange:      5...10,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "wildland_floor_4"
        ),
        GatherLocationDef(
            key:              "ancient_tree_reserve",
            name:             "古樹禁地",
            role:             .woodcutter,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .ancientWood,
            outputRange:      2...5,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "abandoned_mine_floor_4"
        ),
        GatherLocationDef(
            key:              "sunken_mangrove",
            name:             "沉城紅樹林",
            role:             .woodcutter,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .ancientWood,
            outputRange:      4...8,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "ancient_ruins_floor_4"
        ),

        // MARK: 採礦工地點

        GatherLocationDef(
            key:              "mine_pit",
            name:             "礦坑",
            role:             .miner,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .ore,
            outputRange:      2...5,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: nil
        ),
        GatherLocationDef(
            key:              "deep_mine_shaft",
            name:             "深層礦道",
            role:             .miner,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .ore,
            outputRange:      4...9,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "wildland_floor_4"
        ),
        GatherLocationDef(
            key:              "lava_vein",
            name:             "熔岩礦脈",
            role:             .miner,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .refinedOre,
            outputRange:      1...4,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "abandoned_mine_floor_4"
        ),
        GatherLocationDef(
            key:              "sunken_ore_deposit",
            name:             "沉城礦層",
            role:             .miner,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .refinedOre,
            outputRange:      3...7,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "ancient_ruins_floor_4"
        ),

        // MARK: 採藥師地點

        GatherLocationDef(
            key:              "herb_meadow",
            name:             "山野藥圃",
            role:             .herbalist,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .herb,
            outputRange:      3...6,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: nil
        ),
        GatherLocationDef(
            key:              "highland_herb_field",
            name:             "高地藥田",
            role:             .herbalist,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .herb,
            outputRange:      5...10,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "wildland_floor_4"
        ),
        GatherLocationDef(
            key:              "ruins_herb_garden",
            name:             "廢墟藥園",
            role:             .herbalist,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .spiritHerb,
            outputRange:      1...4,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "abandoned_mine_floor_4"
        ),
        GatherLocationDef(
            key:              "sunken_bloom_grove",
            name:             "沉城花圃",
            role:             .herbalist,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .spiritHerb,
            outputRange:      3...6,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "ancient_ruins_floor_4"
        ),

        // MARK: 漁夫地點

        GatherLocationDef(
            key:              "border_stream",
            name:             "邊境溪流",
            role:             .fisherman,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .freshFish,
            outputRange:      3...7,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: nil
        ),
        GatherLocationDef(
            key:              "highland_river_bend",
            name:             "高地灣流",
            role:             .fisherman,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .freshFish,
            outputRange:      5...10,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "wildland_floor_4"
        ),
        GatherLocationDef(
            key:              "abyss_lake",
            name:             "深淵湖",
            role:             .fisherman,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .abyssFish,
            outputRange:      1...4,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "abandoned_mine_floor_4"
        ),
        GatherLocationDef(
            key:              "sunken_harbor",
            name:             "沉城古港",
            role:             .fisherman,
            durationOptions:  AppConstants.DungeonDuration.all,
            outputMaterial:   .abyssFish,
            outputRange:      3...6,
            shortestDuration: AppConstants.DungeonDuration.short,
            requiredBossFloorKey: "ancient_ruins_floor_4"
        ),
    ]

    static func find(key: String) -> GatherLocationDef? {
        all.first { $0.key == key }
    }
}
