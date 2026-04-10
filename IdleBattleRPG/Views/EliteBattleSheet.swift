// EliteBattleSheet.swift
// V4-2 菁英戰鬥 Sheet
//
// 職責：
//   1. Sheet 開啟時立即呼叫 EliteBattleEngine.simulate() 計算戰鬥結果
//   2. 勝利時：授予金幣 + 素材、呼叫 progressionService.markEliteCleared()
//   3. 持有本地 BattleLogPlaybackModel（不干擾 AFK 的全局 playback）
//   4. 將事件序列傳入 playback model 啟動播放
//   5. 以 BattleLogSheet 呈現播放畫面 + 勝敗結果面板

import SwiftUI
import SwiftData

struct EliteBattleSheet: View {

    let elite:           EliteDef
    let appState:        AppState
    /// 勝利且獎勵入帳後呼叫，供 FloorDetailSheet 刷新菁英狀態
    var onEliteDefeated: (() -> Void)? = nil

    @Environment(\.modelContext) private var context

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]

    @State private var playbackModel = BattleLogPlaybackModel()
    @State private var battleResult:  EliteBattleResult? = nil
    @State private var rewardGranted  = false

    // MARK: - Computed

    private var player:    PlayerStateModel?       { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    // MARK: - Body

    var body: some View {
        BattleLogSheet(
            model:       playbackModel,
            title:       elite.name,
            enemyLabel:  elite.name,
            eliteResult: battleResult?.outcome,
            onRetry:     rewardGranted ? nil : { runBattle() }
        )
        .onAppear { runBattle() }
    }

    // MARK: - 核心邏輯

    private func runBattle() {
        // 每次挑戰用當前時間產生不同 seed，體驗上每次稍有差異
        let seed  = EliteBattleEngine.makeSeed(eliteKey: elite.key)
        let stats = HeroStatsService.fetchAndCompute(context: context)

        let result = EliteBattleEngine.simulate(
            elite:     elite,
            heroPower: stats.power,
            heroAgi:   stats.totalAGI,
            heroDex:   stats.totalDEX,
            seed:      seed
        )

        battleResult = result

        // 啟動播放（本地 model，不干擾 AFK）
        playbackModel.start(
            events:          result.events,
            fromBattleIndex: 0,
            taskTotalBattles: 0,   // 0 = 不顯示「第 N 場」標籤
            taskId:          UUID()
        )

        // 勝利：授予獎勵（只做一次）
        if result.won && !rewardGranted {
            grantReward(result: result)
        }
    }

    private func grantReward(result: EliteBattleResult) {
        guard let player, let inventory else { return }

        player.gold += result.elite.reward.gold
        inventory.add(result.elite.reward.materialCount,
                      of: result.elite.reward.material)

        appState.progressionService.markEliteCleared(
            regionKey:  result.elite.regionKey,
            floorIndex: result.elite.floorIndex
        )

        try? context.save()

        rewardGranted = true
        onEliteDefeated?()
    }
}
