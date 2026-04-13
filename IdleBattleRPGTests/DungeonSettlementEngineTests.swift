// DungeonSettlementEngineTests.swift
// 驗證 DungeonSettlementEngine 確定性結算邏輯（V1 & V2-1 兩條路徑）

import XCTest
@testable import IdleBattleRPG

final class DungeonSettlementEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeTask(
        id: UUID = UUID(),
        startedAt: Date = Date(timeIntervalSinceReferenceDate: 700_000_000),
        durationSecs: Double = 3600,
        snapshotPower: Int = 100,
        forcedBattles: Int? = nil
    ) -> TaskModel {
        TaskModel(
            id: id,
            kind: .dungeon,
            actorKey: "player",
            definitionKey: "wildland_border",
            startedAt: startedAt,
            endsAt: startedAt.addingTimeInterval(durationSecs),
            forcedBattles: forcedBattles,
            snapshotPower: snapshotPower
        )
    }

    private var wildlandArea: DungeonAreaDef { DungeonAreaDef.all[0] }
    private var wildlandFloor1: DungeonFloorDef {
        DungeonRegionDef.wildland.floors[0]  // floor index 1
    }
    private var wildlandBossFloor: DungeonFloorDef {
        DungeonRegionDef.wildland.floors[3]  // floor index 4, isBossFloor = true
    }

    // MARK: - 確定性：相同 Task → 相同結果（V1）

    func test_v1_sameTask_sameResult() {
        let task    = makeTask()
        let result1 = DungeonSettlementEngine.settle(task: task, area: wildlandArea)
        let result2 = DungeonSettlementEngine.settle(task: task, area: wildlandArea)

        XCTAssertEqual(result1.gold,            result2.gold)
        XCTAssertEqual(result1.battlesWon,      result2.battlesWon)
        XCTAssertEqual(result1.battlesLost,     result2.battlesLost)
        XCTAssertEqual(result1.hide,            result2.hide)
        XCTAssertEqual(result1.crystalShard,    result2.crystalShard)
        XCTAssertEqual(result1.ancientFragment, result2.ancientFragment)
    }

    // MARK: - 確定性：相同 Task → 相同結果（V2-1）

    func test_v21_sameTask_sameResult() {
        let task    = makeTask(snapshotPower: 80)
        let result1 = DungeonSettlementEngine.settle(task: task, floor: wildlandFloor1)
        let result2 = DungeonSettlementEngine.settle(task: task, floor: wildlandFloor1)

        XCTAssertEqual(result1.gold,        result2.gold)
        XCTAssertEqual(result1.battlesWon,  result2.battlesWon)
        XCTAssertEqual(result1.battlesLost, result2.battlesLost)
        XCTAssertEqual(result1.materials,   result2.materials)
    }

    // MARK: - 不同 Task ID → 不同結果（幾乎必然）

    func test_v1_differentTaskId_differentResult() {
        let task1 = makeTask(id: UUID())
        let task2 = makeTask(id: UUID())
        let r1    = DungeonSettlementEngine.settle(task: task1, area: wildlandArea)
        let r2    = DungeonSettlementEngine.settle(task: task2, area: wildlandArea)

        // gold 幾乎不可能完全相同（若相同，其他欄位應不同）
        let identical = (r1.gold == r2.gold &&
                         r1.battlesWon == r2.battlesWon &&
                         r1.battlesLost == r2.battlesLost)
        XCTAssertFalse(identical, "兩個不同 UUID 的 Task 不應產出完全相同的結算結果")
    }

    // MARK: - battlesWon + battlesLost == totalBattles

    func test_v1_battleCount_sumsCorrectly() {
        let durationSecs: Double = 3600   // 1小時
        let task   = makeTask(durationSecs: durationSecs, snapshotPower: 100)
        let result = DungeonSettlementEngine.settle(task: task, area: wildlandArea)

        let expectedBattles = max(1, Int(durationSecs / 60))
        XCTAssertEqual(result.battlesWon + result.battlesLost, expectedBattles)
    }

    func test_v21_battleCount_sumsCorrectly() {
        let durationSecs: Double = 1800  // 30 分鐘
        let task   = makeTask(durationSecs: durationSecs)
        let result = DungeonSettlementEngine.settle(task: task, floor: wildlandFloor1)

        let expectedBattles = max(1, Int(durationSecs / 60))
        XCTAssertEqual(result.battlesWon + result.battlesLost, expectedBattles)
    }

    func test_forcedBattles_overridesDuration() {
        let task   = makeTask(durationSecs: 3600, forcedBattles: 5)
        let result = DungeonSettlementEngine.settle(task: task, area: wildlandArea)

        XCTAssertEqual(result.battlesWon + result.battlesLost, 5)
    }

    // MARK: - 首次出征保底（forcedBattles != nil && gold == 0 → 給最低金幣）

    func test_v1_firstExpeditionFallback_neverZeroGold() {
        // 用極低戰力 + forcedBattles，多跑幾個 seed 確認至少有金幣
        var foundFallbackApplied = false
        for i in 0..<50 {
            let id   = UUID()
            let base = Date(timeIntervalSinceReferenceDate: Double(i) * 1000 + 500_000_000)
            let task = makeTask(id: id, startedAt: base,
                                durationSecs: 900, snapshotPower: 1, forcedBattles: 5)
            let result = DungeonSettlementEngine.settle(task: task, area: wildlandArea)
            XCTAssertGreaterThan(result.gold, 0, "首次出征 gold 不應為 0（保底）")
            if result.battlesWon == 0 { foundFallbackApplied = true }
        }
        // 在 50 個極低戰力 seed 中，應至少有幾次全敗並觸發保底
        XCTAssertTrue(foundFallbackApplied, "應有全敗情境以驗證保底邏輯")
    }

    // MARK: - 高戰力 → 高勝率（統計驗證）

    func test_highPower_winsMoreThanHalf() {
        // snapshotPower = 10× recommendedPower → winRate ≈ 0.95
        var totalWon = 0
        var totalBattles = 0
        for i in 0..<20 {
            let id   = UUID()
            let base = Date(timeIntervalSinceReferenceDate: Double(i) * 999 + 600_000_000)
            let task = makeTask(id: id, startedAt: base, durationSecs: 3600, snapshotPower: 9999)
            let r    = DungeonSettlementEngine.settle(task: task, area: wildlandArea)
            totalWon     += r.battlesWon
            totalBattles += r.battlesWon + r.battlesLost
        }
        let winRatio = Double(totalWon) / Double(totalBattles)
        XCTAssertGreaterThan(winRatio, 0.80, "超高戰力應有極高勝率（統計 \(totalBattles) 場）")
    }

    func test_zeroPower_winsLessThanHalf() {
        var totalWon = 0
        var totalBattles = 0
        for i in 0..<20 {
            let id   = UUID()
            let base = Date(timeIntervalSinceReferenceDate: Double(i) * 997 + 700_000_000)
            let task = makeTask(id: id, startedAt: base, durationSecs: 3600, snapshotPower: 0)
            let r    = DungeonSettlementEngine.settle(task: task, area: wildlandArea)
            totalWon     += r.battlesWon
            totalBattles += r.battlesWon + r.battlesLost
        }
        let winRatio = Double(totalWon) / Double(totalBattles)
        XCTAssertLessThan(winRatio, 0.20, "零戰力應有極低勝率（統計 \(totalBattles) 場）")
    }

    // MARK: - 金幣永遠非負

    func test_v1_gold_alwaysNonNegative() {
        for i in 0..<30 {
            let task = makeTask(id: UUID(),
                                startedAt: Date(timeIntervalSinceReferenceDate: Double(i) * 1111),
                                snapshotPower: 0)
            let r = DungeonSettlementEngine.settle(task: task, area: wildlandArea)
            XCTAssertGreaterThanOrEqual(r.gold, 0)
        }
    }

    func test_v21_gold_alwaysNonNegative() {
        for i in 0..<30 {
            let task = makeTask(id: UUID(),
                                startedAt: Date(timeIntervalSinceReferenceDate: Double(i) * 777),
                                snapshotPower: 0)
            let r = DungeonSettlementEngine.settle(task: task, floor: wildlandFloor1)
            XCTAssertGreaterThanOrEqual(r.gold, 0)
        }
    }

    // MARK: - V2-1 Boss 樓層：勝場 >= 1 應有武器掉落

    func test_v21_bossFloor_hasBossWeaponWhenWon() {
        // 高戰力確保大概率有勝場
        var foundWinWithDrop = false
        for i in 0..<20 {
            let task = makeTask(id: UUID(),
                                startedAt: Date(timeIntervalSinceReferenceDate: Double(i) * 888 + 800_000_000),
                                durationSecs: 3600,
                                snapshotPower: 9999)
            let r = DungeonSettlementEngine.settle(task: task, floor: wildlandBossFloor)
            if r.battlesWon >= 1 {
                XCTAssertNotNil(r.rolledBossWeapon, "Boss 層有勝場時應有武器掉落")
                foundWinWithDrop = true
                break
            }
        }
        XCTAssertTrue(foundWinWithDrop, "20 次高戰力 Boss 戰應至少有一次勝利含武器掉落")
    }

    // MARK: - V2-1 EXP 計算

    func test_v21_exp_nonNegative() {
        let task = makeTask(snapshotPower: 50)
        let r    = DungeonSettlementEngine.settle(task: task, floor: wildlandFloor1)
        XCTAssertGreaterThanOrEqual(r.exp, 0)
    }

    func test_v21_exp_increasesWithWins() {
        // 相同 task，高戰力應比低戰力多 EXP
        let taskHigh = makeTask(id: UUID(),
                                startedAt: Date(timeIntervalSinceReferenceDate: 900_000_001),
                                snapshotPower: 9999)
        let taskLow  = makeTask(id: UUID(),
                                startedAt: Date(timeIntervalSinceReferenceDate: 900_000_002),
                                snapshotPower: 0)
        let rHigh = DungeonSettlementEngine.settle(task: taskHigh, floor: wildlandFloor1)
        let rLow  = DungeonSettlementEngine.settle(task: taskLow,  floor: wildlandFloor1)

        XCTAssertGreaterThanOrEqual(rHigh.exp, rLow.exp,
                                    "高戰力 EXP 應 ≥ 低戰力（多勝場）")
    }
}
