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
        name:              "荒野邊境",
        regionDescription: "文明邊界外圍，秩序崩鬆的生存地帶。",
        suiteName:         "邊境生存者套裝",
        floors: [

            // 第 1 層：殘木前哨（解鎖飾品）
            // 初始可打（rusty_sword 24 power ≈ 23% 勝率）；V1 普通裝備後 ≈ 95% cap
            DungeonFloorDef(
                key:                 "wildland_floor_1",
                name:                "殘木前哨",
                regionKey:           "wildland",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    40,
                goldPerBattleRange:  4...10,
                dropTable: [
                    DropTableEntry(material: .oldPostBadge, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil,
                commonEnemyNames:    ["荒野哨兵", "殘林追獵者", "蠻地斥候"]
            ),

            // 第 2 層：獸痕荒徑（解鎖防具）
            // V1 普通全套 68 power → 68/65 ≈ 59% 可打；裝備飾品後 104 → 93%
            DungeonFloorDef(
                key:                 "wildland_floor_2",
                name:                "獸痕荒徑",
                regionKey:           "wildland",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    65,
                goldPerBattleRange:  6...14,
                dropTable: [
                    DropTableEntry(material: .driedHideBundle, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_armor",
                unlocksSlot:         .armor,
                bossName:            nil,
                commonEnemyNames:    ["野地獵手", "荒原狂戰士", "裂骨掠奪者"]
            ),

            // 第 3 層：掠影交界（解鎖副手）
            // 裝備飾品 + V1 普通 → 104 power; 104/90 ≈ 68%；再裝防具 → 134/90 ≈ 88%
            DungeonFloorDef(
                key:                 "wildland_floor_3",
                name:                "掠影交界",
                regionKey:           "wildland",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    90,
                goldPerBattleRange:  8...18,
                dropTable: [
                    DropTableEntry(material: .splitHornBone, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil,
                commonEnemyNames:    ["裂角戰士", "荊棘蠻衛", "邊境狙殺者"]
            ),

            // 第 4 層：裂牙王庭（Boss 層，解鎖武器）
            // 荒野 3 件 + V1 普通武器 → 176/120 ≈ 88%；荒野全套（鑄造武器）→ 184/120 ≈ 88%
            DungeonFloorDef(
                key:                 "wildland_floor_4",
                name:                "裂牙王庭",
                regionKey:           "wildland",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    120,
                goldPerBattleRange:  12...25,
                dropTable: [
                    DropTableEntry(material: .riftFangRoyalBadge, dropRate: 0.40, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "wildland_weapon",
                unlocksSlot:         .weapon,
                bossName:            "裂牙掠首",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 2：廢棄礦坑

extension DungeonRegionDef {

    static let abandonedMine = DungeonRegionDef(
        key:               "abandoned_mine",
        name:              "廢棄礦坑",
        regionDescription: "被遺棄的地下採掘場，深處由穴居巨獸盤據。",
        suiteName:         "礦脈工匠套裝",
        floors: [

            // 第 1 層：殘軌礦道（解鎖飾品）
            // 荒野全套（鑄造武器）184 power → 184/155 ≈ 71%；Boss 掉落最優 → 200/155 ≈ 78%
            DungeonFloorDef(
                key:                 "mine_floor_1",
                name:                "殘軌礦道",
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
                commonEnemyNames:    ["礦坑守衛", "坑道挖掘者", "礦脈巡查兵"]
            ),

            // 第 2 層：支架裂層（解鎖防具）
            // 荒野全套 + mine_accessory → 201 power（需 Lv.5 補足：+24 → 225/190 ≈ 70%）
            DungeonFloorDef(
                key:                 "mine_floor_2",
                name:                "支架裂層",
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
                commonEnemyNames:    ["脈鐵鑿工", "深坑採礦手", "裂岩衛士"]
            ),

            // 第 3 層：沉脈深坑（解鎖副手）
            // 荒野武器 + mine 2 件 + Lv.6 → ≈ 240+24=264/225 ≈ 71%（裝上 mine_armor 後更易）
            DungeonFloorDef(
                key:                 "mine_floor_3",
                name:                "沉脈深坑",
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
                commonEnemyNames:    ["承脈重甲", "礦核執行者", "鑄岩傭兵"]
            ),

            // 第 4 層：吞岩巢庭（Boss 層，解鎖武器）
            // 荒野武器 + mine 3 件 + Lv.7 → 246+36=282/260 ≈ 62%（第一次挑戰有一定難度）
            DungeonFloorDef(
                key:                 "mine_floor_4",
                name:                "吞岩巢庭",
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
                bossName:            "深坑吞岩獸",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 3：古代遺跡

extension DungeonRegionDef {

    static let ancientRuins = DungeonRegionDef(
        key:               "ancient_ruins",
        name:              "古代遺跡",
        regionDescription: "古王誓約仍未消散的神殿遺構。",
        suiteName:         "遺跡守誓套裝",
        floors: [

            // 第 1 層：破階外庭（解鎖飾品）
            // 礦坑全套（鑄造武器）282 power + Lv.7（+36）= 318/295 ≈ 62%
            // 若持有礦坑 Boss 掉落武器最優（+16 power）→ 334/295 ≈ 68%
            DungeonFloorDef(
                key:                 "ruins_floor_1",
                name:                "破階外庭",
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
                commonEnemyNames:    ["遺跡守誓者", "碎壁巡守", "廢墟浪人"]
            ),

            // 第 2 層：斷碑迴廊（解鎖防具）
            // 礦坑全套 + ruins_accessory（+19） + Lv.8（+42）= 343/330 ≈ 62%
            DungeonFloorDef(
                key:                 "ruins_floor_2",
                name:                "斷碑迴廊",
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
                commonEnemyNames:    ["碑紋祭司", "符文詠唱者", "遺靈術士"]
            ),

            // 第 3 層：守誓前殿（解鎖副手）
            // 礦坑武器 + ruins 2 件 + Lv.9（+48）→ 80+126+72+58+48=384/368 ≈ 62%
            DungeonFloorDef(
                key:                 "ruins_floor_3",
                name:                "守誓前殿",
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
                commonEnemyNames:    ["前殿衛士", "殿堂執行者", "古誓騎士"]
            ),

            // 第 4 層：王印聖所（Boss 層，解鎖武器）
            // 遺跡全套（鑄造武器）399 + Lv.10 全 ATK 54 = 453/410 ≈ 64%
            // Boss 掉落最優（ATK 72）→ 419+54=473/410 ≈ 68%（Farming 動機）
            DungeonFloorDef(
                key:                 "ruins_floor_4",
                name:                "王印聖所",
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
                bossName:            "王誓執行者",
                commonEnemyNames:    []
            ),
        ]
    )
}

// MARK: - 區域 4：沉落王城

extension DungeonRegionDef {

    static let sunkenCity = DungeonRegionDef(
        key:               "sunken_city",
        name:              "沉落王城",
        regionDescription: "被詛咒沉入地下暗水的王都，腐蝕魔力與幽暗水流充斥廢墟。",
        suiteName:         "沉城深淵套裝",
        floors: [

            // 第 1 層：沉塔入口（解鎖飾品）
            // 遺跡全套（鑄造武器）≈ 532 power + Lv.20 全 ATK（+60）→ 592/530 ≈ 66%
            DungeonFloorDef(
                key:                 "sunken_floor_1",
                name:                "沉塔入口",
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
                commonEnemyNames:    ["沉城守衛", "溺甲巡邏者", "深淵前哨兵"]
            ),

            // 第 2 層：溺殿迴廊（解鎖防具）
            DungeonFloorDef(
                key:                 "sunken_floor_2",
                name:                "溺殿迴廊",
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
                commonEnemyNames:    ["晶液術士", "腐化侍從", "淵底召喚師"]
            ),

            // 第 3 層：王室深淵（解鎖副手）
            DungeonFloorDef(
                key:                 "sunken_floor_3",
                name:                "王室深淵",
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
                commonEnemyNames:    ["溺冕衛兵", "沉冕執法者", "王室禁衛"]
            ),

            // 第 4 層：沉王聖座（Boss，解鎖武器）
            DungeonFloorDef(
                key:                 "sunken_floor_4",
                name:                "沉王聖座",
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
                bossName:            "沉落王・深淵甦醒",
                commonEnemyNames:    []
            ),
        ]
    )
}
