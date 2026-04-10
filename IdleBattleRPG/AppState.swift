// AppState.swift
// 全域協調層
//
// 責任（嚴格限縮）：
//   1. 持有 SettlementService + TaskClaimService（服務注入點）
//   2. scanAndSettle() — 觸發掃描，若有完成任務則開啟結算 Sheet
//   3. claimAllCompleted() — 入帳獎勵、刪除任務、關閉 Sheet
//   4. dismissSettlement() — 僅關閉 Sheet（edge case 用）
//   5. shouldShowSettlement + lastSettledCount — 驅動 UI
//   6. tick — 每秒更新一次，供 View 層驅動即時倒數顯示
//      同時在 tick 時自動呼叫 scanAndSettle()，補抓前台到期任務
//   7. startForegroundTimer() / stopForegroundTimer() — 由 ContentView 管理生命週期
//   8. progressionService — 公開供 ViewModel 查詢地下城推進狀態（V2-1 Ticket 03）
//   9. enhancementService — 公開供 ViewModel 執行強化 / 拆解操作（V2-2 Ticket 03）
//
// 注意：AppState 本身不存任何遊戲狀態（金幣、素材、戰力等），
//       這些資料從 SwiftData 即時查詢。

import Foundation
import SwiftData

@Observable
final class AppState {

    // MARK: - ModelContext

    private let modelContext: ModelContext

    // MARK: - Services

    private let settlementService: SettlementService
    private let claimService: TaskClaimService
    /// 地下城推進狀態查詢服務（V2-1 Ticket 03）。
    /// 公開讓 ViewModel 直接呼叫 isRegionUnlocked / isFloorCleared 等方法。
    let progressionService: DungeonProgressionService

    /// 裝備強化 / 拆解服務（V2-2 Ticket 03）。
    /// 公開讓 ViewModel 呼叫 enhance / disassemble。
    let enhancementService: EnhancementService

    /// NPC 效率升級服務（V2-3 Ticket 03）。
    /// 公開讓 ViewModel 呼叫 upgrade / nextUpgradeCost。
    let npcUpgradeService: NpcUpgradeService

    // MARK: - 播放模型（背景持續播放，關閉 Sheet 不中斷）

    /// 地下城戰鬥播放（全局共用一個，同時只有一個地下城任務）
    let battleLogPlayback = BattleLogPlaybackModel()

    // MARK: - UI 狀態

    /// 是否顯示結算 Sheet
    private(set) var shouldShowSettlement: Bool = false

    /// 最近一次 scanAndSettle() 結算的筆數（供 SettlementSheet 顯示）
    private(set) var lastSettledCount: Int = 0

    /// 每秒更新一次，供 View 層讀取以驅動即時倒數
    /// View 讀取此屬性即訂閱更新，AppState 為 @Observable 故自動 re-render
    private(set) var tick: Date = .now

    /// 輕量 Toast 訊息（非阻擋，2.5 秒後自動清除）
    private(set) var toastMessage: String?

    // MARK: - Timer

    private var timer: Timer?

    // MARK: - Init

    init(context: ModelContext) {
        self.modelContext        = context
        self.settlementService   = SettlementService(context: context)
        self.claimService        = TaskClaimService(context: context)
        self.progressionService  = DungeonProgressionService(context: context)
        self.enhancementService  = EnhancementService(context: context)
        self.npcUpgradeService   = NpcUpgradeService(context: context)
    }

    // MARK: - Timer 生命週期（由 ContentView 管理）

    /// 啟動前台 1 秒 ticker。每秒：更新 tick + 自動掃描到期任務。
    /// 呼叫時機：app 進入前景（.active）。
    func startForegroundTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tick = .now
            self.scanAndSettle()
            self.updateHighestPower()
        }
    }

    /// 停止前台 ticker。
    /// 呼叫時機：app 進入背景（.background / .inactive）。
    func stopForegroundTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 公開入口

    /// 掃描到期任務並填入結果、標記 completed。
    /// 若有任務完成，開啟結算 Sheet，並顯示輕量 Toast。
    /// 呼叫時機：app 啟動、scenePhase → .active、前台 Timer tick。
    func scanAndSettle() {
        let settled = settlementService.scanAndSettle()
        guard !settled.isEmpty else { return }
        lastSettledCount     = settled.count
        shouldShowSettlement = true
        showToast("\(settled.count) 筆任務完成，請收下獎勵")
    }

    /// 顯示輕量 Toast（2.5 秒後自動清除）
    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.toastMessage == message else { return }
            self.toastMessage = nil
        }
    }

    /// 收下所有已完成任務：入帳獎勵 → 刪除任務 → 關閉 Sheet。
    /// 呼叫時機：玩家點「收下」按鈕，或拖曳關閉 Sheet。
    func claimAllCompleted() {
        claimService.claimAllCompleted()
        shouldShowSettlement = false
    }

    /// 僅關閉 Sheet，不觸發 claim（edge case 備用）
    func dismissSettlement() {
        shouldShowSettlement = false
    }

    // MARK: - Private

    /// 每秒比對當前戰力，若超過歷史最高則更新。
    private func updateHighestPower() {
        let stats  = HeroStatsService.fetchAndCompute(context: modelContext)
        let descriptor = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? modelContext.fetch(descriptor))?.first else { return }
        if stats.power > player.highestPowerReached {
            player.highestPowerReached = stats.power
            try? modelContext.save()
        }
    }
}
