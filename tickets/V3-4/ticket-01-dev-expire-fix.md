# V3-4 Ticket 01：Dev 快速完成任務修正（保留完整時長）

**狀態：** ✅ 完成

**依賴：** 無

---

## 問題

`BaseView.devExpireAllTasks()` 目前只把 `endsAt` 設為 `now - 2`，
但 `startedAt` 維持原值（任務剛建立，幾秒前）。

結算引擎用 `endsAt - startedAt` 計算任務時長，因此算出的時長接近 0：
- 地下城：戰鬥場次幾乎為 0 → 沒有金幣、素材、EXP → **像撤退**
- 採集：產出量公式同樣依賴時長，結果為 0
- 鑄造：`resultCraftedEquipKey` 建立時已填入，不受影響

---

## 修改

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

```swift
// 改前
private func devExpireAllTasks() {
    let past = Date.now.addingTimeInterval(-2)
    tasks.filter { $0.status == .inProgress }.forEach { $0.endsAt = past }
    try? context.save()
    appState.scanAndSettle()
}

// 改後
private func devExpireAllTasks() {
    let now = Date.now
    tasks.filter { $0.status == .inProgress }.forEach { task in
        let duration = task.endsAt.timeIntervalSince(task.startedAt)
        task.startedAt = now.addingTimeInterval(-duration - 2)
        task.endsAt    = now.addingTimeInterval(-2)
    }
    try? context.save()
    appState.scanAndSettle()
}
```

### 說明

`startedAt` 與 `endsAt` 同步往過去移，**保留原始時長**。
結算引擎讀到的 `endsAt - startedAt` 與玩家實際設定的時長（15 分鐘 / 1 小時 / 8 小時 / 12 小時）完全一致，
產出量、勝場數、EXP 等全部正常計算。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/BaseView.swift` | ✏️ 修改（devExpireAllTasks，僅 debug） |

---

## 驗收標準

- [ ] 建立 15 分鐘地下城任務 → 點「快速完成」→ 收下後有正常金幣與戰鬥場次
- [ ] 建立 12 小時地下城任務 → 點「快速完成」→ 收下後產出量與手動等 12 小時結果一致
- [ ] 採集任務快速完成後素材數量正常（非 0）
- [ ] Build 無錯誤
