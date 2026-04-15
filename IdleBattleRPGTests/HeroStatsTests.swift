// HeroStatsTests.swift
// 驗證 HeroStats.power 公式與 winRate 勝率公式

import XCTest
@testable import IdleBattleRPG

final class HeroStatsTests: XCTestCase {

    // MARK: - power 戰力公式：ATK×2 + DEF×1.5 + HP + AGI + DEX

    func test_power_baseFormula() {
        let stats = HeroStats(totalATK: 10, totalDEF: 10, totalHP: 10)
        // 10×2 + 10×1.5 + 10 = 20 + 15 + 10 = 45
        XCTAssertEqual(stats.power, 45)
    }

    func test_power_withAgiAndDex() {
        let stats = HeroStats(totalATK: 10, totalDEF: 10, totalHP: 10, totalAGI: 5, totalDEX: 3)
        // ATK×2=20, DEF×1.5=15, HP=10, AGI×1.5=7, DEX×1.5=4 → 56
        XCTAssertEqual(stats.power, 56)
    }

    func test_power_zeros() {
        let stats = HeroStats(totalATK: 0, totalDEF: 0, totalHP: 0)
        XCTAssertEqual(stats.power, 0)
    }

    func test_power_atkHeavy() {
        let stats = HeroStats(totalATK: 100, totalDEF: 0, totalHP: 0)
        XCTAssertEqual(stats.power, 200)
    }

    func test_power_defHeavy() {
        // DEF × 1.5 → 結果為整數（截斷）
        let stats = HeroStats(totalATK: 0, totalDEF: 7, totalHP: 0)
        // 7×1.5 = 10.5 → Int = 10
        XCTAssertEqual(stats.power, 10)
    }

    // MARK: - winRate 勝率公式
    // clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (power/recPower − 1)))

    func test_winRate_equalPower_isHalf() {
        // ratio = 1.0 → tanh(0) = 0 → 0.50 + 0 = 0.50
        let rate = HeroStats.winRate(power: 100, recommendedPower: 100)
        XCTAssertEqual(rate, 0.50, accuracy: 0.001)
    }

    func test_winRate_muchStronger_approachesUpperBound() {
        // 公式最大值 = 0.50 + 0.40×tanh(∞) → 0.90（tanh 飽和）
        // clamp 上限 0.95 永遠不會被觸發，實際上限趨近 0.90
        let rate = HeroStats.winRate(power: 10000, recommendedPower: 100)
        XCTAssertGreaterThan(rate, 0.89)
        XCTAssertLessThanOrEqual(rate, 0.95)
    }

    func test_winRate_muchWeaker_approachesLowerBound() {
        // 公式下限趨近 0.10（但不完全等於）
        let rate = HeroStats.winRate(power: 1, recommendedPower: 1000)
        XCTAssertGreaterThanOrEqual(rate, 0.10)
        XCTAssertLessThan(rate, 0.15)
    }

    func test_winRate_zeroPower_nearFloor() {
        // ratio=0 → tanh(-2) ≈ -0.964 → 0.50 + 0.40×(-0.964) ≈ 0.114
        let rate = HeroStats.winRate(power: 0, recommendedPower: 100)
        XCTAssertGreaterThanOrEqual(rate, 0.10)
        XCTAssertLessThan(rate, 0.15)
    }

    func test_winRate_zeroRecommendedPower_returnsFallback() {
        // guard recommendedPower > 0 → return 0.5
        let rate = HeroStats.winRate(power: 100, recommendedPower: 0)
        XCTAssertEqual(rate, 0.50, accuracy: 0.001)
    }

    func test_winRate_slightlyStronger_above50() {
        // ratio = 1.2 → tanh(0.4) ≈ 0.379 → 0.50 + 0.40×0.379 ≈ 0.652
        let rate = HeroStats.winRate(power: 120, recommendedPower: 100)
        XCTAssertGreaterThan(rate, 0.50)
        XCTAssertLessThan(rate, 0.95)
    }

    func test_winRate_slightlyWeaker_below50() {
        let rate = HeroStats.winRate(power: 80, recommendedPower: 100)
        XCTAssertLessThan(rate, 0.50)
        XCTAssertGreaterThan(rate, 0.10)
    }

    func test_winRate_alwaysInValidRange() {
        let powers = [0, 1, 10, 50, 100, 200, 500, 1000, 9999]
        for p in powers {
            let rate = HeroStats.winRate(power: p, recommendedPower: 100)
            XCTAssertGreaterThanOrEqual(rate, 0.10, "power=\(p)")
            XCTAssertLessThanOrEqual(rate, 0.95, "power=\(p)")
        }
    }

    func test_winRate_isMonotoneIncreasing() {
        // 戰力越高，勝率不降
        var prev = 0.0
        for p in stride(from: 0, through: 500, by: 10) {
            let rate = HeroStats.winRate(power: p, recommendedPower: 100)
            XCTAssertGreaterThanOrEqual(rate, prev, "power=\(p) 勝率不應低於 power=\(p-10)")
            prev = rate
        }
    }

    // MARK: - instance winRate（委派 static）

    func test_instanceWinRate_matchesStatic() {
        let stats = HeroStats(totalATK: 20, totalDEF: 10, totalHP: 30)
        let instanceRate = stats.winRate(recommendedPower: 80)
        let staticRate   = HeroStats.winRate(power: stats.power, recommendedPower: 80)
        XCTAssertEqual(instanceRate, staticRate, accuracy: 0.0001)
    }
}
