// HeroStats.swift
// 英雄戰力的計算結果 Value Type（不存 DB，每次現算）
// 供 HeroStatsService（Phase 2）使用，Phase 1 先定義型別

import Foundation

// MARK: - HeroStats

struct HeroStats {
    let totalATK: Int
    let totalDEF: Int
    let totalHP:  Int
    let totalAGI: Int   // 敏捷：ATB 填充速度
    let totalDEX: Int   // 靈巧：暴擊率

    init(totalATK: Int, totalDEF: Int, totalHP: Int, totalAGI: Int = 0, totalDEX: Int = 0) {
        self.totalATK = totalATK
        self.totalDEF = totalDEF
        self.totalHP  = totalHP
        self.totalAGI = totalAGI
        self.totalDEX = totalDEX
    }

    /// 戰力 = ATK × 2 + DEF × 1.5 + HP × 1 + AGI × 1.5 + DEX × 1.5
    var power: Int {
        totalATK * 2
        + Int(Double(totalDEF) * 1.5)
        + totalHP
        + Int(Double(totalAGI) * 1.5)
        + Int(Double(totalDEX) * 1.5)
    }

    /// 對指定地下城的預估勝率（供 AdventureViewModel 顯示）
    func winRate(recommendedPower: Int) -> Double {
        HeroStats.winRate(power: power, recommendedPower: recommendedPower)
    }

    /// 勝率公式（集中在此，DungeonSettlementEngine 也委派至此）
    /// clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (power / recommendedPower − 1)))
    static func winRate(power: Int, recommendedPower: Int) -> Double {
        guard recommendedPower > 0 else { return 0.5 }
        let ratio = Double(power) / Double(recommendedPower)
        let raw   = 0.50 + 0.40 * tanh(2.0 * (ratio - 1.0))
        return max(0.10, min(0.95, raw))
    }
}

// MARK: - V6-1 職業 & 技能加成

extension HeroStats {

    /// 套用職業基礎加成（永久，影響角色頁顯示數值與出征快照）
    func applying(classDef: ClassDef) -> HeroStats {
        HeroStats(
            totalATK: totalATK + classDef.baseATKBonus,
            totalDEF: totalDEF + classDef.baseDEFBonus,
            totalHP:  totalHP  + classDef.baseHPBonus,
            totalAGI: totalAGI + classDef.baseAGIBonus,
            totalDEX: totalDEX + classDef.baseDEXBonus
        )
    }

    /// 套用技能加成（出征建立時使用，加在 snapshotStats 上）
    func applying(skills: [SkillDef]) -> HeroStats {
        var atk = totalATK, def = totalDEF, hp = totalHP
        var agi = totalAGI, dex = totalDEX
        for skill in skills {
            for effect in skill.effects {
                switch effect {
                case .atkBonus(let v): atk += v
                case .defBonus(let v): def += v
                case .hpBonus(let v):  hp  += v
                case .agiBonus(let v): agi += v
                case .dexBonus(let v): dex += v
                }
            }
        }
        return HeroStats(totalATK: atk, totalDEF: def, totalHP: hp,
                         totalAGI: agi, totalDEX: dex)
    }
}
