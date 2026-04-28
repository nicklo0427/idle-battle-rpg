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
    var gatherer3Tier: Int = 0   // 採藥師
    var gatherer4Tier: Int = 0   // 漁夫

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

    // MARK: - 料理 Buff（V7-3）

    /// 目前生效的料理 key（空字串 = 無 buff）
    var activeCuisineKey: String = ""
    /// Buff 到期時間（timeIntervalSinceReferenceDate；0 = 無 buff）
    var cuisineBuffExpiresAt: Double = 0

    // MARK: - 廚師升級 Tier（V7-3）
    var chefTier: Int = 0

    // MARK: - 農夫升級 Tier（V7-4）
    /// 控制可用農田數量：availablePlots = gatherer5Tier + 1（最多 4 塊）
    var gatherer5Tier: Int = 0

    // MARK: - 製藥師升級 Tier（V7-4）
    var pharmacistTier: Int = 0

    // MARK: - 採集者技能（V7-1 T02）

    var gatherer1SkillPoints: Int = 0
    var gatherer1SkillsRaw:   String = ""
    var gatherer2SkillPoints: Int = 0
    var gatherer2SkillsRaw:   String = ""
    var gatherer3SkillPoints: Int = 0
    var gatherer3SkillsRaw:   String = ""
    var gatherer4SkillPoints: Int = 0
    var gatherer4SkillsRaw:   String = ""

    // MARK: - 生產者技能

    var blacksmithSkillPoints: Int = 0
    var blacksmithSkillsRaw:   String = ""
    var chefSkillPoints:       Int = 0
    var chefSkillsRaw:         String = ""
    var pharmacistSkillPoints: Int = 0
    var pharmacistSkillsRaw:   String = ""
    var farmerSkillPoints:     Int = 0
    var farmerSkillsRaw:       String = ""

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
        case "gatherer_3": return gatherer3Tier
        case "gatherer_4": return gatherer4Tier
        case "chef":        return chefTier
        // V7-4 農田共用同一個 Tier（多塊田由同一個農夫管理）
        case "farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4":
            return gatherer5Tier
        case "pharmacist":  return pharmacistTier
        default:            return 0
        }
    }

    /// 根據 actorKey 回傳對應的 NpcKind（供 NpcUpgradeService 呼叫）
    func npcKind(for actorKey: String) -> NpcKind? {
        switch actorKey {
        case "gatherer_1": return .woodcutter
        case "gatherer_2": return .miner
        case "blacksmith":  return .blacksmith
        case "gatherer_3": return .herbalist
        case "gatherer_4": return .fisherman
        case "chef":        return .chef
        // V7-4 農田（升級 farmer 時消耗相同成本）
        case "farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4":
            return .farmer
        case "pharmacist":  return .pharmacist
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

// MARK: - 採集者技能便利存取（V7-1 T02）

extension PlayerStateModel {

    /// 指定採集者已投入技能 key 陣列
    func investedSkillKeys(for actorKey: String) -> [String] {
        rawSkills(for: actorKey)
            .split(separator: ",")
            .compactMap { s in s.isEmpty ? nil : String(s) }
    }

    /// 指定 NPC 可用技能點數（採集者 + 生產者）
    func skillPoints(for actorKey: String) -> Int {
        switch actorKey {
        case "gatherer_1":  return gatherer1SkillPoints
        case "gatherer_2":  return gatherer2SkillPoints
        case "gatherer_3":  return gatherer3SkillPoints
        case "gatherer_4":  return gatherer4SkillPoints
        case "blacksmith":  return blacksmithSkillPoints
        case "chef":        return chefSkillPoints
        case "pharmacist":  return pharmacistSkillPoints
        case "farmer":      return farmerSkillPoints
        default: return 0
        }
    }

    /// 指定節點的已投入次數（即等級）
    func skillLevel(nodeKey: String, actorKey: String) -> Int {
        investedSkillKeys(for: actorKey).filter { $0 == nodeKey }.count
    }

    func decrementSkillPoints(for actorKey: String) {
        switch actorKey {
        case "gatherer_1":  gatherer1SkillPoints  = max(0, gatherer1SkillPoints  - 1)
        case "gatherer_2":  gatherer2SkillPoints  = max(0, gatherer2SkillPoints  - 1)
        case "gatherer_3":  gatherer3SkillPoints  = max(0, gatherer3SkillPoints  - 1)
        case "gatherer_4":  gatherer4SkillPoints  = max(0, gatherer4SkillPoints  - 1)
        case "blacksmith":  blacksmithSkillPoints = max(0, blacksmithSkillPoints - 1)
        case "chef":        chefSkillPoints       = max(0, chefSkillPoints       - 1)
        case "pharmacist":  pharmacistSkillPoints = max(0, pharmacistSkillPoints - 1)
        case "farmer":      farmerSkillPoints     = max(0, farmerSkillPoints     - 1)
        default: break
        }
    }

    func appendSkillKey(_ key: String, for actorKey: String) {
        let updated = (investedSkillKeys(for: actorKey) + [key]).joined(separator: ",")
        switch actorKey {
        case "gatherer_1":  gatherer1SkillsRaw  = updated
        case "gatherer_2":  gatherer2SkillsRaw  = updated
        case "gatherer_3":  gatherer3SkillsRaw  = updated
        case "gatherer_4":  gatherer4SkillsRaw  = updated
        case "blacksmith":  blacksmithSkillsRaw = updated
        case "chef":        chefSkillsRaw       = updated
        case "pharmacist":  pharmacistSkillsRaw = updated
        case "farmer":      farmerSkillsRaw     = updated
        default: break
        }
    }

    private func rawSkills(for actorKey: String) -> String {
        switch actorKey {
        case "gatherer_1":  return gatherer1SkillsRaw
        case "gatherer_2":  return gatherer2SkillsRaw
        case "gatherer_3":  return gatherer3SkillsRaw
        case "gatherer_4":  return gatherer4SkillsRaw
        case "blacksmith":  return blacksmithSkillsRaw
        case "chef":        return chefSkillsRaw
        case "pharmacist":  return pharmacistSkillsRaw
        case "farmer":      return farmerSkillsRaw
        default: return ""
        }
    }
}
