// BattleLogPlaybackModel.swift
// V4-1 重設計：戰鬥播放背景模型（@Observable，持久於 AppState）
//
// 設計：
//   - 播放 Task 在背景持續執行，關閉 Sheet 不會中斷
//   - 每批播完後自動向 nextBatchProvider 取下一批，直到任務到期（provider 回傳 nil）
//   - 重新打開 Sheet 時讀取當前狀態，繼續從中斷點播放
//   - associatedTaskId 防止同一任務被重複啟動
//
// ATB 動畫策略：
//   - 全部使用手動步進（~20fps），避免 withAnimation 被 @Observable re-render 中斷
//   - 戰鬥時英雄與敵方 ATB 並行獨立填充，各自滿了各自攻擊
//   - 探索時只顯示英雄 ATB（藍綠色），敵方面板在 encounter 前隱藏

import Foundation
import SwiftUI

@Observable
final class BattleLogPlaybackModel {

    // MARK: - 外部讀取（UI 綁定）

    var currentBattleEvents:     [BattleEvent] = []
    var displayedCount:          Int    = 0
    var currentBattleInSession:  Int    = 0
    var heroATBProgress:         Double = 0
    var enemyATBProgress:        Double = 0
    var fromBattleIndex:         Int    = 0
    var taskTotalBattles:        Int    = 0
    var isActive:                Bool   = false
    var associatedTaskId:        UUID?  = nil
    /// 探索搜索期間為 true，供 BattleLogSheet 切換 ATB 條顏色（.teal）
    var isExploring:             Bool   = false
    /// encounter 事件後為 true，控制 BattleLogSheet 顯示敵方血條
    var isBattleActive:          Bool   = false

    // MARK: - 內部

    private var battleGroups:        [[BattleEvent]] = []
    private var playbackTask:         Task<Void, Never>? = nil
    private var nextBatchProvider:   (@MainActor (_ nextBattleIndex: Int) -> [BattleEvent]?)? = nil
    /// 最近一次 damage 事件的 chargeTime，供 kill shot 時敵方 ATB 比例填充
    private var lastEnemyChargeTime: Double = 1.5

    // MARK: - 公開方法

