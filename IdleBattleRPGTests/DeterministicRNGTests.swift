// DeterministicRNGTests.swift
// 驗證 DeterministicRNG (LCG) 的確定性、均勻性與邊界行為

import XCTest
@testable import IdleBattleRPG

final class DeterministicRNGTests: XCTestCase {

    // MARK: - 確定性：相同 seed 產出相同序列

    func test_sameSeed_producesSameSequence() {
        var rng1 = DeterministicRNG(seed: 12345)
        var rng2 = DeterministicRNG(seed: 12345)

        for _ in 0..<20 {
            XCTAssertEqual(rng1.nextUInt64(), rng2.nextUInt64())
        }
    }

    func test_differentSeed_producesDifferentSequence() {
        var rng1 = DeterministicRNG(seed: 111)
        var rng2 = DeterministicRNG(seed: 222)

        // 兩個 seed 的第一個值幾乎必然不同
        XCTAssertNotEqual(rng1.nextUInt64(), rng2.nextUInt64())
    }

    // MARK: - seed = 0 防護

    func test_zeroSeed_doesNotProduceAllZeros() {
        var rng = DeterministicRNG(seed: 0)
        let val = rng.nextUInt64()
        // seed=0 應被替換為非零常數，確保序列不全為 0
        XCTAssertNotEqual(val, 0)
    }

    // MARK: - nextDouble

    func test_nextDouble_alwaysInRange() {
        var rng = DeterministicRNG(seed: 9999)
        for _ in 0..<1000 {
            let d = rng.nextDouble()
            XCTAssertGreaterThanOrEqual(d, 0.0)
            XCTAssertLessThan(d, 1.0)
        }
    }

    func test_nextDouble_notAllSame() {
        var rng = DeterministicRNG(seed: 42)
        let values = (0..<100).map { _ in rng.nextDouble() }
        let unique = Set(values)
        XCTAssertGreaterThan(unique.count, 80, "100 次 nextDouble() 應產出至少 80 個不同值")
    }

    // MARK: - nextInt(in:)

    func test_nextInt_alwaysInClosedRange() {
        var rng = DeterministicRNG(seed: 7777)
        let range = 3...8
        for _ in 0..<500 {
            let v = rng.nextInt(in: range)
            XCTAssertGreaterThanOrEqual(v, range.lowerBound)
            XCTAssertLessThanOrEqual(v, range.upperBound)
        }
    }

    func test_nextInt_singleValueRange_alwaysReturnsLowerBound() {
        var rng = DeterministicRNG(seed: 1)
        for _ in 0..<20 {
            XCTAssertEqual(rng.nextInt(in: 5...5), 5)
        }
    }

    func test_nextInt_coversAllValuesInSmallRange() {
        var rng = DeterministicRNG(seed: 314159)
        var seen = Set<Int>()
        for _ in 0..<2000 {
            seen.insert(rng.nextInt(in: 1...6))
        }
        XCTAssertEqual(seen, Set(1...6), "2000 次應涵蓋 1~6 全部數值")
    }

    // MARK: - 序列狀態不共享

    func test_independentInstances_doNotShareState() {
        // rngA 推進 3 步的第 3 個值，應等於 fresh rng 推進 3 步的第 3 個值
        var rngA = DeterministicRNG(seed: 55)
        _ = rngA.nextUInt64()
        _ = rngA.nextUInt64()
        let a3 = rngA.nextUInt64()

        var fresh = DeterministicRNG(seed: 55)
        _ = fresh.nextUInt64()
        _ = fresh.nextUInt64()
        let f3 = fresh.nextUInt64()

        XCTAssertEqual(a3, f3, "相同 seed 的兩個獨立實例，第三步應相同")

        // rngB 只推進一步，值應與 rngA 的第三步不同（已分岐）
        var rngB = DeterministicRNG(seed: 55)
        let b1 = rngB.nextUInt64()
        XCTAssertNotEqual(b1, a3, "第 1 步與第 3 步應不同")
    }
}
