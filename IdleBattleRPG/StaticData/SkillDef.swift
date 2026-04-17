// SkillDef.swift
// V6-1 技能靜態定義（修訂版）
//
// 設計原則：
//   - 每個職業有 5 個專屬主動技能，升等自動解鎖（Lv.3/6/10/15/20）
//   - 技能學了永久持有，出征時最多裝備 4 個嵌入格
//   - 技能在戰鬥中自動觸發（方案 A：獨立冷卻計時器）
//   - 技能效果在 BattleLogGenerator 中計算，不 bake 進 snapshotPower
//   - 純 Swift struct，不進 SwiftData

import Foundation

// MARK: - 主動技能效果

enum ActiveEffect {
    /// 對敵造成 heroAtk × multiplier 傷害
    case damage(multiplier: Double)

    /// 恢復英雄 heroMaxHp × multiplier HP
    case heal(multiplier: Double)

    /// 傷害 + 治癒組合（單一技能事件）
    case damageAndHeal(dmgMultiplier: Double, healMultiplier: Double)

    /// 下次英雄攻擊傷害 × (1 + bonus)（單次生效後重置）
    case heroAtkUp(bonus: Double)

    /// 下次敵方攻擊傷害 × (1 - reduction)（單次生效後重置）
    case enemyAtkDown(reduction: Double)

    /// 傷害 + 下次敵方攻擊削弱組合（mg_frost_nova 用）
    case damageAndEnemyAtkDown(dmgMultiplier: Double, reduction: Double)
}

// MARK: - 技能定義

struct SkillDef {
    let key:             String        // e.g. "sw_heavy_slash"
    let classKey:        String        // 所屬職業 key
    let requiredLevel:   Int           // 解鎖所需等級
    let name:            String        // 技能名稱
    let description:     String        // 效果說明
    let cooldownSeconds: Int           // 冷卻時間（秒）
    let effect:          ActiveEffect  // 主動效果
}

// MARK: - 靜態查詢

extension SkillDef {

    static let all: [SkillDef] = [
        // 劍士
        sw_heavy_slash, sw_battle_cry, sw_whirlwind, sw_intimidate, sw_deathblow,
        // 弓手
        ar_rapid_shot, ar_cripple, ar_barrage, ar_eagle_shot, ar_lethal_aim,
        // 法師
        mg_fireball, mg_frost_nova, mg_arcane_blast, mg_mana_shield, mg_meteor,
        // 聖騎士
        pl_holy_strike, pl_divine_shield, pl_consecration, pl_holy_light, pl_judgment,
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

    /// 效果摘要文字，例："150% ATK 傷害 · CD 20s"
    var effectSummary: String {
        let effectText: String
        switch effect {
        case .damage(let m):
            effectText = "\(Int(m * 100))% ATK 傷害"
        case .heal(let m):
            effectText = "恢復 \(Int(m * 100))% HP"
        case .damageAndHeal(let dm, let hm):
            effectText = "\(Int(dm * 100))% ATK 傷害 + 恢復 \(Int(hm * 100))% HP"
        case .heroAtkUp(let b):
            effectText = "下次攻擊 +\(Int(b * 100))% 傷害"
        case .enemyAtkDown(let r):
            effectText = "敵方下次攻擊 -\(Int(r * 100))%"
        case .damageAndEnemyAtkDown(let dm, let r):
            effectText = "\(Int(dm * 100))% ATK 傷害 + 敵方下次攻擊 -\(Int(r * 100))%"
        }
        return "\(effectText) · CD \(cooldownSeconds)s"
    }
}

// MARK: - 劍士技能（爆發傷害型）

extension SkillDef {

    static let sw_heavy_slash = SkillDef(
        key:             "sw_heavy_slash",
        classKey:        "swordsman",
        requiredLevel:   3,
        name:            "重斬擊",
        description:     "以全身之力揮下重斬，對敵造成巨大傷害。",
        cooldownSeconds: 20,
        effect:          .damage(multiplier: 1.5)
    )

    static let sw_battle_cry = SkillDef(
        key:             "sw_battle_cry",
        classKey:        "swordsman",
        requiredLevel:   6,
        name:            "戰吼",
        description:     "發出震天戰吼，下次攻擊傷害大幅提升。",
        cooldownSeconds: 28,
        effect:          .heroAtkUp(bonus: 0.8)
    )

    static let sw_whirlwind = SkillDef(
        key:             "sw_whirlwind",
        classKey:        "swordsman",
        requiredLevel:   10,
        name:            "旋風斬",
        description:     "旋轉揮劍，掃蕩敵方。",
        cooldownSeconds: 28,
        effect:          .damage(multiplier: 2.0)
    )

    static let sw_intimidate = SkillDef(
        key:             "sw_intimidate",
        classKey:        "swordsman",
        requiredLevel:   15,
        name:            "威嚇",
        description:     "凌厲眼神壓制敵方鬥志，大幅削弱其下次攻擊。",
        cooldownSeconds: 35,
        effect:          .enemyAtkDown(reduction: 0.4)
    )

    static let sw_deathblow = SkillDef(
        key:             "sw_deathblow",
        classKey:        "swordsman",
        requiredLevel:   20,
        name:            "必殺一擊",
        description:     "集結所有力量的究極斬擊，無人可擋。",
        cooldownSeconds: 45,
        effect:          .damage(multiplier: 3.0)
    )
}

// MARK: - 弓手技能（速攻 + 減益型）

extension SkillDef {

