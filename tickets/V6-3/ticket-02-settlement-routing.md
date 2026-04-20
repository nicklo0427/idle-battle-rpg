# V6-3 Ticket 02：SettlementSheet 路由 + AppState 觸發點

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T01

**修改檔案：**
- `IdleBattleRPG/AppState.swift`
- `IdleBattleRPG/Views/SettlementSheet.swift`
- `IdleBattleRPG/ContentView.swift`

---

## 說明

T01 讓 dungeon 任務到期後帶有 `battlePending = true`。
本 Ticket 將 UI 路由接上：SettlementSheet 偵測到此狀態時，
顯示「⚔️ 開始戰鬥」按鈕，點擊後透過 AppState 開啟 `DungeonBattleSheet`。

---

## AppState 修改

新增觸發點，讓 DungeonBattleSheet 可以在任何 View 層彈出：

```swift
// AppState.swift — Services 區塊之後

/// 待即時戰鬥的地下城任務（非 nil 時彈出 DungeonBattleSheet）
var pendingDungeonBattleTask: TaskModel? = nil

func startDungeonBattle(task: TaskModel) {
    pendingDungeonBattleTask = task
}

func clearDungeonBattle() {
    pendingDungeonBattleTask = nil
}
```

`TaskModel` 需要 `Identifiable`（已是），可直接作為 `.sheet(item:)` 的 item 型別。

---

## SettlementSheet 修改

在每個任務列的顯示邏輯中加入 `battlePending` 分支。

現有的任務列大致結構（節錄，依實際程式碼調整）：

```swift
// 修改前
ForEach(completedTasks) { task in
    taskRow(task: task)
}

// taskRow 修改後（在方法最開頭加入判斷）
@ViewBuilder
private func taskRow(task: TaskModel) -> some View {
    if task.battlePending {
        battlePendingRow(task: task)
    } else {
        // 現有的結果顯示 UI（不動）
        ...
    }
}

@ViewBuilder
private func battlePendingRow(task: TaskModel) -> some View {
    HStack(spacing: 12) {
        Image(systemName: "bolt.circle.fill")
            .font(.title2)
            .foregroundStyle(.orange)

        VStack(alignment: .leading, spacing: 2) {
            Text(taskDisplayName(task))           // 沿用現有的任務名稱方法
                .fontWeight(.semibold)
            Text("探索完成，準備發起戰鬥")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()

        Button("⚔️ 開始戰鬥") {
            appState.startDungeonBattle(task: task)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }
    .padding(.vertical, 4)
}
```

---

## ContentView 修改

在 `.sheet` 鏈中新增 DungeonBattleSheet 觸發：

```swift
// ContentView.swift 或 SettlementSheet 所在的 fullScreenCover / sheet 層
.sheet(item: $appState.pendingDungeonBattleTask) { task in
    DungeonBattleSheet(task: task, appState: appState)
        .interactiveDismissDisabled(true)   // 戰鬥中不允許下滑關閉
}
```

`interactiveDismissDisabled(true)` 確保玩家不能意外關閉正在進行的戰鬥。

---

## 注意事項

- `battlePendingRow` 的任務**不能被「全部收下」按鈕一起收走**：
  確認現有的「收下全部」邏輯在收下前先過濾掉 `battlePending == true` 的任務。

```swift
// TaskClaimService 或 AppState.claimAllCompleted() 修改（或確認已有此過濾）
let claimable = completedTasks.filter { !$0.battlePending }
```

---

## 驗收標準

- [ ] dungeon 任務完成後，SettlementSheet 顯示橙色「⚔️ 開始戰鬥」按鈕，不顯示勝敗數字
- [ ] 其他任務（gather / craft）正常顯示結果、可正常收下
- [ ] 「收下全部」不把 `battlePending == true` 的任務一起收走
- [ ] 點擊「⚔️ 開始戰鬥」→ 開啟 DungeonBattleSheet，Sheet 無法下滑關閉
- [ ] `xcodebuild` 通過，無新警告
