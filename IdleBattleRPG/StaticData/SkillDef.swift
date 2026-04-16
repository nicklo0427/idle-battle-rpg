// SkillDef.swift
// V6-1 技能靜態定義
//
// 設計原則：
//   - 每個職業有 5 個專屬技能，升等自動解鎖（Lv.3/6/10/15/20）
//   - 技能效果永久持有，出征時最多裝備 4 個，全程生效
//   - 技能加成在出征建立時疊加到 snapshotStats，不依賴結算當下狀態
//   - 純 Swift struct，不進 SwiftData

import Foundation

// MARK: - 技能效果

enum SkillEffect {
    case atkBonus(Int)   // ATK 永久加成（出征期間）
    case defBonus(Int)   // DEF 永久加成
    case hpBonus(Int)    // HP 永久加成
    case agiBonus(Int)   // AGI 永久加成
    case dexBonus(Int)   // DEX 永久加成
}

// MARK: - 技能定義

struct SkillDef {
    let key:           String         // e.g. "sw_slash_boost"
    let classKey:      String         // 所屬職業 key
    let requiredLevel: Int            // 解鎖所需等級
    let name:          String         // 技能名稱
    let description:   String         // 效果說明
    let effects:       [SkillEffect]  // 支援多效果
}

// MARK: - 靜態資料

extension SkillDef {

    static let all: [SkillDef] = [
        // 劍士
        sw_slash_boost, sw_iron_will, sw_war_cry, sw_fierce_blow, sw_peerless,
        // 弓手
        ar_swift_step, ar_eagle_eye, ar_wind_walk, ar_sniper, ar_phantom_step,
        // 法師
        mg_magic_bolt, mg_arcane_shield, mg_mana_surge, mg_time_warp, mg_arcane_mastery,
        // 聖騎士
        pl_iron_guard, pl_healing_aura, pl_shield_wall, pl_blessed_armor, pl_aegis,
    ]

    static func find(key: String) -> SkillDef? {
        all.first { $0.key == key }
    }

    /// 取得特定職業在某等級下已解鎖的技能（依解鎖等級排序）
    static func unlocked(classKey: String, atLevel level: Int) -> [SkillDef] {
        all.filter { $0.classKey == classKey && $0.requiredLevel <= level }
           .sorted { $0.requiredLevel < $1.requiredLevel }
    }
}

// MARK: - UI 輔助

extension SkillDef {

    /// 效果摘要文字，e.g. "ATK +12" 或 "AGI +6  DEX +4"
    var effectSummary: String {
        effects.map { effect in
            switch effect {
            case .atkBonus(let v): return "ATK +\(v)"
            case .defBonus(let v): return "DEF +\(v)"
            case .hpBonus(let v):  return "HP +\(v)"
            case .agiBonus(let v): return "AGI +\(v)"
            case .dexBonus(let v): return "DEX +\(v)"
            }
        }.joined(separator: "  ")
    }
}

// MARK: - 劍士技能

extension SkillDef {

    static let sw_slash_boost = SkillDef(
        key:           "sw_slash_boost",
        classKey:      "swordsman",
        requiredLevel: 3,
        name:          "斬擊強化",
        description:   "攻擊力大幅提升。",
        effects:       [.atkBonus(12)]
    )

    static let sw_iron_will = SkillDef(
        key:           "sw_iron_will",
        classKey:      "swordsman",
        requiredLevel: 6,
        name:          "防禦姿態",
        description:   "出征全程防禦力提升。",
        effects:       [.defBonus(10)]
    )

    static let sw_war_cry = SkillDef(
        key:           "sw_war_cry",
        classKey:      "swordsman",
        requiredLevel: 10,
        name:          "戰吼",
        description:   "宣戰之吼，攻擊力再提升。",
        effects:       [.atkBonus(20)]
    )

    static let sw_fierce_blow = SkillDef(
        key:           "sw_fierce_blow",
        classKey:      "swordsman",
        requiredLevel: 15,
        name:          "猛擊",
        description:   "重擊技法，攻擊力大幅強化。",
        effects:       [.atkBonus(30)]
    )

    static let sw_peerless = SkillDef(
        key:           "sw_peerless",
        classKey:      "swordsman",
        requiredLevel: 20,
        name:          "無雙斬",
        description:   "無人可擋的究極斬技。",
        effects:       [.atkBonus(45)]
    )
}

// MARK: - 弓手技能

extension SkillDef {

