// DungeonRegionDef.swift
// V2-1 地下城區域與樓層靜態定義
// 靜態資料，不進 SwiftData
//
// 結構：
//   DungeonRegionDef  — 區域（3 個）
//   DungeonFloorDef   — 樓層（每區 4 層，第 4 層為 Boss 層）
//
// 裝備解鎖節奏（固定）：
//   第 1 層 → 飾品
//   第 2 層 → 防具
//   第 3 層 → 副手
//   第 4 層 Boss → 武器
//
// 推薦戰力設計基準（Ticket 09 已確認）：
//   荒野邊境 F1–F4：初始可打 → V1 通用裝備配合，目標勝率 65–90%
//   廢棄礦坑 F1–F4：荒野全套後進入，目標勝率 60–75%
//   古代遺跡 F1–F4：礦坑全套 + Lv.7 後進入，最終 Boss 目標勝率 ≈ 64%（全套 + Lv.10）

import Foundation

// MARK: - 樓層定義

struct DungeonFloorDef: Identifiable {
    var id: String { key }
    let key:                 String             // e.g. "wildland_floor_1"
    let name:                String             // e.g. "殘木前哨"
    let regionKey:           String             // 所屬區域 key
    let floorIndex:          Int                // 1–4
    let isBossFloor:         Bool               // true = 第 4 層
    let recommendedPower:    Int                // 建議戰力（佔位值）
    let goldPerBattleRange:  ClosedRange<Int>   // 每場勝場金幣（佔位值）
    let dropTable:           [DropTableEntry]   // 素材掉落表（複用 V1 定義）
    let unlocksEquipmentKey: String             // 首通解鎖的裝備 key
    let unlocksSlot:         EquipmentSlot      // 首通解鎖的裝備部位
    let bossName:            String?            // Boss 名稱（一般層為 nil）
    /// 普通小怪名稱候選（非 Boss 層填 3–4 個，Boss 層留空）
    let commonEnemyNames:    [String]
}

// MARK: - 區域定義

struct DungeonRegionDef {
    let key:               String             // e.g. "wildland"
    let name:              String             // e.g. "荒野邊境"
    let regionDescription: String            // 區域氛圍說明
    let suiteName:         String            // 區域套裝名稱
    let floors:            [DungeonFloorDef] // 固定 4 層，index 1–4

    var bossFloor: DungeonFloorDef? {
        floors.first { $0.isBossFloor }
    }

    var regularFloors: [DungeonFloorDef] {
        floors.filter { !$0.isBossFloor }
    }

    func floor(index: Int) -> DungeonFloorDef? {
        floors.first { $0.floorIndex == index }
    }
}

// MARK: - 靜態資料

extension DungeonRegionDef {

    static let all: [DungeonRegionDef] = [
        wildland,
        abandonedMine,
        ancientRuins,
        sunkenCity,
    ]

    static func find(key: String) -> DungeonRegionDef? {
        all.first { $0.key == key }
    }
}

extension DungeonFloorDef {
    /// 跨所有區域以 floor key 查詢樓層定義
    static func find(key: String) -> DungeonFloorDef? {
        DungeonRegionDef.all.flatMap { $0.floors }.first { $0.key == key }
    }
}

// MARK: - 區域 1：荒野邊境

extension DungeonRegionDef {

