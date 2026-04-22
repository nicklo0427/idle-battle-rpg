// GathererSkillDef.swift
// 採集者技能節點靜態定義（V7-1 T02）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 效果

enum GathererSkillEffect {
    case yieldBonus(Int)            // 每點 +N 採集產出
    case durationReduction(Double)  // 每點縮短 X% 任務時長
    case rareChance(Double)         // 每點提升 X% 稀有事件機率（T03）
}

// MARK: - 節點定義

struct GathererSkillNodeDef {
    let key:               String
    let actorKey:          String
    let name:              String
    let description:       String
    let maxLevel:          Int
    let prerequisiteKey:   String?
    let prerequisiteLevel: Int      // 前置節點需達到的最低等級
    let effect:            GathererSkillEffect

    init(
        key: String,
        actorKey: String,
        name: String,
        description: String,
        maxLevel: Int,
        prerequisiteKey: String? = nil,
        prerequisiteLevel: Int = 1,
        effect: GathererSkillEffect
    ) {
        self.key               = key
        self.actorKey          = actorKey
        self.name              = name
        self.description       = description
        self.maxLevel          = maxLevel
        self.prerequisiteKey   = prerequisiteKey
        self.prerequisiteLevel = prerequisiteLevel
        self.effect            = effect
    }
}

// MARK: - 靜態資料

extension GathererSkillNodeDef {

    static let all: [GathererSkillNodeDef] = [

        // MARK: 伐木工（gatherer_1）
        .init(key: "g1_yield", actorKey: "gatherer_1",
              name: "砍伐熟練", description: "每點 +1 木材產出", maxLevel: 5,
              effect: .yieldBonus(1)),
        .init(key: "g1_speed", actorKey: "gatherer_1",
              name: "林地節奏", description: "每點縮短 5% 任務時長", maxLevel: 3,
              prerequisiteKey: "g1_yield", prerequisiteLevel: 1,
              effect: .durationReduction(0.05)),
        .init(key: "g1_rare", actorKey: "gatherer_1",
              name: "林中奇遇", description: "每點提升 5% 稀有事件機率", maxLevel: 3,
              prerequisiteKey: "g1_yield", prerequisiteLevel: 3,
              effect: .rareChance(0.05)),

        // MARK: 採礦工（gatherer_2）
        .init(key: "g2_yield", actorKey: "gatherer_2",
              name: "礦脈開採", description: "每點 +1 礦石產出", maxLevel: 5,
              effect: .yieldBonus(1)),
        .init(key: "g2_speed", actorKey: "gatherer_2",
              name: "採礦效率", description: "每點縮短 5% 任務時長", maxLevel: 3,
              prerequisiteKey: "g2_yield", prerequisiteLevel: 1,
              effect: .durationReduction(0.05)),
        .init(key: "g2_rare", actorKey: "gatherer_2",
              name: "礦中發現", description: "每點提升 5% 稀有事件機率", maxLevel: 3,
              prerequisiteKey: "g2_yield", prerequisiteLevel: 3,
              effect: .rareChance(0.05)),

        // MARK: 採藥師（gatherer_3）
        .init(key: "g3_yield", actorKey: "gatherer_3",
              name: "採藥精通", description: "每點 +1 草藥產出", maxLevel: 5,
              effect: .yieldBonus(1)),
        .init(key: "g3_speed", actorKey: "gatherer_3",
              name: "藥草識別", description: "每點縮短 5% 任務時長", maxLevel: 3,
              prerequisiteKey: "g3_yield", prerequisiteLevel: 1,
              effect: .durationReduction(0.05)),
        .init(key: "g3_rare", actorKey: "gatherer_3",
              name: "靈藥嗅覺", description: "每點提升 5% 稀有事件機率", maxLevel: 3,
              prerequisiteKey: "g3_yield", prerequisiteLevel: 3,
              effect: .rareChance(0.05)),

        // MARK: 漁夫（gatherer_4）
        .init(key: "g4_yield", actorKey: "gatherer_4",
              name: "漁獲豐收", description: "每點 +1 鮮魚產出", maxLevel: 5,
              effect: .yieldBonus(1)),
        .init(key: "g4_speed", actorKey: "gatherer_4",
              name: "精準拋線", description: "每點縮短 5% 任務時長", maxLevel: 3,
              prerequisiteKey: "g4_yield", prerequisiteLevel: 1,
              effect: .durationReduction(0.05)),
        .init(key: "g4_rare", actorKey: "gatherer_4",
              name: "深淵感應", description: "每點提升 5% 稀有事件機率", maxLevel: 3,
              prerequisiteKey: "g4_yield", prerequisiteLevel: 3,
              effect: .rareChance(0.05)),
    ]

    static func nodes(for actorKey: String) -> [GathererSkillNodeDef] {
        all.filter { $0.actorKey == actorKey }
    }

    static func find(key: String) -> GathererSkillNodeDef? {
        all.first { $0.key == key }
    }
}

// MARK: - 便利屬性

extension GathererSkillNodeDef {

    var yieldBonusPerPoint: Int {
        if case .yieldBonus(let n) = effect { return n }
        return 0
    }

    var speedReductionPerPoint: Double {
        if case .durationReduction(let d) = effect { return d }
        return 0
    }

    var rareChancePerPoint: Double {
        if case .rareChance(let r) = effect { return r }
        return 0
    }
}