    /// 啟動播放。若已在播放相同任務則跳過（重開 Sheet 時不重啟）。
    @MainActor
    func start(events: [BattleEvent],
               fromBattleIndex: Int,
               taskTotalBattles: Int,
               taskId: UUID,
               nextBatchProvider: (@MainActor (_ nextBattleIndex: Int) -> [BattleEvent]?)? = nil) {
        if isActive && associatedTaskId == taskId { return }

        playbackTask?.cancel()
        playbackTask = nil

        self.fromBattleIndex        = fromBattleIndex
        self.taskTotalBattles       = taskTotalBattles
        self.associatedTaskId       = taskId
        self.nextBatchProvider      = nextBatchProvider
        self.battleGroups           = groupIntoBattles(events)
        self.currentBattleEvents    = []
        self.displayedCount         = 0
        self.currentBattleInSession = 0
        self.heroATBProgress        = 0
        self.enemyATBProgress       = 0
        self.isExploring            = false
        self.isBattleActive         = false
        self.isActive               = true

        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 600_000_000)
            await self.runPlayback()
        }
    }

    @MainActor
    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        nextBatchProvider = nil
        isExploring     = false
        isBattleActive  = false
        isActive        = false
    }

    // MARK: - 播放核心

    @MainActor
    private func runPlayback() async {
        var currentFromIndex = fromBattleIndex
        var groups = battleGroups

        repeat {
            var batchEnd = currentFromIndex

            for (sessionIdx, battleEvents) in groups.enumerated() {
                if Task.isCancelled { return }

                currentBattleInSession = sessionIdx
                fromBattleIndex        = currentFromIndex
                currentBattleEvents    = []
                displayedCount         = 0
                heroATBProgress        = 0
                enemyATBProgress       = 0
                isExploring            = false
                isBattleActive         = false
                lastEnemyChargeTime    = 1.5

                var i = 0
                while i < battleEvents.count {
                    if Task.isCancelled { return }
                    let event = battleEvents[i]

                    switch event.type {

                    // MARK: explore
                    case .explore:
                        if event.chargeTime > 0 {
                            // 搜索階段：手動步進填充（避免 withAnimation 被 re-render 中斷）
                            isExploring = true
                            currentBattleEvents.append(event)
                            displayedCount += 1

                            let startProgress = heroATBProgress
                            let target        = event.chargeTarget
                            let steps         = max(1, Int(event.chargeTime * 20)) // ~20 fps
                            let stepNs        = UInt64(event.chargeTime / Double(steps) * 1_000_000_000)

                            for step in 1...steps {
                                if Task.isCancelled { return }
                                heroATBProgress = startProgress + (target - startProgress) * Double(step) / Double(steps)
                                try? await Task.sleep(nanoseconds: stepNs)
                            }
                            if Task.isCancelled { return }

                            // 最終階段（chargeTarget == 1.0）才重置進度條
                            if event.chargeTarget >= 1.0 {
                                snapZero(hero: true)
                                isExploring = false
                            }
                        } else {
                            // 到達文字：立即顯示 + 0.5s 停頓
                            isExploring = false
                            currentBattleEvents.append(event)
                            displayedCount += 1
                            try? await Task.sleep(nanoseconds: 500_000_000)
                        }
                        i += 1

                    // MARK: encounter
                    case .encounter:
                        isBattleActive = true          // ← 此刻才顯示敵方血條
                        snapZero(hero: true, enemy: true)
                        currentBattleEvents.append(event)
                        displayedCount += 1
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        i += 1

                    // MARK: attack（+配對 damage）— 並行步進
                    case .attack:
                        let attackEvent = event
                        let heroTime    = attackEvent.chargeTime

                        if i + 1 < battleEvents.count && battleEvents[i + 1].type == .damage {
                            // ── 一般回合：英雄 & 敵方 ATB 同時獨立填充 ──
                            let damageEvent = battleEvents[i + 1]
                            let enemyTime   = damageEvent.chargeTime
                            lastEnemyChargeTime = enemyTime   // ← 記錄供 kill shot 使用

                            let total   = max(heroTime, enemyTime)
                            let steps   = max(1, Int(total * 20)) // ~20 fps
                            let stepDur = total / Double(steps)
                            let stepNs  = UInt64(stepDur * 1_000_000_000)

                            snapZero(hero: true, enemy: true)

                            var heroShown  = false
                            var enemyShown = false
                            var elapsed    = 0.0

                            for _ in 0..<steps {
                                if Task.isCancelled { return }
                                elapsed += stepDur
                                if !heroShown  { heroATBProgress  = min(1.0, elapsed / heroTime)  }
                                if !enemyShown { enemyATBProgress = min(1.0, elapsed / enemyTime) }
                                try? await Task.sleep(nanoseconds: stepNs)
                                if Task.isCancelled { return }
                                if !heroShown && heroATBProgress >= 1.0 {
                                    snapZero(hero: true)
                                    currentBattleEvents.append(attackEvent)
                                    displayedCount += 1
                                    heroShown = true
                                }
                                if !enemyShown && enemyATBProgress >= 1.0 {
                                    snapZero(enemy: true)
                                    currentBattleEvents.append(damageEvent)
                                    displayedCount += 1
                                    enemyShown = true
                                }
                                if heroShown && enemyShown { break }
                            }
                            i += 2   // attack + damage 一起消耗

                        } else {
                            // ── Kill shot：敵方即將死亡，兩條 bar 並行 ──
                            // 敵方填到 heroTime/lastEnemyChargeTime 比例後停下（英雄先出手）
                            let enemyFillRatio = lastEnemyChargeTime > 0
                                ? min(1.0, heroTime / lastEnemyChargeTime)
                                : 0.5

                            let steps  = max(1, Int(heroTime * 20))
                            let stepNs = UInt64(heroTime / Double(steps) * 1_000_000_000)

                            snapZero(hero: true, enemy: true)

                            for step in 1...steps {
                                if Task.isCancelled { return }
                                let t = Double(step) / Double(steps)
                                heroATBProgress  = t
                                enemyATBProgress = t * enemyFillRatio
                                try? await Task.sleep(nanoseconds: stepNs)
                            }
                            if Task.isCancelled { return }
                            snapZero(hero: true, enemy: true)
                            currentBattleEvents.append(attackEvent)
                            displayedCount += 1
                            i += 1
                        }

                    // MARK: damage（獨立出現時 fallback，正常應被 attack 消耗）
                    case .damage:
                        currentBattleEvents.append(event)
                        displayedCount += 1
                        i += 1

                    // MARK: victory
                    case .victory:
                        snapZero(hero: true, enemy: true)
                        currentBattleEvents.append(event)
                        displayedCount += 1
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        i += 1

                    // MARK: defeat
                    case .defeat:
                        snapZero(hero: true, enemy: true)
                        currentBattleEvents.append(event)
                        displayedCount += 1
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        i += 1

                    // MARK: heal — 手動步進（同 explore 策略）
                    case .heal:
                        isBattleActive = false   // 戰鬥結束，隱藏敵方血條
                        let steps  = max(1, Int(event.chargeTime * 20))
                        let stepNs = UInt64(event.chargeTime / Double(steps) * 1_000_000_000)
                        snapZero(hero: true)
                        for step in 1...steps {
                            if Task.isCancelled { return }
                            heroATBProgress = Double(step) / Double(steps)
                            try? await Task.sleep(nanoseconds: stepNs)
                        }
                        if Task.isCancelled { return }
                        snapZero(hero: true)
                        currentBattleEvents.append(event)
                        displayedCount += 1
                        i += 1
                    }
                }

                batchEnd = currentFromIndex + sessionIdx
            }

            // 向 provider 取下一批
            let nextIdx = batchEnd + 1
            if let provider = nextBatchProvider,
               let newEvents = provider(nextIdx),
               !newEvents.isEmpty {
                currentFromIndex = nextIdx
                groups = groupIntoBattles(newEvents)
            } else {
                break
            }

        } while !Task.isCancelled

        isActive = false
    }

    // MARK: - Helpers

    /// ATB 歸零時用 disablesAnimations 徹底關閉所有動畫層（含 view-level .animation modifier）
    @MainActor
    private func snapZero(hero: Bool = false, enemy: Bool = false) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            if hero  { heroATBProgress  = 0 }
            if enemy { enemyATBProgress = 0 }
        }
    }

    /// 以 chargeTime==0 的 .explore（到達事件）為每組起點分組
    /// chargeTime>0 的 .explore（搜索動作）屬於同一場，不切割
    private func groupIntoBattles(_ events: [BattleEvent]) -> [[BattleEvent]] {
        var result:  [[BattleEvent]] = []
        var current: [BattleEvent]   = []
        for event in events {
            if event.type == .explore && event.chargeTime == 0 && !current.isEmpty {
                result.append(current)
                current = []
            }
            current.append(event)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
