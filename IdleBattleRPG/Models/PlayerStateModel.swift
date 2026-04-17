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

    // MARK: - 敏捷 / 靈巧（V4-1 新增，SwiftData optional init 自動向後相容）
    var agiPoints: Int = 0   // 敏捷：影響 ATB 填充速度（越高攻擊越快）
    var dexPoints: Int = 0   // 靈巧：影響暴擊率（越高暴擊機率越高）

    // MARK: - NPC 升級 Tier（0 = 未升級，上限 NpcUpgradeDef.maxTier）
    var gatherer1Tier: Int = 0
    var gatherer2Tier: Int = 0
    var blacksmithTier: Int = 0

    // MARK: - 職業 & 技能（V6-1）

    /// 選定的職業 key（空字串 = 尚未選擇，觸發職業選擇畫面）
    var classKey: String = ""
    /// 已裝備的技能 key，逗號分隔，最多 4 個（e.g. "sw_slash_boost,sw_iron_will"）
    var equippedSkillKeysRaw: String = ""

    // MARK: - 天賦（V6-2）

    /// 可投入的天賦點數（升等 +1，初始 0）
    var availableTalentPoints: Int = 0
    /// 已投入的天賦節點 key，逗號分隔（e.g. "sw_berserker_1,sw_berserker_2"）
    var investedTalentKeysRaw: String = ""

    // MARK: - 技能升階（V6-2 T09）

    /// 可投入的技能點數（升等 +1，初始 0）
    var availableSkillPoints: Int = 0
    /// 技能升階等級，格式 "key:level,key:level"（e.g. "sw_heavy_slash:2,sw_iron_will:1"）
    var skillLevelsRaw: String = ""

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

// MARK: - 技能 & 天賦便利存取

extension PlayerStateModel {

    /// 已裝備技能 key 陣列（由 equippedSkillKeysRaw 解析，最多 4 個）
    var equippedSkillKeys: [String] {
        get {
            equippedSkillKeysRaw
                .split(separator: ",")
                .compactMap { s in s.isEmpty ? nil : String(s) }
        }
        set {
            equippedSkillKeysRaw = newValue.joined(separator: ",")
        }
    }

    /// 已投入天賦節點 key 陣列（由 investedTalentKeysRaw 解析）
    var investedTalentKeys: [String] {
        investedTalentKeysRaw
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// 技能升階等級字典（key: skillKey, value: 升階次數）
    var skillLevels: [String: Int] {
        Dictionary(uniqueKeysWithValues:
            skillLevelsRaw
                .split(separator: ",")
                .compactMap { pair -> (String, Int)? in
                    let parts = pair.split(separator: ":")
                    guard parts.count == 2, let lv = Int(parts[1]) else { return nil }
                    return (String(parts[0]), lv)
                }
        )
    }

    /// 取得指定技能的升階次數（未升階回傳 0）
    func level(of skillKey: String) -> Int {
        skillLevels[skillKey] ?? 0
    }

    /// 更新指定技能的升階次數（寫回 skillLevelsRaw）
    func setLevel(_ level: Int, of skillKey: String) {
        var levels = skillLevels
        if level <= 0 {
            levels.removeValue(forKey: skillKey)
        } else {
            levels[skillKey] = level
        }
        skillLevelsRaw = levels.map { "\($0.key):\($0.value)" }.joined(separator: ",")
    }
}
