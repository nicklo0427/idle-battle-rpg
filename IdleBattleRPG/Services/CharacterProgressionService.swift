// CharacterProgressionService.swift
// 英雄升級與屬性點分配
//
// 責任：
//   levelUp(player:)      — 驗證 EXP + 等級上限，扣除 EXP，升等，發放屬性點
//   allocatePoint(to:player:) — 消耗 1 可分配點，增加指定屬性
//
// 規則（AppConstants 為唯一數值來源）：
//   升級所需 EXP = AppConstants.ExpThreshold.required(toLevel:)
//   等級上限     = AppConstants.Game.heroMaxLevel（10）
//   每升一級     = +AppConstants.Game.statPointsPerLevel（3）屬性點

import Foundation
import SwiftData

// MARK: - StatType

enum StatType {
    case atk, def, hp, agi, dex
}

// MARK: - LevelUpError

enum LevelUpError: Error {
    case maxLevelReached
    case insufficientExp(required: Int, have: Int)

    var message: String {
        switch self {
        case .maxLevelReached:
            return "已達等級上限 Lv.\(AppConstants.Game.heroMaxLevel)"
        case let .insufficientExp(required, have):
            return "EXP 不足（需要 \(required)，擁有 \(have)）"
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

        guard let required = AppConstants.ExpThreshold.required(toLevel: nextLevel) else {
            return .failure(.maxLevelReached)
        }

        guard player.heroExp >= required else {
            return .failure(.insufficientExp(required: required, have: player.heroExp))
        }

        player.heroExp               -= required
        player.heroLevel              = nextLevel
        player.availableStatPoints   += AppConstants.Game.statPointsPerLevel
        player.availableTalentPoints += 1
        player.availableSkillPoints  += 1
        save()

        print("[CharacterProgressionService] 升級至 Lv.\(nextLevel)，扣除 EXP \(required)")
        return .success(())
    }

    // MARK: - 自動升級

    /// EXP 足夠時自動連續升級（可一次跨多級）。
    /// 在 TaskClaimService.creditExp() 入帳後呼叫。
    func autoLevelIfPossible(player: PlayerStateModel) {
        var leveled = false
        while true {
            let next = player.heroLevel + 1
            guard next <= AppConstants.Game.heroMaxLevel,
                  let required = AppConstants.ExpThreshold.required(toLevel: next),
                  player.heroExp >= required else { break }
            player.heroExp               -= required
            player.heroLevel              = next
            player.availableStatPoints   += AppConstants.Game.statPointsPerLevel
            player.availableTalentPoints += 1
            player.availableSkillPoints  += 1
            leveled = true
            print("[CharacterProgressionService] 自動升級至 Lv.\(next)，扣除 EXP \(required)")
        }
        if leveled { save() }
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
        case .agi: player.agiPoints += 1
        case .dex: player.dexPoints += 1
        }
        save()
        return true
    }

    // MARK: - 確認加點（pending → 正式寫入）

    /// 將 pending 點數批次寫入 PlayerStateModel。
    /// 呼叫前需確認 total delta ≤ availableStatPoints。
    func commitAllocations(
        player: PlayerStateModel,
        atkDelta: Int, defDelta: Int, hpDelta: Int,
        agiDelta: Int, dexDelta: Int
    ) {
        let total = atkDelta + defDelta + hpDelta + agiDelta + dexDelta
        guard total <= player.availableStatPoints else { return }
        player.atkPoints           += atkDelta
        player.defPoints           += defDelta
        player.hpPoints            += hpDelta
        player.agiPoints           += agiDelta
        player.dexPoints           += dexDelta
        player.availableStatPoints -= total
        save()
    }

    // MARK: - 重置所有屬性點

    /// 將 5 種屬性全部清零，所用點數退回 availableStatPoints。
    func resetAllStats(player: PlayerStateModel) {
        let used = player.atkPoints + player.defPoints + player.hpPoints
                 + player.agiPoints + player.dexPoints
        player.availableStatPoints += used
        player.atkPoints = 0
        player.defPoints = 0
        player.hpPoints  = 0
        player.agiPoints = 0
        player.dexPoints = 0
        save()
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
