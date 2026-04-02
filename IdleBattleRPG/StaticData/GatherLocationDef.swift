// GatherLocationDef.swift
// 採集地點靜態定義
// 靜態資料，不進 SwiftData

import Foundation

struct GatherLocationDef {
    let key: String
    let name: String
    /// 可選時長（秒），由短到長排列，UI 以此為選項
    let durationOptions: [Int]
    let outputMaterial: MaterialType
    let outputRange: ClosedRange<Int>

    var shortestDuration: Int { durationOptions.first ?? 1800 }
}

extension GatherLocationDef {

    static let all: [GatherLocationDef] = [
        GatherLocationDef(
            key:             "forest",
            name:            "森林",
            durationOptions: [60, 300, 7200],          // 1分 / 5分 / 2小時
            outputMaterial:  .wood,
            outputRange:     3...6
        ),
        GatherLocationDef(
            key:             "mine_pit",
            name:            "礦坑",
            durationOptions: [60, 300, 10800],         // 1分 / 5分 / 3小時
            outputMaterial:  .ore,
            outputRange:     2...5
        ),
    ]

    static func find(key: String) -> GatherLocationDef? {
        all.first { $0.key == key }
    }
}
