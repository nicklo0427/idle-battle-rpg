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
// TODO: recommendedPower 與 goldPerBattleRange 為佔位值，待數值平衡工單調整

import Foundation

// MARK: - 樓層定義

struct DungeonFloorDef {
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
    ]

    static func find(key: String) -> DungeonRegionDef? {
        all.first { $0.key == key }
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
                bossName:            nil
            ),

            // 第 2 層：獸痕荒徑（解鎖防具）
            DungeonFloorDef(
                key:                 "wildland_floor_2",
                name:                "獸痕荒徑",
                regionKey:           "wildland",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    60,
                goldPerBattleRange:  6...14,
                dropTable: [
                    DropTableEntry(material: .driedHideBundle, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_armor",
                unlocksSlot:         .armor,
                bossName:            nil
            ),

            // 第 3 層：掠影交界（解鎖副手）
            DungeonFloorDef(
                key:                 "wildland_floor_3",
                name:                "掠影交界",
                regionKey:           "wildland",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    80,
                goldPerBattleRange:  8...18,
                dropTable: [
                    DropTableEntry(material: .splitHornBone, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "wildland_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil
            ),

            // 第 4 層：裂牙王庭（Boss 層，解鎖武器）
            DungeonFloorDef(
                key:                 "wildland_floor_4",
                name:                "裂牙王庭",
                regionKey:           "wildland",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    110,
                goldPerBattleRange:  12...25,
                dropTable: [
                    DropTableEntry(material: .riftFangRoyalBadge, dropRate: 0.40, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "wildland_weapon",
                unlocksSlot:         .weapon,
                bossName:            "裂牙掠首"
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
            DungeonFloorDef(
                key:                 "mine_floor_1",
                name:                "殘軌礦道",
                regionKey:           "abandoned_mine",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    140,
                goldPerBattleRange:  10...20,
                dropTable: [
                    DropTableEntry(material: .mineLampCopperClip, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil
            ),

            // 第 2 層：支架裂層（解鎖防具）
            DungeonFloorDef(
                key:                 "mine_floor_2",
                name:                "支架裂層",
                regionKey:           "abandoned_mine",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    175,
                goldPerBattleRange:  14...28,
                dropTable: [
                    DropTableEntry(material: .tunnelIronClip, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_armor",
                unlocksSlot:         .armor,
                bossName:            nil
            ),

            // 第 3 層：沉脈深坑（解鎖副手）
            DungeonFloorDef(
                key:                 "mine_floor_3",
                name:                "沉脈深坑",
                regionKey:           "abandoned_mine",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    210,
                goldPerBattleRange:  18...35,
                dropTable: [
                    DropTableEntry(material: .veinStoneSlab, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "mine_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil
            ),

            // 第 4 層：吞岩巢庭（Boss 層，解鎖武器）
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
                bossName:            "深坑吞岩獸"
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
            DungeonFloorDef(
                key:                 "ruins_floor_1",
                name:                "破階外庭",
                regionKey:           "ancient_ruins",
                floorIndex:          1,
                isBossFloor:         false,
                recommendedPower:    330,
                goldPerBattleRange:  22...42,
                dropTable: [
                    DropTableEntry(material: .relicSealRing, dropRate: 0.50, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_accessory",
                unlocksSlot:         .accessory,
                bossName:            nil
            ),

            // 第 2 層：斷碑迴廊（解鎖防具）
            DungeonFloorDef(
                key:                 "ruins_floor_2",
                name:                "斷碑迴廊",
                regionKey:           "ancient_ruins",
                floorIndex:          2,
                isBossFloor:         false,
                recommendedPower:    400,
                goldPerBattleRange:  28...55,
                dropTable: [
                    DropTableEntry(material: .oathInscriptionShard, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_armor",
                unlocksSlot:         .armor,
                bossName:            nil
            ),

            // 第 3 層：守誓前殿（解鎖副手）
            DungeonFloorDef(
                key:                 "ruins_floor_3",
                name:                "守誓前殿",
                regionKey:           "ancient_ruins",
                floorIndex:          3,
                isBossFloor:         false,
                recommendedPower:    470,
                goldPerBattleRange:  35...65,
                dropTable: [
                    DropTableEntry(material: .foreShrineClip, dropRate: 0.45, quantityRange: 1...2),
                ],
                unlocksEquipmentKey: "ruins_offhand",
                unlocksSlot:         .offhand,
                bossName:            nil
            ),

            // 第 4 層：王印聖所（Boss 層，解鎖武器）
            DungeonFloorDef(
                key:                 "ruins_floor_4",
                name:                "王印聖所",
                regionKey:           "ancient_ruins",
                floorIndex:          4,
                isBossFloor:         true,
                recommendedPower:    550,
                goldPerBattleRange:  45...80,
                dropTable: [
                    DropTableEntry(material: .ancientKingCore, dropRate: 0.35, quantityRange: 1...1),
                ],
                unlocksEquipmentKey: "ruins_weapon",
                unlocksSlot:         .weapon,
                bossName:            "王誓執行者"
            ),
        ]
    )
}
