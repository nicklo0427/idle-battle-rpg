// ProducerSkillDef.swift
// 生產者技能節點靜態定義（鑄造師 / 廚師 / 製藥師）
// 架構沿用 GathererSkillDef，靜態資料，不進 SwiftData

import Foundation

// MARK: - 效果

enum ProducerSkillEffect {
    case durationReduction(Double)  // 每點縮短 X% 任務時長（已在 TaskCreationService 套用）
    case goldCostReduction(Double)  // 每點降低 X% 金幣消耗
    case qualityBonus(Double)       // 精良↑裝備屬性 +X%（結算套用，待實作）
    case portionChance(Double)      // 額外產出機率（結算套用，待實作）
    case potencyBonus(Double)       // 藥水 / 料理效果 +X%（使用時套用，待實作）
}

// MARK: - 節點定義

struct ProducerSkillNodeDef {
    let key:               String
    let actorKey:          String
    let name:              String
    let description:       String
    let maxLevel:          Int
    let prerequisiteKey:   String?
    let prerequisiteLevel: Int
    let effect:            ProducerSkillEffect

    init(
        key: String,
        actorKey: String,
        name: String,
        description: String,
        maxLevel: Int,
        prerequisiteKey: String? = nil,
        prerequisiteLevel: Int = 1,
        effect: ProducerSkillEffect
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

extension ProducerSkillNodeDef {

    static let all: [ProducerSkillNodeDef] = [

        // MARK: 鑄造師（blacksmith）
        .init(key: "bs_speed", actorKey: "blacksmith",
              name: "快速鍛造",
              description: "每點縮短 5% 鑄造時間", maxLevel: 3,
              effect: .durationReduction(0.05)),
        .init(key: "bs_gold", actorKey: "blacksmith",
              name: "節省用金",
              description: "每點降低 10% 金幣消耗", maxLevel: 2,
              prerequisiteKey: "bs_speed", prerequisiteLevel: 1,
              effect: .goldCostReduction(0.10)),
        .init(key: "bs_mastery", actorKey: "blacksmith",
              name: "爐火純青",
              description: "每點提升精良及以上裝備 5% 屬性", maxLevel: 3,
              prerequisiteKey: "bs_gold", prerequisiteLevel: 1,
              effect: .qualityBonus(0.05)),

        // MARK: 廚師（chef）
        .init(key: "ch_speed", actorKey: "chef",
              name: "快速烹飪",
              description: "每點縮短 5% 烹飪時間", maxLevel: 3,
              effect: .durationReduction(0.05)),
        .init(key: "ch_portion", actorKey: "chef",
              name: "豐盛料理",
              description: "每點 10% 機率多產一份料理", maxLevel: 2,
              prerequisiteKey: "ch_speed", prerequisiteLevel: 1,
              effect: .portionChance(0.10)),
        .init(key: "ch_flavor", actorKey: "chef",
              name: "廚藝精進",
              description: "每點提升料理 Buff 效果 10%", maxLevel: 3,
              prerequisiteKey: "ch_portion", prerequisiteLevel: 1,
              effect: .potencyBonus(0.10)),

        // MARK: 製藥師（pharmacist）
        .init(key: "ph_speed", actorKey: "pharmacist",
              name: "快速煉藥",
              description: "每點縮短 5% 煉藥時間", maxLevel: 3,
              effect: .durationReduction(0.05)),
        .init(key: "ph_yield", actorKey: "pharmacist",
              name: "加量製造",
              description: "每點 10% 機率多產一瓶藥水", maxLevel: 2,
              prerequisiteKey: "ph_speed", prerequisiteLevel: 1,
              effect: .portionChance(0.10)),
        .init(key: "ph_potency", actorKey: "pharmacist",
              name: "精煉藥劑",
              description: "每點提升藥水回復量 10%", maxLevel: 3,
              prerequisiteKey: "ph_yield", prerequisiteLevel: 1,
              effect: .potencyBonus(0.10)),

        // MARK: 農夫（farmer）
        .init(key: "fa_speed", actorKey: "farmer",
              name: "快速生長",
              description: "每點縮短 5% 種植時間", maxLevel: 3,
              effect: .durationReduction(0.05)),
        .init(key: "fa_yield", actorKey: "farmer",
              name: "豐收之手",
              description: "每點 30% 機率多產一份農作物", maxLevel: 2,
              prerequisiteKey: "fa_speed", prerequisiteLevel: 1,
              effect: .portionChance(0.30)),
        .init(key: "fa_quality", actorKey: "farmer",
              name: "精心栽培",
              description: "每點提升 10% 高品質機率", maxLevel: 2,
              prerequisiteKey: "fa_yield", prerequisiteLevel: 1,
              effect: .qualityBonus(0.10)),
    ]

    static func nodes(for actorKey: String) -> [ProducerSkillNodeDef] {
        all.filter { $0.actorKey == actorKey }
    }

    static func find(key: String) -> ProducerSkillNodeDef? {
        all.first { $0.key == key }
    }
}

// MARK: - 便利屬性

extension ProducerSkillNodeDef {

    var speedReductionPerPoint: Double {
        if case .durationReduction(let d) = effect { return d }
        return 0
    }

    var goldReductionPerPoint: Double {
        if case .goldCostReduction(let d) = effect { return d }
        return 0
    }
}
