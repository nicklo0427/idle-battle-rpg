// TalentDef.swift
// V6-2 天賦靜態定義
//
// 純 Swift struct，不進 SwiftData
// 8 條路線（每職業 2 條）× 5 個節點 = 40 個節點

import Foundation

// MARK: - TalentEffect

enum TalentEffect {
    case atkPercent(Double)
    case defPercent(Double)
    case hpPercent(Double)
    case critRatePercent(Double)
    case skillDmgPercent(Double)
    case healPercent(Double)
}

extension TalentEffect {
    var summary: String {
        func fmt(_ v: Double) -> String { "\(Int(v * 100))%" }
        switch self {
        case .atkPercent(let v):      return "ATK +\(fmt(v))"
        case .defPercent(let v):      return "DEF +\(fmt(v))"
        case .hpPercent(let v):       return "HP +\(fmt(v))"
        case .critRatePercent(let v): return "Crit +\(fmt(v))"
        case .skillDmgPercent(let v): return "SkillDmg +\(fmt(v))"
        case .healPercent(let v):     return "Heal +\(fmt(v))"
        }
    }
}

// MARK: - TalentNodeDef

struct TalentNodeDef {
    let key:         String
    let name:        String
    let description: String
    let routeKey:    String
    let nodeIndex:   Int
    let effects:     [TalentEffect]
    let maxLevel:    Int   // nodeIndex 0/1→3, 2/3→2, 4→1
}

extension TalentNodeDef {
    static func find(key: String) -> TalentNodeDef? {
        TalentRouteDef.allRoutes.flatMap(\.nodes).first { $0.key == key }
    }

    var effectSummary: String {
        effects.map(\.summary).joined(separator: " · ")
    }

    func currentLevel(in player: PlayerStateModel) -> Int {
        player.investedTalentKeys.filter { $0 == key }.count
    }

    func isMaxed(in player: PlayerStateModel) -> Bool {
        currentLevel(in: player) >= maxLevel
    }
}

// MARK: - TalentRouteDef

struct TalentRouteDef {
    let key:              String
    let name:             String
    let classKey:         String
    let themeDescription: String
    let nodes:            [TalentNodeDef]
}

extension TalentRouteDef {
    static func all(for classKey: String) -> [TalentRouteDef] {
        allRoutes.filter { $0.classKey == classKey }
    }

    static func find(key: String) -> TalentRouteDef? {
        allRoutes.first { $0.key == key }
    }
}

// MARK: - 靜態資料

extension TalentRouteDef {
    static let allRoutes: [TalentRouteDef] = [
        swBerserker, swIronwall,
        arPrecision, arPoison,
        mgBurst, mgBarrier,
        plHoly, plJudgment
    ]

    // MARK: 劍士

