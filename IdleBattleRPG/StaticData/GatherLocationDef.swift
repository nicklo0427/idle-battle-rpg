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
    /// 每回合基礎時長（秒）；與 durationOptions[0] 無關，採集輸出縮放依此計算
    let shortestDuration: Int
}

extension GatherLocationDef {

    static let all: [GatherLocationDef] = [
        GatherLocationDef(
            key:             "forest",
            name:            "森林",
            role:            .woodcutter,
            durationOptions: AppConstants.DungeonDuration.all,  // 同冒險：1分/15分/1小時/12小時
            outputMaterial:  .wood,
            outputRange:     3...6,
            shortestDuration: AppConstants.DungeonDuration.short  // 每 15 分鐘一回合
        ),
        GatherLocationDef(
            key:             "mine_pit",
            name:            "礦坑",
            role:            .miner,
            durationOptions: AppConstants.DungeonDuration.all,  // 同冒險：1分/15分/1小時/12小時
            outputMaterial:  .ore,
            outputRange:     2...5,
            shortestDuration: AppConstants.DungeonDuration.short  // 每 15 分鐘一回合
        ),
    ]

    static func find(key: String) -> GatherLocationDef? {
        all.first { $0.key == key }
    }
}
