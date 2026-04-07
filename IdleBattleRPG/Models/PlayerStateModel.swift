// PlayerStateModel.swift
// 玩家狀態的持久化模型（全域單例）

import Foundation
import SwiftData

@Model
final class PlayerStateModel {

    // MARK: - 資源
    var gold: Int

    // MARK: - 英雄屬性點（來自升級分配）
    var heroLevel: Int
    var availableStatPoints: Int
    var atkPoints: Int
    var defPoints: Int
    var hpPoints: Int

    // MARK: - 時間追蹤
    var lastOpenedAt: Date

    // MARK: - 新手保護 Flag（各使用一次後永久消耗）
    var hasUsedFirstCraftBoost: Bool
    var hasUsedFirstDungeonBoost: Bool

    // MARK: - Onboarding 進度（0 = 尚未開始，3 = 完成）
    var onboardingStep: Int

    // MARK: - 英雄經驗值（消耗型，升級後扣除）
    var heroExp: Int = 0

    // MARK: - 累計統計
    var totalGoldEarned: Int = 0
    var totalBattlesWon: Int = 0
    var totalBattlesLost: Int = 0
    var totalItemsCrafted: Int = 0
    var highestPowerReached: Int = 0

    // MARK: - NPC 升級 Tier（0 = 未升級，上限 NpcUpgradeDef.maxTier）
    var gatherer1Tier: Int = 0
    var gatherer2Tier: Int = 0
    var blacksmithTier: Int = 0

    // MARK: - Init

    init(
        gold: Int = AppConstants.Initial.gold,
        heroLevel: Int = 1,
        availableStatPoints: Int = 0,
        atkPoints: Int = 5,
        defPoints: Int = 3,
        hpPoints: Int = 20,
        lastOpenedAt: Date = .now,
        hasUsedFirstCraftBoost: Bool = false,
        hasUsedFirstDungeonBoost: Bool = false,
        onboardingStep: Int = 0
    ) {
        self.gold                    = gold
        self.heroLevel               = heroLevel
        self.availableStatPoints     = availableStatPoints
        self.atkPoints               = atkPoints
        self.defPoints               = defPoints
        self.hpPoints                = hpPoints
        self.lastOpenedAt            = lastOpenedAt
        self.hasUsedFirstCraftBoost  = hasUsedFirstCraftBoost
        self.hasUsedFirstDungeonBoost = hasUsedFirstDungeonBoost
        self.onboardingStep          = onboardingStep
    }

    // MARK: - 便利查詢

    /// 根據 actorKey 回傳對應 NPC 的升級 Tier
    func tier(for actorKey: String) -> Int {
        switch actorKey {
        case "gatherer_1": return gatherer1Tier
        case "gatherer_2": return gatherer2Tier
        case "blacksmith":  return blacksmithTier
        default:            return 0
        }
    }

    /// 根據 actorKey 回傳對應的 NpcKind（供 NpcUpgradeService 呼叫）
    func npcKind(for actorKey: String) -> NpcKind? {
        switch actorKey {
        case "gatherer_1": return .woodcutter
        case "gatherer_2": return .miner
        case "blacksmith":  return .blacksmith
        default:            return nil
        }
    }
}
