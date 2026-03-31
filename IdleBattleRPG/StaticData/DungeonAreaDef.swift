// DungeonAreaDef.swift
// 地下城區域靜態定義（3 個區域）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 掉落表項目

struct DropTableEntry {
    let material: MaterialType
    let dropRate: Double            // 每場勝場的觸發機率 0.0 ~ 1.0
    let quantityRange: ClosedRange<Int>
}

// MARK: - 地下城區域定義

struct DungeonAreaDef {
    let key: String
    let name: String
    let recommendedPower: Int       // 50% 勝率對應的推薦戰力
    let requiredPower: Int          // 解鎖門檻（0 = 初始可進）
    let dropTable: [DropTableEntry]
    let goldPerBattleRange: ClosedRange<Int>

    var isUnlocked: Bool { requiredPower == 0 }
}

// MARK: - 靜態資料

extension DungeonAreaDef {

    static let all: [DungeonAreaDef] = [

        // ── 區域 1：荒野邊境（初始解鎖）──────────────────────────────
        DungeonAreaDef(
            key:              "wildland_border",
            name:             "荒野邊境",
            recommendedPower: 50,
            requiredPower:    0,
            dropTable: [
                DropTableEntry(material: .hide, dropRate: 0.50, quantityRange: 1...2),
            ],
            goldPerBattleRange: 3...8
        ),

        // ── 區域 2：廢棄礦坑（戰力 ≥ 150 解鎖）──────────────────────
        DungeonAreaDef(
            key:              "abandoned_mine",
            name:             "廢棄礦坑",
            recommendedPower: 150,
            requiredPower:    150,
            dropTable: [
                DropTableEntry(material: .crystalShard, dropRate: 0.40, quantityRange: 1...2),
            ],
            goldPerBattleRange: 6...15
        ),

        // ── 區域 3：深淵遺跡（戰力 ≥ 400 解鎖）──────────────────────
        DungeonAreaDef(
            key:              "abyss_ruins",
            name:             "深淵遺跡",
            recommendedPower: 400,
            requiredPower:    400,
            dropTable: [
                DropTableEntry(material: .ancientFragment, dropRate: 0.30, quantityRange: 1...2),
            ],
            goldPerBattleRange: 15...35
        ),
    ]

    static func find(key: String) -> DungeonAreaDef? {
        all.first { $0.key == key }
    }
}
