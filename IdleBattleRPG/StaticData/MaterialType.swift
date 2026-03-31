// MaterialType.swift
// 遊戲中的 5 種素材類型定義
// 靜態資料，不進 SwiftData

import Foundation

enum MaterialType: String, CaseIterable, Codable {
    case wood            = "wood"
    case ore             = "ore"
    case hide            = "hide"
    case crystalShard    = "crystal_shard"
    case ancientFragment = "ancient_fragment"

    var displayName: String {
        switch self {
        case .wood:            return "木材"
        case .ore:             return "礦石"
        case .hide:            return "獸皮"
        case .crystalShard:    return "魔晶石"
        case .ancientFragment: return "古代碎片"
        }
    }

    var icon: String {
        switch self {
        case .wood:            return "🪵"
        case .ore:             return "🪨"
        case .hide:            return "🐾"
        case .crystalShard:    return "💎"
        case .ancientFragment: return "🔮"
        }
    }
}
