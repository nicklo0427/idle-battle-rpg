// AchievementService.swift
// V4-4 成就系統：條件評估與解鎖
//
// 責任：
//   checkAll() — 對 AchievementDef.all 中每個尚未解鎖的成就進行條件評估，
//                若達成則呼叫 AchievementProgressModel.markUnlocked()
//
// 呼叫時機（Hook 插入點）：
//   - TaskClaimService.claimAllCompleted() 在所有獎勵入帳後
//     → 涵蓋 battlesWon / goldEarned / itemsCrafted / heroLevel（自動升級已發生）
//     → 涵蓋 floorCleared（SettlementService 已在 scanAndSettle() 期間標記）
//
// 設計原則：
//   - 純 struct，無 @Observable，不持有 UI 狀態
//   - 無副作用以外的 save()：只有確實解鎖新成就時才儲存一次
//   - checkAll() 冪等：重複呼叫不重複解鎖

import Foundation
import SwiftData

struct AchievementService {

    let context: ModelContext

    // MARK: - 主入口

    /// 掃描所有尚未解鎖的成就，若條件達成則標記解鎖並儲存。
    func checkAll() {
        let progressModel = fetchOrCreateProgressModel()

        let playerDesc = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(playerDesc))?.first else { return }

        let progressionService = DungeonProgressionService(context: context)

        var changed = false
        for achievement in AchievementDef.all {
            guard !progressModel.isUnlocked(key: achievement.key) else { continue }
            if evaluate(achievement.condition, player: player, progression: progressionService) {
                progressModel.markUnlocked(key: achievement.key)
                changed = true
                print("[AchievementService] 解鎖成就：\(achievement.icon) \(achievement.title)")
            }
        }

        if changed {
            try? context.save()
        }
    }

    // MARK: - 便利查詢（供 CharacterView 成就 UI 使用）

    /// 回傳所有成就及是否已解鎖的配對
    func allWithStatus() -> [(def: AchievementDef, unlocked: Bool)] {
        let progressModel = fetchOrCreateProgressModel()
        return AchievementDef.all.map { def in
            (def: def, unlocked: progressModel.isUnlocked(key: def.key))
        }
    }

    // MARK: - Private helpers

    private func fetchOrCreateProgressModel() -> AchievementProgressModel {
        let desc = FetchDescriptor<AchievementProgressModel>()
        if let existing = (try? context.fetch(desc))?.first {
            return existing
        }
        let model = AchievementProgressModel()
        context.insert(model)
        return model
    }

    private func evaluate(
        _ condition: AchievementCondition,
        player: PlayerStateModel,
        progression: DungeonProgressionService
    ) -> Bool {
        switch condition {
        case .heroLevel(let level):
            return player.heroLevel >= level

        case .battlesWon(let count):
            return player.totalBattlesWon >= count

        case .goldEarned(let amount):
            return player.totalGoldEarned >= amount

        case .itemsCrafted(let count):
            return player.totalItemsCrafted >= count

        case .floorCleared(let regionKey, let floorIndex):
            return progression.isFloorCleared(regionKey: regionKey, floorIndex: floorIndex)
        }
    }
}
