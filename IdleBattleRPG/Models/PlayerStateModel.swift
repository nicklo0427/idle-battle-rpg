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
}
