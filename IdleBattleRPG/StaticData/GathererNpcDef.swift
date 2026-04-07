// GathererNpcDef.swift
// 採集者 NPC 靜態定義：職業、名稱、圖示、actorKey、可前往地點
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - GathererRole

enum GathererRole: String {
    case woodcutter  // 伐木工
    case miner       // 採礦工
}

// MARK: - GathererNpcDef

struct GathererNpcDef: Identifiable {
    let actorKey:     String
    let name:         String
    let icon:         String          // SF Symbol 名稱
    let role:         GathererRole
    let npcKind:      NpcKind
    let locationKeys: [String]

    var id: String { actorKey }
}

// MARK: - 靜態資料

extension GathererNpcDef {

    static let all: [GathererNpcDef] = [
        GathererNpcDef(
            actorKey:     "gatherer_1",
            name:         "伐木工",
            icon:         "tree.fill",
            role:         .woodcutter,
            npcKind:      .woodcutter,
            locationKeys: ["forest"]
        ),
        GathererNpcDef(
            actorKey:     "gatherer_2",
            name:         "採礦工",
            icon:         "mountain.2.fill",
            role:         .miner,
            npcKind:      .miner,
            locationKeys: ["mine_pit"]
        ),
    ]

    static func find(actorKey: String) -> GathererNpcDef? {
        all.first { $0.actorKey == actorKey }
    }
}