    static let wildland = DungeonRegionDef(
        key:               "wildland",
        name:              "金穗之野",
        regionDescription: "豐饒農地被野獸與惡靈侵擾，收穫與危險並存。",
        suiteName:         "農地衛守套裝",
        floors: [

            // 第 1 層：穀倉前道（解鎖飾品）
            DungeonFloorDef(
                key:                 "wildland_floor_1",
                name:                "穀倉前道",
                regionKey:           "wildland",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    40,
                goldPerBattleRange:  5...12,
                dropTable: [
                    DropTableEntry(material: .oldPostBadge, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil,
                commonEnemyNames:    ["野豬掠奪者", "偷糧鳥獸", "田間流氓"]
            ),

            // 第 2 層：荒廢農舍（解鎖防具）
            DungeonFloorDef(
                key:                 "wildland_floor_2",
                name:                "荒廢農舍",
                regionKey:           "wildland",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    65,
                goldPerBattleRange:  7...16,
                dropTable: [
                    DropTableEntry(material: .driedHideBundle, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_armor",
                unlocksSlot:         .armor,
                bossName:            nil,
                commonEnemyNames:    ["稻草人惡靈", "農場狂戰士", "豐收鬼魂"]
            ),

            // 第 3 層：豐收穀倉（解鎖副手）
            DungeonFloorDef(
                key:                 "wildland_floor_3",
                name:                "豐收穀倉",
                regionKey:           "wildland",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    90,
                goldPerBattleRange:  9...20,
                dropTable: [
                    DropTableEntry(material: .splitHornBone, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil,
                commonEnemyNames:    ["倉庫守衛長", "巨型倉鼠王", "飢餓農奴"]
            ),

            // 第 4 層：農神祭壇（Boss 層，解鎖武器）
            DungeonFloorDef(
                key:                 "wildland_floor_4",
                name:                "農神祭壇",
                regionKey:           "wildland",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    120,
                goldPerBattleRange:  13...28,
                dropTable: [
                    DropTableEntry(material: .riftFangRoyalBadge, dropRate: 0.40, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "wildland_weapon",
                unlocksSlot:         .weapon,
                bossName:            "豐收惡神",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 2：廢棄礦坑

extension DungeonRegionDef {

    static let abandonedMine = DungeonRegionDef(
        key:               "abandoned_mine",
        name:              "暮色古林",
        regionDescription: "古老森林深處靈氣充溢，卻被腐化的精靈與獸靈盤據。",
        suiteName:         "森林獵人套裝",
        floors: [

            // 第 1 層：林道入口（解鎖飾品）
            DungeonFloorDef(
                key:                 "mine_floor_1",
                name:                "林道入口",
                regionKey:           "abandoned_mine",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    155,
                goldPerBattleRange:  10...20,
                dropTable: [
                    DropTableEntry(material: .mineLampCopperClip, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil,
                commonEnemyNames:    ["森林狼群", "荊棘射手", "藤蔓蟲群"]
            ),

            // 第 2 層：古樹迷宮（解鎖防具）
            DungeonFloorDef(
                key:                 "mine_floor_2",
                name:                "古樹迷宮",
                regionKey:           "abandoned_mine",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    190,
                goldPerBattleRange:  14...28,
                dropTable: [
                    DropTableEntry(material: .tunnelIronClip, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_armor",
                unlocksSlot:         .armor,
                bossName:            nil,
                commonEnemyNames:    ["腐木傀儡", "精靈游獵者", "暗夜追蹤者"]
            ),

            // 第 3 層：幽暗深處（解鎖副手）
            DungeonFloorDef(
                key:                 "mine_floor_3",
                name:                "幽暗深處",
                regionKey:           "abandoned_mine",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    225,
                goldPerBattleRange:  18...35,
                dropTable: [
                    DropTableEntry(material: .veinStoneSlab, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil,
                commonEnemyNames:    ["古林守護者", "黑夜獸靈", "腐化樹人"]
            ),

            // 第 4 層：古林王座（Boss 層，解鎖武器）
            DungeonFloorDef(
                key:                 "mine_floor_4",
                name:                "古林王座",
                regionKey:           "abandoned_mine",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    260,
                goldPerBattleRange:  24...45,
                dropTable: [
                    DropTableEntry(material: .stoneSwallowCore, dropRate: 0.35, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "mine_weapon",
                unlocksSlot:         .weapon,
                bossName:            "千年古林王",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 3：古代遺跡

extension DungeonRegionDef {

    static let ancientRuins = DungeonRegionDef(
        key:               "ancient_ruins",
        name:              "血色曠野",
        regionDescription: "廣闊草原上游牧部落互相征伐，天際染血的戰場。",
        suiteName:         "草原霸主套裝",
        floors: [

            // 第 1 層：草原邊緣（解鎖飾品）
            DungeonFloorDef(
                key:                 "ruins_floor_1",
                name:                "草原邊緣",
                regionKey:           "ancient_ruins",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    295,
                goldPerBattleRange:  22...42,
                dropTable: [
                    DropTableEntry(material: .relicSealRing, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil,
                commonEnemyNames:    ["游牧斥候", "草原鬣狗", "騎馬獵手"]
            ),

            // 第 2 層：遊牧廢營（解鎖防具）
            DungeonFloorDef(
                key:                 "ruins_floor_2",
                name:                "遊牧廢營",
                regionKey:           "ancient_ruins",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    330,
                goldPerBattleRange:  28...55,
                dropTable: [
                    DropTableEntry(material: .oathInscriptionShard, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_armor",
                unlocksSlot:         .armor,
                bossName:            nil,
                commonEnemyNames:    ["部落戰士", "祭祀巫師", "旗手騎兵"]
            ),

            // 第 3 層：衝突前線（解鎖副手）
            DungeonFloorDef(
                key:                 "ruins_floor_3",
                name:                "衝突前線",
                regionKey:           "ancient_ruins",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    368,
                goldPerBattleRange:  35...65,
                dropTable: [
                    DropTableEntry(material: .foreShrineClip, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil,
                commonEnemyNames:    ["精銳重甲兵", "前線指揮官", "衝鋒戰士"]
            ),

            // 第 4 層：血旗王庭（Boss 層，解鎖武器）
            DungeonFloorDef(
                key:                 "ruins_floor_4",
                name:                "血旗王庭",
                regionKey:           "ancient_ruins",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    410,
                goldPerBattleRange:  45...80,
                dropTable: [
                    DropTableEntry(material: .ancientKingCore, dropRate: 0.35, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "ruins_weapon",
                unlocksSlot:         .weapon,
                bossName:            "血旗草原王",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 4：沉落王城

extension DungeonRegionDef {

    static let sunkenCity = DungeonRegionDef(
        key:               "sunken_city",
        name:              "烈焰沙海",
        regionDescription: "永恆烈日下，古老法老的詛咒在廢墟中沸騰。",
        suiteName:         "沙漠遠征套裝",
        floors: [

            // 第 1 層：沙丘入口（解鎖飾品）
            DungeonFloorDef(
                key:                 "sunken_floor_1",
                name:                "沙丘入口",
                regionKey:           "sunken_city",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    530,
                goldPerBattleRange:  50...95,
                dropTable: [
                    DropTableEntry(material: .sunkenRuneShard, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "sunken_city_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil,
                commonEnemyNames:    ["沙漠蠍兵", "骷髏流浪者", "熱焰精靈"]
            ),

            // 第 2 層：沙暴迴廊（解鎖防具）
            DungeonFloorDef(
                key:                 "sunken_floor_2",
                name:                "沙暴迴廊",
                regionKey:           "sunken_city",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    585,
                goldPerBattleRange:  62...115,
                dropTable: [
                    DropTableEntry(material: .abyssalCrystalDrop, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "sunken_city_armor",
                unlocksSlot:         .armor,
                bossName:            nil,
                commonEnemyNames:    ["沙漠術士", "沙暴戰士", "沙中游魂"]
            ),

            // 第 3 層：法老深墓（解鎖副手）
            DungeonFloorDef(
                key:                 "sunken_floor_3",
                name:                "法老深墓",
                regionKey:           "sunken_city",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    645,
                goldPerBattleRange:  78...145,
                dropTable: [
                    DropTableEntry(material: .drownedCrownFragment, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "sunken_city_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil,
                commonEnemyNames:    ["木乃伊衛兵", "古墓祭司", "守墓傀儡"]
            ),

            // 第 4 層：烈陽神座（Boss，解鎖武器）
            DungeonFloorDef(
                key:                 "sunken_floor_4",
                name:                "烈陽神座",
                regionKey:           "sunken_city",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    710,
                goldPerBattleRange:  100...180,
                dropTable: [
                    DropTableEntry(material: .sunkenKingSeal, dropRate: 0.35, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "sunken_city_weapon",
                unlocksSlot:         .weapon,
                bossName:            "不死沙漠法老",
                commonEnemyNames:    []
            ),
        ]
    )
}
