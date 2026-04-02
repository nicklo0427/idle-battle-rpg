// CharacterProgressionService.swift
// 英雄升級與屬性點分配
//
// 責任：
//   levelUp(player:)      — 驗證金幣 + 等級上限，扣除金幣，升等，發放屬性點
//   allocatePoint(to:player:) — 消耗 1 可分配點，增加指定屬性
//
// 規則（AppConstants 為唯一數值來源）：
//   升級費用    = AppConstants.UpgradeCost.gold(toLevel:)
//   等級上限    = AppConstants.Game.heroMaxLevel（10）
//   每升一級    = +AppConstants.Game.statPointsPerLevel（3）屬性點

import Foundation
import SwiftData

// MARK: - StatType

enum StatType {
    case atk, def, hp
}

// MARK: - LevelUpError

enum LevelUpError: Error {
    case maxLevelReached
    case insufficientGold(required: Int, have: Int)

    var message: String {
        switch self {
        case .maxLevelReached:
            return "已達等級上限 Lv.\(AppConstants.Game.heroMaxLevel)"
        case let .insufficientGold(required, have):
            return "金幣不足（需要 \(required)，擁有 \(have)）"
        }
    }
}

// MARK: - CharacterProgressionService

struct CharacterProgressionService {

    let context: ModelContext

    // MARK: - 升級

    /// 驗證並執行升級。成功回傳 .success，失敗回傳對應 LevelUpError。
    @discardableResult
    func levelUp(player: PlayerStateModel) -> Result<Void, LevelUpError> {
        let nextLevel = player.heroLevel + 1

        guard nextLevel <= AppConstants.Game.heroMaxLevel else {
            return .failure(.maxLevelReached)
        }

        let cost = AppConstants.UpgradeCost.gold(toLevel: nextLevel)
        guard player.gold >= cost else {
            return .failure(.insufficientGold(required: cost, have: player.gold))
        }

        player.gold                -= cost
        player.heroLevel            = nextLevel
        player.availableStatPoints += AppConstants.Game.statPointsPerLevel
        save()

        print("[CharacterProgressionService] 升級至 Lv.\(nextLevel)，扣除金幣 \(cost)")
        return .success(())
    }

    // MARK: - 屬性點分配

    /// 消耗 1 可分配點，增加指定屬性。無可分配點時回傳 false（不寫入）。
    @discardableResult
    func allocatePoint(to stat: StatType, player: PlayerStateModel) -> Bool {
        guard player.availableStatPoints > 0 else { return false }

        player.availableStatPoints -= 1
        switch stat {
        case .atk: player.atkPoints += 1
        case .def: player.defPoints += 1
        case .hp:  player.hpPoints  += 1
        }
        save()
        return true
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