    static let ar_swift_step = SkillDef(
        key:           "ar_swift_step",
        classKey:      "archer",
        requiredLevel: 3,
        name:          "疾風步法",
        description:   "移動速度提升，ATB 充能加快。",
        effects:       [.agiBonus(4)]
    )

    static let ar_eagle_eye = SkillDef(
        key:           "ar_eagle_eye",
        classKey:      "archer",
        requiredLevel: 6,
        name:          "銳眼訓練",
        description:   "精準度提升，暴擊率提升。",
        effects:       [.dexBonus(4)]
    )

    static let ar_wind_walk = SkillDef(
        key:           "ar_wind_walk",
        classKey:      "archer",
        requiredLevel: 10,
        name:          "迅風",
        description:   "風中漫步，速度大幅提升。",
        effects:       [.agiBonus(8)]
    )

    static let ar_sniper = SkillDef(
        key:           "ar_sniper",
        classKey:      "archer",
        requiredLevel: 15,
        name:          "神射",
        description:   "神乎其技的精準射擊。",
        effects:       [.dexBonus(8)]
    )

    static let ar_phantom_step = SkillDef(
        key:           "ar_phantom_step",
        classKey:      "archer",
        requiredLevel: 20,
        name:          "幻影步",
        description:   "殘影交錯，極速移動。",
        effects:       [.agiBonus(14)]
    )
}

// MARK: - 法師技能

extension SkillDef {

    static let mg_magic_bolt = SkillDef(
        key:           "mg_magic_bolt",
        classKey:      "mage",
        requiredLevel: 3,
        name:          "魔力箭",
        description:   "魔力凝聚成矢，增強攻擊。",
        effects:       [.atkBonus(8)]
    )

    static let mg_arcane_shield = SkillDef(
        key:           "mg_arcane_shield",
        classKey:      "mage",
        requiredLevel: 6,
        name:          "魔法護盾",
        description:   "奧術護盾，防禦力提升。",
        effects:       [.defBonus(8)]
    )

    static let mg_mana_surge = SkillDef(
        key:           "mg_mana_surge",
        classKey:      "mage",
        requiredLevel: 10,
        name:          "魔力衝湧",
        description:   "魔力爆發，攻擊力大增。",
        effects:       [.atkBonus(16)]
    )

    static let mg_time_warp = SkillDef(
        key:           "mg_time_warp",
        classKey:      "mage",
        requiredLevel: 15,
        name:          "時流扭曲",
        description:   "扭曲時間軸，速度與精準同時提升。",
        effects:       [.agiBonus(6), .dexBonus(4)]
    )

    static let mg_arcane_mastery = SkillDef(
        key:           "mg_arcane_mastery",
        classKey:      "mage",
        requiredLevel: 20,
        name:          "奧術精通",
        description:   "掌握奧術奧義，攻擊達到極致。",
        effects:       [.atkBonus(25)]
    )
}

// MARK: - 聖騎士技能

extension SkillDef {

    static let pl_iron_guard = SkillDef(
        key:           "pl_iron_guard",
        classKey:      "paladin",
        requiredLevel: 3,
        name:          "鐵壁防禦",
        description:   "以盾為牆，防禦力提升。",
        effects:       [.defBonus(10)]
    )

    static let pl_healing_aura = SkillDef(
        key:           "pl_healing_aura",
        classKey:      "paladin",
        requiredLevel: 6,
        name:          "治癒光環",
        description:   "神聖光環環繞，生命值提升。",
        effects:       [.hpBonus(30)]
    )

    static let pl_shield_wall = SkillDef(
        key:           "pl_shield_wall",
        classKey:      "paladin",
        requiredLevel: 10,
        name:          "護盾之牆",
        description:   "多重護盾疊加，防禦大幅提升。",
        effects:       [.defBonus(18)]
    )

    static let pl_blessed_armor = SkillDef(
        key:           "pl_blessed_armor",
        classKey:      "paladin",
        requiredLevel: 15,
        name:          "神佑鎧甲",
        description:   "神之庇護，防禦與生命同時提升。",
        effects:       [.defBonus(25), .hpBonus(20)]
    )

    static let pl_aegis = SkillDef(
        key:           "pl_aegis",
        classKey:      "paladin",
        requiredLevel: 20,
        name:          "神盾庇護",
        description:   "傳說中的神盾，防禦達到極致。",
        effects:       [.defBonus(35)]
    )
}
