// DungeonBattleSheet.swift
// 地下城即時戰鬥控制器（V6-3 T03）
//
// 責任：
//   - 找到 TaskModel 對應的 DungeonFloorDef
//   - 以 BattleLogGenerator.generate(maxBattles:1) 逐場產生事件
//   - 用本地 BattleLogPlaybackModel 即時播放（不干擾 AppState 的 AFK 全局 playback）
//   - 每場結束後透過 onBattleEnded callback 累計勝 / 敗，自動啟動下一場
//   - 全部場次結束後：
//       1. DungeonSettlementEngine.settle() 計算獎勵（seed 與即時戰鬥完全相同）
//       2. 填入 task.result* 欄位
//       3. 呼叫 DungeonProgressionService 標記首通
//       4. task.battlePending = false，context.save()
//   - finishedPanel：顯示勝敗 + 摘要獎勵，「收下獎勵」清除戰鬥狀態並入帳

import SwiftUI
import SwiftData

struct DungeonBattleSheet: View {

    let task:     TaskModel
    let appState: AppState

    @Environment(\.modelContext) private var context

    // MARK: - 狀態

    /// 本地播放模型（每個 DungeonBattleSheet 獨立持有，不影響 AFK 全局播放）
    @State private var playbackModel      = BattleLogPlaybackModel()
    @State private var battlesWon         = 0
    @State private var battlesLost        = 0
    @State private var currentBattleIndex = 0
    @State private var isFinished         = false
    @State private var finalResult:       FloorDungeonResult? = nil
    /// 本次首通的樓層（nil = 非首通）
    @State private var firstClearFloor:   DungeonFloorDef?    = nil

    // MARK: - 靜態計算

    private var floor: DungeonFloorDef? {
        DungeonRegionDef.all
            .flatMap { $0.floors }
            .first { $0.key == task.definitionKey }
    }

    private var totalBattles: Int {
        let duration = task.endsAt.timeIntervalSince(task.startedAt)
        return task.forcedBattles ?? max(1, Int(duration / 60))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let floor {
                BattleLogSheet(
                    model:      playbackModel,
                    title:      floor.name,
                    enemyLabel: floor.bossName ?? (floor.commonEnemyNames.first ?? "怪物")
                )
                .safeAreaInset(edge: .bottom) {
                    if isFinished { finishedPanel }
                }
                .onAppear {
                    // 防止 Sheet 重新出現時重複啟動（或已結束後誤啟）
                    guard !isFinished, !playbackModel.isActive else { return }
                    startNextBattle()
                }
            } else {
                // 防禦性 fallback：battlePending 任務理論上必有對應 FloorDef
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.orange)
                    Text("找不到地下城資料")
                        .foregroundStyle(.secondary)
                    Button("關閉") { appState.clearDungeonBattle() }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
    }

    // MARK: - 逐場戰鬥控制

    /// 啟動下一場戰鬥。若已達總場次則呼叫 finalizeBattle()。
    private func startNextBattle() {
        guard let floor else { return }
        guard currentBattleIndex < totalBattles else {
            finalizeBattle()
            return
        }

        // 只產生 1 場事件，結束後透過 callback 再呼叫 startNextBattle()
        let events = BattleLogGenerator.generate(
            task:            task,
            floor:           floor,
            fromBattleIndex: currentBattleIndex,
            maxBattles:      1
        )

        // T09：傳入裝備技能定義，啟用 CD 面板
        let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

        playbackModel.start(
            events:           events,
            fromBattleIndex:  currentBattleIndex,
            taskTotalBattles: 0,               // T12：不顯示場次計數（battleLabel 回傳 nil）
            taskId:           task.id,
            activeSkills:     activeSkills,
            onBattleEnded:    { won in
                // 在 @MainActor 上非同步執行，確保 runPlayback 已完成（isActive = false）
                Task { @MainActor in
                    if won { battlesWon  += 1 }
                    else   { battlesLost += 1 }
                    currentBattleIndex += 1
                    startNextBattle()
                }
            }
        )
    }

    // MARK: - 全部場次結束後結算

    /// 計算獎勵、寫入 task.result*、標記首通、清除 battlePending。
    private func finalizeBattle() {
        guard let floor else { return }

        // 用確定性引擎結算（combatRng seed 與 BattleLogGenerator 完全相同 → 勝負一致）
        let result = DungeonSettlementEngine.settle(task: task, floor: floor)
        finalResult = result

        // ── 寫入 result* 欄位 ────────────────────────────────────────────
        task.resultGold        = result.gold
        task.resultBattlesWon  = result.battlesWon
        task.resultBattlesLost = result.battlesLost
        task.resultExp         = result.exp
        for (material, amount) in result.materials {
            task.setResult(amount, of: material)
        }
        if let bossWeapon = result.rolledBossWeapon {
            task.resultCraftedEquipKey = bossWeapon.equipKey
            task.resultRolledAtk       = bossWeapon.atk
        }

        // ── 首通 / 地下城推進標記（原 SettlementService.markDungeonProgression）──
        let svc        = appState.progressionService
        let wasCleared = svc.isFloorCleared(
            regionKey:  floor.regionKey,
            floorIndex: floor.floorIndex
        )
        svc.markFloorCleared(
            regionKey:  floor.regionKey,
            floorIndex: floor.floorIndex
        )
        if !wasCleared {
            task.resultFirstClearedFloorKey = floor.key
            firstClearFloor = floor   // 供 finishedPanel 顯示解鎖通知
        }

        // ── 清除 battlePending，持久化 ──────────────────────────────────
        task.battlePending = false
        try? context.save()
        isFinished = true
    }

    // MARK: - 結束面板

    @ViewBuilder
    private var finishedPanel: some View {
        VStack(spacing: 10) {

            // 勝敗標題
            Label(
                "戰鬥結束：\(battlesWon) 勝 \(battlesLost) 敗",
                systemImage: battlesWon > 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .fontWeight(.semibold)
            .foregroundStyle(battlesWon > 0 ? Color.green : Color.red)

            // 核心獎勵摘要
            if let result = finalResult {
                HStack(spacing: 14) {
                    if result.gold > 0 {
                        Label("\(result.gold) 金", systemImage: "coins")
                            .foregroundStyle(.yellow)
                    }
                    if result.exp > 0 {
                        Label("EXP +\(result.exp)", systemImage: "sparkles")
                            .foregroundStyle(.purple)
                    }
                    if let weapon = result.rolledBossWeapon,
                       let def   = EquipmentDef.find(key: weapon.equipKey) {
                        Label("✦ \(def.name)", systemImage: "figure.fencing")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.subheadline)
            }

            // 首通解鎖通知
            if let cleared = firstClearFloor {
                Label("首次通關：\(cleared.name)", systemImage: "lock.open.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }

            // 收下按鈕：清除戰鬥狀態 + 入帳所有獎勵
            Button {
                appState.clearDungeonBattle()
                appState.claimAllCompleted()
            } label: {
                Label("收下獎勵", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 16)
        }
        .padding(.top, 14)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let appState = AppState(context: container.mainContext)

    // 建立一個 battlePending 地下城任務（荒野邊境 F1）
    let task = TaskModel(
        kind:          .dungeon,
        actorKey:      "player",
        definitionKey: "wildland_floor_1",
        startedAt:     Date().addingTimeInterval(-300),
        endsAt:        Date().addingTimeInterval(-1),
        snapshotPower: 80,
        snapshotAgi:   5,
        snapshotDex:   3,
        status:        .completed
    )
    task.battlePending = true
    container.mainContext.insert(task)

    return DungeonBattleSheet(task: task, appState: appState)
        .modelContainer(container)
}
