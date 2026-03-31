// GatherLocationDef.swift
// 採集地點靜態定義
// 靜態資料，不進 SwiftData

import Foundation

struct GatherLocationDef {
    let key: String
    let name: String
    let durationSeconds: Int
    let outputMaterial: MaterialType
    let outputRange: ClosedRange<Int>

    var durationDisplay: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours) 小時 \(minutes) 分鐘"
        } else if hours > 0 {
            return "\(hours) 小時"
        } else {
            return "\(minutes) 分鐘"
        }
    }
}

extension GatherLocationDef {

    static let all: [GatherLocationDef] = [
        GatherLocationDef(
            key:             "forest",
            name:            "森林",
            durationSeconds: 7200,      // 2 小時
            outputMaterial:  .wood,
            outputRange:     3...6
        ),
        GatherLocationDef(
            key:             "mine_pit",
            name:            "礦坑",
            durationSeconds: 10800,     // 3 小時
            outputMaterial:  .ore,
            outputRange:     2...5
        ),
    ]

    static func find(key: String) -> GatherLocationDef? {
        all.first { $0.key == key }
    }
}
