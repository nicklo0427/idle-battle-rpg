# V6-3 Ticket 03：DungeonBattleSheet（多場即時戰鬥控制器）

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T01、T02、T04

**修改檔案：**
- 新建 `IdleBattleRPG/Views/DungeonBattleSheet.swift`
- `IdleBattleRPG/Services/DungeonSettlementEngine.swift`（新增獎勵計算純函式）

---

## 說明

模仿 `EliteBattleSheet` 架構，但處理 AFK 出征後的多場連續戰鬥：

1. Sheet 開啟 → 立即開始第一場
2. 每場結束 → 自動串接下一場（透過 T04 新增的 `onBattleEnded` callback）
3. 全部場次完成 → 計算獎勵、填入 TaskModel result*、顯示收下面板

---

## 新建 DungeonBattleSheet.swift

```swift
// IdleBattleRPG/Views/DungeonBattleSheet.swift

import SwiftUI
import SwiftData

struct DungeonBattleSheet: View {

    let task:     TaskModel
    let appState: AppState

    @Environment(\.modelContext) private var context
    @Query private var players: [PlayerStateModel]

    @State private var playbackModel      = BattleLogPlaybackModel()
    @State private var battlesWon         = 0
    @State private var battlesLost        = 0
    @State private var currentBattleIndex = 0
    @State private var isFinished         = false
    @State private var rewardGold         = 0
    @State private var rewardGranted      = false

    // MARK: - Computed

    private var player: PlayerStateModel? { players.first }

    private var floor: DungeonFloorDef? {
        DungeonRegionDef.findFloor(key: task.definitionKey)
    }

    private var totalBattles: Int {
        let duration = task.endsAt.timeIntervalSince(task.startedAt)
        return task.forcedBattles ?? max(1, Int(duration / 60))
    }

    private var floorName: String {
        floor?.name ?? "地下城"
    }

    private var enemyName: String {
        floor?.enemyName ?? "敵人"
    }

    // MARK: - Body

    var body: some View {
        BattleLogSheet(
            model:      playbackModel,
            title:      floorName,
            enemyLabel: enemyName
        )
        .safeAreaInset(edge: .bottom) {
            if isFinished {
                finishedPanel
            }
        }
        .onAppear {
            startNextBattle()
        }
    }

    // MARK: - 戰鬥控制

    private func startNextBattle() {
        guard let floor else { finalizeBattle(); return }
        guard currentBattleIndex < totalBattles else {
            finalizeBattle()
            return
        }

        let events = BattleLogGenerator.generate(
            task:            task,
            floor:           floor,
            fromBattleIndex: currentBattleIndex,
            maxBattles:      1
        )

        playbackModel.start(
            events:           events,
            fromBattleIndex:  currentBattleIndex,
            taskTotalBattles: totalBattles,
            taskId:           task.id,
            onBattleEnded: { won in
                Task { @MainActor in
                    if won { battlesWon += 1 } else { battlesLost += 1 }
                    currentBattleIndex += 1
                    startNextBattle()
                }
            }
        )
    }

    private func finalizeBattle() {
        guard !isFinished else { return }
        isFinished = true

        guard let floor else { return }

        // 計算獎勵
        let seed     = UInt64(task.startedAt.timeIntervalSinceReferenceDate.bitPattern)
                     ^ UInt64(bitPattern: task.id.hashValue)
        let goldRng  = DeterministicRNG(seed: seed ^ 0x474F4C44)  // "GOLD"
        rewardGold   = DungeonSettlementEngine.computeGold(
            floor: floor, battlesWon: battlesWon, rng: &goldRng
        )

        // 填入 TaskModel result
        task.battlePending     = false
        task.resultBattlesWon  = battlesWon
        task.resultBattlesLost = battlesLost
        task.resultGold        = rewardGold

        // 素材獎勵（複用現有 DungeonSettlementEngine 邏輯）
        DungeonSettlementEngine.fillMaterialResults(
            task: task, floor: floor, battlesWon: battlesWon
        )

        // 首通標記（若未首通過）
        appState.progressionService.markDungeonProgression(task: task)

        try? context.save()
    }

    // MARK: - 完成面板

    private var finishedPanel: some View {
        VStack(spacing: 14) {
            Divider()

            Label(
                "戰鬥結束：\(battlesWon) 勝 \(battlesLost) 敗",
                systemImage: battlesWon > 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(battlesWon > 0 ? .green : .red)

            if rewardGold > 0 {
                Text("獲得 \(rewardGold) 金幣")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("收下獎勵") {
                grantRewardAndClose()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(rewardGranted)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func grantRewardAndClose() {
        guard !rewardGranted, let player else { return }

        // 金幣入帳
        player.gold += rewardGold

        // 更新累計統計
        player.totalBattlesWon  += battlesWon
        player.totalBattlesLost += battlesLost
        player.totalGoldEarned  += rewardGold

        try? context.save()

        // 成就檢查
        appState.achievementService.checkAll()

        rewardGranted = true
        appState.clearDungeonBattle()
    }
}
```

---

## DungeonSettlementEngine 新增純函式

T03 的 `finalizeBattle()` 需要兩個不改現有介面的純計算函式：

```swift
extension DungeonSettlementEngine {

    /// 根據勝場數計算金幣獎勵（確定性 RNG）
    static func computeGold(
        floor: DungeonFloorDef,
        battlesWon: Int,
        rng: inout DeterministicRNG
    ) -> Int {
        guard battlesWon > 0 else { return 0 }
        return (0..<battlesWon).reduce(0) { acc, _ in
            acc + rng.nextInt(in: floor.goldPerBattleRange)
        }
    }

    /// 填入素材 result 欄位（複用現有 V2-1 路徑的素材計算，僅限勝場）
    static func fillMaterialResults(task: TaskModel, floor: DungeonFloorDef, battlesWon: Int) {
        guard battlesWon > 0 else { return }
        let seed   = UInt64(task.startedAt.timeIntervalSinceReferenceDate.bitPattern)
                   ^ UInt64(bitPattern: task.id.hashValue)
                   ^ 0x4D415445  // "MATE"
        var matRng = DeterministicRNG(seed: seed)

        for drop in floor.dropTable {
            let count = (0..<battlesWon).reduce(0) { acc, _ in
                matRng.nextDouble() < drop.dropRate ? acc + drop.amount : acc
            }
            task.setResult(count, of: drop.material)
        }
    }
}
```

---

## 注意事項

- 素材入帳由 `TaskClaimService.claimAllCompleted()` 在玩家「收下」時負責（現有機制），
  本 Ticket 只負責把金幣直接入帳並關閉 Sheet（簡化路徑，避免再走一次 SettlementSheet）。

- 若 `DungeonFloorDef` 尚無 `enemyName` 欄位，先用 `floor.name` 代替，T05 狀態效果完成後可補充。

- `appState.clearDungeonBattle()` 應在 Sheet 確認關閉前呼叫，不在 `onDisappear` 觸發，
  避免玩家意外滑動關閉時獎勵遺失。

---

## 驗收標準

- [ ] 開啟 DungeonBattleSheet → 第一場戰鬥自動開始播放（HP 條 / ATB 條 / 事件 log）
- [ ] 每場結束後自動銜接下一場，頂部「第 N 場 / 共 M 場」計數正確
- [ ] 全部場次完成 → finishedPanel 出現，顯示勝敗場數與金幣
- [ ] 「收下獎勵」→ 金幣入帳、累計統計更新、Sheet 關閉
- [ ] `task.battlePending == false`、`resultBattlesWon/Lost/Gold` 正確填入
- [ ] `xcodebuild` 通過，無新警告
