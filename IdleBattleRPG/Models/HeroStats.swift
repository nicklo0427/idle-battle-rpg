// HeroStats.swift
// 英雄戰力的計算結果 Value Type（不存 DB，每次現算）
// 供 HeroStatsService（Phase 2）使用，Phase 1 先定義型別

import Foundation

struct HeroStats {
    let totalATK: Int
    let totalDEF: Int
    let totalHP: Int

    /// 戰力 = ATK × 2 + DEF × 1.5 + HP × 1
    var power: Int {
        totalATK * 2 + Int(Double(totalDEF) * 1.5) + totalHP
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
