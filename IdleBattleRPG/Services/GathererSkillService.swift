// GathererSkillService.swift
// 採集者技能點投入的業務邏輯（V7-1 T02）

import Foundation
import SwiftData

struct GathererSkillService {
    let context: ModelContext

    // MARK: - 查詢

    func canInvest(nodeKey: String, actorKey: String, player: PlayerStateModel) -> Bool {
        guard player.skillPoints(for: actorKey) > 0 else { return false }
        guard let node = GathererSkillNodeDef.find(key: nodeKey) else { return false }
        guard player.skillLevel(nodeKey: nodeKey, actorKey: actorKey) < node.maxLevel else { return false }
        return isPrerequisiteMet(node: node, actorKey: actorKey, player: player)
    }

    func isPrerequisiteMet(node: GathererSkillNodeDef, actorKey: String, player: PlayerStateModel) -> Bool {
        guard let prereqKey = node.prerequisiteKey else { return true }
        return player.skillLevel(nodeKey: prereqKey, actorKey: actorKey) >= node.prerequisiteLevel
    }

    // MARK: - 寫入

    func investPoint(nodeKey: String, actorKey: String, player: PlayerStateModel) throws {
        guard player.skillPoints(for: actorKey) > 0 else {
            throw GathererSkillError.noPointsAvailable
        }
        guard let node = GathererSkillNodeDef.find(key: nodeKey) else {
            throw GathererSkillError.nodeNotFound
        }
        guard player.skillLevel(nodeKey: nodeKey, actorKey: actorKey) < node.maxLevel else {
            throw GathererSkillError.maxLevelReached
        }
        guard isPrerequisiteMet(node: node, actorKey: actorKey, player: player) else {
            throw GathererSkillError.prerequisiteNotMet
        }

        player.decrementSkillPoints(for: actorKey)
        player.appendSkillKey(nodeKey, for: actorKey)
        try context.save()
    }
}

// MARK: - 錯誤型別

enum GathererSkillError: LocalizedError {
    case noPointsAvailable
    case nodeNotFound
    case maxLevelReached
    case prerequisiteNotMet

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable:  return "沒有可用的採集技能點"
        case .nodeNotFound:       return "找不到技能節點"
        case .maxLevelReached:    return "此節點已達投入上限"
        case .prerequisiteNotMet: return "前置節點等級不足"
        }
    }
}