    static let swBerserker = TalentRouteDef(
        key: "sw_berserker",
        name: "狂戰士",
        classKey: "swordsman",
        themeDescription: "以傷換傷，高爆發攻擊",
        nodes: [
            TalentNodeDef(key: "sw_berserker_1", name: "蠻力突破", description: "ATK +3%",          routeKey: "sw_berserker", nodeIndex: 0, effects: [.atkPercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "sw_berserker_2", name: "戰意高漲", description: "ATK +5%",          routeKey: "sw_berserker", nodeIndex: 1, effects: [.atkPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "sw_berserker_3", name: "致命衝動", description: "ATK +5%, Crit +2%", routeKey: "sw_berserker", nodeIndex: 2, effects: [.atkPercent(0.05), .critRatePercent(0.02)], maxLevel: 2),
            TalentNodeDef(key: "sw_berserker_4", name: "血怒覺醒", description: "ATK +8%",          routeKey: "sw_berserker", nodeIndex: 3, effects: [.atkPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "sw_berserker_5", name: "不滅戰魂", description: "ATK +10%",         routeKey: "sw_berserker", nodeIndex: 4, effects: [.atkPercent(0.10)], maxLevel: 1)
        ]
    )

    static let swIronwall = TalentRouteDef(
        key: "sw_ironwall",
        name: "鐵壁",
        classKey: "swordsman",
        themeDescription: "以守為攻，堅不可摧",
        nodes: [
            TalentNodeDef(key: "sw_ironwall_1", name: "硬化皮膚", description: "DEF +3%",          routeKey: "sw_ironwall", nodeIndex: 0, effects: [.defPercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "sw_ironwall_2", name: "強壯體魄", description: "HP +5%",           routeKey: "sw_ironwall", nodeIndex: 1, effects: [.hpPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "sw_ironwall_3", name: "鐵甲磨礪", description: "DEF +5%",          routeKey: "sw_ironwall", nodeIndex: 2, effects: [.defPercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "sw_ironwall_4", name: "生命汲取", description: "HP +8%",           routeKey: "sw_ironwall", nodeIndex: 3, effects: [.hpPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "sw_ironwall_5", name: "鋼鐵意志", description: "DEF +8%, HP +5%",  routeKey: "sw_ironwall", nodeIndex: 4, effects: [.defPercent(0.08), .hpPercent(0.05)], maxLevel: 1)
        ]
    )

    // MARK: 弓手

    static let arPrecision = TalentRouteDef(
        key: "ar_precision",
        name: "精準",
        classKey: "archer",
        themeDescription: "精心瞄準，必中要害",
        nodes: [
            TalentNodeDef(key: "ar_precision_1", name: "鷹眼觀察", description: "Crit +3%",               routeKey: "ar_precision", nodeIndex: 0, effects: [.critRatePercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "ar_precision_2", name: "穩定呼吸", description: "Crit +3%",               routeKey: "ar_precision", nodeIndex: 1, effects: [.critRatePercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "ar_precision_3", name: "要害穿刺", description: "SkillDmg +5%",           routeKey: "ar_precision", nodeIndex: 2, effects: [.skillDmgPercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "ar_precision_4", name: "獵手本能", description: "Crit +5%",               routeKey: "ar_precision", nodeIndex: 3, effects: [.critRatePercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "ar_precision_5", name: "神射境界", description: "Crit +5%, SkillDmg +10%", routeKey: "ar_precision", nodeIndex: 4, effects: [.critRatePercent(0.05), .skillDmgPercent(0.10)], maxLevel: 1)
        ]
    )

    static let arPoison = TalentRouteDef(
        key: "ar_poison",
        name: "毒箭",
        classKey: "archer",
        themeDescription: "侵蝕削弱，持續消耗",
        nodes: [
            TalentNodeDef(key: "ar_poison_1", name: "淬毒箭頭", description: "ATK +3%",              routeKey: "ar_poison", nodeIndex: 0, effects: [.atkPercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "ar_poison_2", name: "腐蝕劑量", description: "SkillDmg +5%",         routeKey: "ar_poison", nodeIndex: 1, effects: [.skillDmgPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "ar_poison_3", name: "劇毒萃取", description: "ATK +5%",              routeKey: "ar_poison", nodeIndex: 2, effects: [.atkPercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "ar_poison_4", name: "蔓延感染", description: "SkillDmg +8%",         routeKey: "ar_poison", nodeIndex: 3, effects: [.skillDmgPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "ar_poison_5", name: "致命毒素", description: "ATK +8%, SkillDmg +5%", routeKey: "ar_poison", nodeIndex: 4, effects: [.atkPercent(0.08), .skillDmgPercent(0.05)], maxLevel: 1)
        ]
    )

    // MARK: 法師

    static let mgBurst = TalentRouteDef(
        key: "mg_burst",
        name: "爆發",
        classKey: "mage",
        themeDescription: "蓄積魔力，一擊必殺",
        nodes: [
            TalentNodeDef(key: "mg_burst_1", name: "魔力聚焦", description: "SkillDmg +5%",  routeKey: "mg_burst", nodeIndex: 0, effects: [.skillDmgPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "mg_burst_2", name: "靈能共鳴", description: "SkillDmg +5%",  routeKey: "mg_burst", nodeIndex: 1, effects: [.skillDmgPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "mg_burst_3", name: "元素過載", description: "SkillDmg +8%",  routeKey: "mg_burst", nodeIndex: 2, effects: [.skillDmgPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "mg_burst_4", name: "魔法強化", description: "ATK +5%",       routeKey: "mg_burst", nodeIndex: 3, effects: [.atkPercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "mg_burst_5", name: "奧術暴走", description: "SkillDmg +10%", routeKey: "mg_burst", nodeIndex: 4, effects: [.skillDmgPercent(0.10)], maxLevel: 1)
        ]
    )

    static let mgBarrier = TalentRouteDef(
        key: "mg_barrier",
        name: "結界",
        classKey: "mage",
        themeDescription: "魔力護盾，以耐制勝",
        nodes: [
            TalentNodeDef(key: "mg_barrier_1", name: "魔力皮膚", description: "HP +5%",    routeKey: "mg_barrier", nodeIndex: 0, effects: [.hpPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "mg_barrier_2", name: "反射護盾", description: "DEF +3%",   routeKey: "mg_barrier", nodeIndex: 1, effects: [.defPercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "mg_barrier_3", name: "生命強化", description: "HP +8%",    routeKey: "mg_barrier", nodeIndex: 2, effects: [.hpPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "mg_barrier_4", name: "治癒波動", description: "Heal +10%", routeKey: "mg_barrier", nodeIndex: 3, effects: [.healPercent(0.10)], maxLevel: 2),
            TalentNodeDef(key: "mg_barrier_5", name: "不朽之軀", description: "HP +10%",   routeKey: "mg_barrier", nodeIndex: 4, effects: [.hpPercent(0.10)], maxLevel: 1)
        ]
    )

    // MARK: 聖騎士

    static let plHoly = TalentRouteDef(
        key: "pl_holy",
        name: "神聖",
        classKey: "paladin",
        themeDescription: "神聖光輝，治癒庇護",
        nodes: [
            TalentNodeDef(key: "pl_holy_1", name: "聖光觸碰", description: "Heal +5%",  routeKey: "pl_holy", nodeIndex: 0, effects: [.healPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "pl_holy_2", name: "神聖祈禱", description: "HP +5%",    routeKey: "pl_holy", nodeIndex: 1, effects: [.hpPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "pl_holy_3", name: "光明恩賜", description: "Heal +8%",  routeKey: "pl_holy", nodeIndex: 2, effects: [.healPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "pl_holy_4", name: "聖域守護", description: "HP +8%",    routeKey: "pl_holy", nodeIndex: 3, effects: [.hpPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "pl_holy_5", name: "神聖奇蹟", description: "Heal +15%", routeKey: "pl_holy", nodeIndex: 4, effects: [.healPercent(0.15)], maxLevel: 1)
        ]
    )

    static let plJudgment = TalentRouteDef(
        key: "pl_judgment",
        name: "審判",
        classKey: "paladin",
        themeDescription: "神聖審判，以正義之名傷敵",
        nodes: [
            TalentNodeDef(key: "pl_judgment_1", name: "正義之怒", description: "ATK +3%",              routeKey: "pl_judgment", nodeIndex: 0, effects: [.atkPercent(0.03)], maxLevel: 3),
            TalentNodeDef(key: "pl_judgment_2", name: "神聖烙印", description: "SkillDmg +5%",         routeKey: "pl_judgment", nodeIndex: 1, effects: [.skillDmgPercent(0.05)], maxLevel: 3),
            TalentNodeDef(key: "pl_judgment_3", name: "聖徒鍛鍊", description: "ATK +5%",              routeKey: "pl_judgment", nodeIndex: 2, effects: [.atkPercent(0.05)], maxLevel: 2),
            TalentNodeDef(key: "pl_judgment_4", name: "神裁印記", description: "SkillDmg +8%",         routeKey: "pl_judgment", nodeIndex: 3, effects: [.skillDmgPercent(0.08)], maxLevel: 2),
            TalentNodeDef(key: "pl_judgment_5", name: "最終審判", description: "ATK +8%, SkillDmg +5%", routeKey: "pl_judgment", nodeIndex: 4, effects: [.atkPercent(0.08), .skillDmgPercent(0.05)], maxLevel: 1)
        ]
    )
}
