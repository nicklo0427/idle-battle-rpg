# V6-3 Ticket 04：BattleLogPlaybackModel onBattleEnded Callback

**狀態：** 🔲 待實作
**版本：** V6-3
**依賴：** 無（可與 T01/T02 並行）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogPlaybackModel.swift`

---

## 說明

`DungeonBattleSheet`（T03）需要在每場戰鬥結束後（`.victory` / `.defeat` 事件播放完畢、
進入下一場之前）收到通知，以便累計勝敗場數、啟動下一場。

本 Ticket 為 `BattleLogPlaybackModel.start()` 新增 `onBattleEnded` 可選 callback，
**預設為 nil，所有現有呼叫點不需修改**。

---

## BattleLogPlaybackModel.start() 簽名修改

```swift
// 修改前
func start(
    events:           [BattleEvent],
    fromBattleIndex:  Int,
    taskTotalBattles: Int,
    taskId:           UUID
)

// 修改後（新增末尾可選參數）
func start(
    events:           [BattleEvent],
    fromBattleIndex:  Int,
    taskTotalBattles: Int,
    taskId:           UUID,
    onBattleEnded:    ((Bool) -> Void)? = nil   // ← 新增，預設 nil
)
```

---

## 播放迴圈修改

`start()` 內部的播放 `Task` 會按事件序列步進。
在偵測到 `.victory` 或 `.defeat` 事件並等待固定停頓（目前約 2 秒）後，
**在進入下一場事件之前**，呼叫 callback：

```swift
// 播放迴圈（節錄）
for event in currentBattleEvents {
    // ... 現有步進邏輯 ...

    switch event.type {
    case .victory:
        // ... 現有勝利處理 ...
        await Task.sleep(nanoseconds: 2_000_000_000)   // 停頓 2 秒（現有）
        onBattleEnded?(true)                            // ← 新增

    case .defeat:
        // ... 現有失敗處理 ...
        await Task.sleep(nanoseconds: 2_000_000_000)
        onBattleEnded?(false)                           // ← 新增

    default: break
    }
}
```

callback 的呼叫時機：**停頓結束之後、下一場事件開始之前**。
`DungeonBattleSheet` 收到後才呼叫 `startNextBattle()`，確保時序正確。

---

## 現有呼叫點確認

以下呼叫點傳入預設 nil，行為不變：
- `AdventureView`（AFK 戰鬥記錄查看）
- `EliteBattleSheet`（菁英即時戰鬥）
- 其他所有使用 `BattleLogPlaybackModel` 的地方

---

## 驗收標準

- [ ] `DungeonBattleSheet` 透過 `onBattleEnded` 正確收到每場勝（true）/ 敗（false）通知
- [ ] callback 在 2 秒停頓後、下一場開始前觸發（時序不倒置）
- [ ] `EliteBattleSheet` 和 AFK 戰鬥記錄播放行為完全不受影響
- [ ] `xcodebuild` 通過，無新警告