    static let ar_rapid_shot = SkillDef(
        key:             "ar_rapid_shot",
        classKey:        "archer",
        requiredLevel:   3,
        name:            "速射",
        description:     "閃電般的快速射擊，短暫冷卻即可再次發動。",
        cooldownSeconds: 12,
        effect:          .damage(multiplier: 1.2)
    )

    static let ar_cripple = SkillDef(
        key:             "ar_cripple",
        classKey:        "archer",
        requiredLevel:   6,
        name:            "腱射",
        description:     "精準射中敵方弱點，大幅削弱其反擊力道。",
        cooldownSeconds: 22,
        effect:          .enemyAtkDown(reduction: 0.5)
    )

    static let ar_barrage = SkillDef(
        key:             "ar_barrage",
        classKey:        "archer",
        requiredLevel:   10,
        name:            "連矢",
        description:     "連續發射多支箭矢，密集打擊敵方。",
        cooldownSeconds: 22,
        effect:          .damage(multiplier: 1.8)
    )

    static let ar_eagle_shot = SkillDef(
        key:             "ar_eagle_shot",
        classKey:        "archer",
        requiredLevel:   15,
        name:            "神鷹射",
        description:     "模仿神鷹俯衝之姿，以極高精準度貫穿敵方。",
        cooldownSeconds: 32,
        effect:          .damage(multiplier: 2.4)
    )

    static let ar_lethal_aim = SkillDef(
        key:             "ar_lethal_aim",
        classKey:        "archer",
        requiredLevel:   20,
        name:            "致命狙擊",
        description:     "鎖定致命要害，一擊決勝負。",
        cooldownSeconds: 42,
        effect:          .damage(multiplier: 3.4)
    )
}

// MARK: - 法師技能（爆發 + 混合型）

extension SkillDef {

    static let mg_fireball = SkillDef(
        key:             "mg_fireball",
        classKey:        "mage",
        requiredLevel:   3,
        name:            "火球術",
        description:     "凝聚魔力成火球，爆炸造成範圍傷害。",
        cooldownSeconds: 18,
        effect:          .damage(multiplier: 1.4)
    )

    static let mg_frost_nova = SkillDef(
        key:             "mg_frost_nova",
        classKey:        "mage",
        requiredLevel:   6,
        name:            "冰霜新星",
        description:     "冰霜爆發同時傷害敵方並封凍其行動力。",
        cooldownSeconds: 28,
        effect:          .damageAndEnemyAtkDown(dmgMultiplier: 1.2, reduction: 0.35)
    )

    static let mg_arcane_blast = SkillDef(
        key:             "mg_arcane_blast",
        classKey:        "mage",
        requiredLevel:   10,
        name:            "魔爆",
        description:     "奧術能量瞬間爆發，造成巨大魔法傷害。",
        cooldownSeconds: 30,
        effect:          .damage(multiplier: 2.1)
    )

    static let mg_mana_shield = SkillDef(
        key:             "mg_mana_shield",
        classKey:        "mage",
        requiredLevel:   15,
        name:            "魔盾恢復",
        description:     "將魔力轉化為生命能量，恢復自身 HP。",
        cooldownSeconds: 35,
        effect:          .heal(multiplier: 0.15)
    )

    static let mg_meteor = SkillDef(
        key:             "mg_meteor",
        classKey:        "mage",
        requiredLevel:   20,
        name:            "隕星術",
        description:     "召喚天外隕石砸落，究極毀滅之術。",
        cooldownSeconds: 50,
        effect:          .damage(multiplier: 3.1)
    )
}

// MARK: - 聖騎士技能（坦克 + 治癒型）

extension SkillDef {

    static let pl_holy_strike = SkillDef(
        key:             "pl_holy_strike",
        classKey:        "paladin",
        requiredLevel:   3,
        name:            "聖光擊",
        description:     "以聖光注入武器攻擊，同時恢復自身生命。",
        cooldownSeconds: 22,
        effect:          .damageAndHeal(dmgMultiplier: 1.2, healMultiplier: 0.1)
    )

    static let pl_divine_shield = SkillDef(
        key:             "pl_divine_shield",
        classKey:        "paladin",
        requiredLevel:   6,
        name:            "神盾",
        description:     "召喚神聖護盾，大幅削弱敵方下次攻擊。",
        cooldownSeconds: 32,
        effect:          .enemyAtkDown(reduction: 0.6)
    )

    static let pl_consecration = SkillDef(
        key:             "pl_consecration",
        classKey:        "paladin",
        requiredLevel:   10,
        name:            "奉獻",
        description:     "以神聖之力奉獻攻擊並恢復自身。",
        cooldownSeconds: 34,
        effect:          .damageAndHeal(dmgMultiplier: 1.6, healMultiplier: 0.12)
    )

    static let pl_holy_light = SkillDef(
        key:             "pl_holy_light",
        classKey:        "paladin",
        requiredLevel:   15,
        name:            "神聖之光",
        description:     "聖光籠罩全身，大量恢復生命值。",
        cooldownSeconds: 40,
        effect:          .heal(multiplier: 0.25)
    )

    static let pl_judgment = SkillDef(
        key:             "pl_judgment",
        classKey:        "paladin",
        requiredLevel:   20,
        name:            "審判",
        description:     "以神之名降下審判，給予敵方毀滅性打擊。",
        cooldownSeconds: 55,
        effect:          .damage(multiplier: 2.8)
    )
}
