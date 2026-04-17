// TalentService.swift
// V6-2 天賦點投入的業務邏輯

import Foundation
import SwiftData

struct TalentService {
    let context: ModelContext

    // MARK: - 查詢

    func investedNodes(for player: PlayerStateModel) -> [TalentNodeDef] {
        player.investedTalentKeys.compactMap { TalentNodeDef.find(key: $0) }
    }

    func canInvest(nodeKey: String, for player: PlayerStateModel) -> Bool {
        guard player.availableTalentPoints > 0 else { return false }
        guard let node = TalentNodeDef.find(key: nodeKey) else { return false }

        // 節點等級上限
        guard !node.isMaxed(in: player) else { return false }

        // 路線互斥：若玩家已在此職業的另一條路線投入，則鎖定
        let routes = TalentRouteDef.all(for: player.classKey)
        for other in routes where other.key != node.routeKey {
            let hasInvestedInOther = other.nodes.contains {
                player.investedTalentKeys.contains($0.key)
            }
            if hasInvestedInOther { return false }
        }

        // 前置節點（需 ≥ 1 次投入）
        if node.nodeIndex == 0 { return true }
        guard let route = TalentRouteDef.find(key: node.routeKey) else { return false }
        let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
        guard let prev = prevNode else { return false }
        return player.investedTalentKeys.contains(prev.key)
    }

    func isRouteLocked(_ route: TalentRouteDef, for player: PlayerStateModel) -> Bool {
        let routes = TalentRouteDef.all(for: player.classKey)
        for other in routes where other.key != route.key {
            let hasInvestedInOther = other.nodes.contains {
                player.investedTalentKeys.contains($0.key)
            }
            if hasInvestedInOther { return true }
        }
        return false
    }

    // MARK: - 寫入

    func investPoint(nodeKey: String, for player: PlayerStateModel) throws {
        guard player.availableTalentPoints > 0 else {
            throw TalentError.noPointsAvailable
        }
        guard let node = TalentNodeDef.find(key: nodeKey) else {
            throw TalentError.nodeNotFound
        }
        guard !node.isMaxed(in: player) else {
            throw TalentError.maxLevelReached
        }

        // 路線互斥檢查
        let routes = TalentRouteDef.all(for: player.classKey)
        for other in routes where other.key != node.routeKey {
            let hasInvestedInOther = other.nodes.contains {
                player.investedTalentKeys.contains($0.key)
            }
            if hasInvestedInOther { throw TalentError.routeLocked }
        }

        // 前置節點檢查（需 ≥ 1 次投入）
        if node.nodeIndex > 0 {
            guard let route = TalentRouteDef.find(key: node.routeKey) else {
                throw TalentError.nodeNotFound
            }
            let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
            guard let prev = prevNode,
                  player.investedTalentKeys.contains(prev.key) else {
                throw TalentError.previousNodeNotInvested
            }
        }

        player.availableTalentPoints -= 1
        player.investedTalentKeysRaw = (player.investedTalentKeys + [nodeKey]).joined(separator: ",")

        try context.save()
    }

    // MARK: - 天賦重置（T06）

    func resetAllTalents(player: PlayerStateModel) throws {
        let invested = player.investedTalentKeys
        guard !invested.isEmpty else { throw TalentResetError.noInvestedNodes }

        let cost = 500
        guard player.gold >= cost else {
            throw TalentResetError.insufficientGold(required: cost, have: player.gold)
        }

        player.gold                  -= cost
        player.availableTalentPoints += invested.count
        player.investedTalentKeysRaw  = ""

        try context.save()
    }
}

// MARK: - 天賦重置錯誤

enum TalentResetError: LocalizedError {
    case noInvestedNodes
    case insufficientGold(required: Int, have: Int)

    var errorDescription: String? {
        switch self {
        case .noInvestedNodes:
            return "尚未投入任何天賦"
        case .insufficientGold(let required, let have):
            return "金幣不足（需要 \(required)，擁有 \(have)）"
        }
    }
}

// MARK: - 錯誤型別

enum TalentError: LocalizedError {
    case noPointsAvailable
    case maxLevelReached
    case nodeNotFound
    case previousNodeNotInvested
    case routeLocked

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable:       return "沒有可用的天賦點"
        case .maxLevelReached:         return "此天賦節點已達投入上限"
        case .nodeNotFound:            return "找不到天賦節點"
        case .previousNodeNotInvested: return "需先解鎖前一個節點"
        case .routeLocked:             return "此路線已被互斥鎖定，請先重置天賦"
        }
    }
}
