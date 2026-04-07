# V2-4 Ticket 03：任務進度條（BaseView + AdventureView）

**狀態：** ✅ 完成

**依賴：** 無（獨立）

---

## 目標

任務目前只顯示「剩餘時間」文字，缺少視覺化進度。
本 ticket 在採集、鑄造、出征三個進行中任務區塊加入進度條，由 `appState.tick` 每秒更新。

---

## 修改一：BaseView — 採集者 row 進度條

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

在 `npcGathererRow` 的 VStack 內，倒數文字（`.foregroundStyle(.green)`）下方加入：

```swift
let progress = taskProgress(task)
ProgressView(value: progress)
    .tint(.green)
    .scaleEffect(y: 0.7)
    .padding(.top, 1)
```

---

## 修改二：BaseView — 鑄造師 row 進度條

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

在 `npcBlacksmithRow` 的 VStack 內，倒數文字（`.foregroundStyle(.orange)`）下方加入：

```swift
let progress = taskProgress(task)
ProgressView(value: progress)
    .tint(.orange)
    .scaleEffect(y: 0.7)
    .padding(.top, 1)
```

---

## 修改三：AdventureView — 出征 Banner 進度條

**檔案：** `IdleBattleRPG/Views/AdventureView.swift`

在出征進行中的 Banner 區塊（含倒數時間的 HStack/VStack），倒數文字下方加入：

```swift
let progress = taskProgress(task)
ProgressView(value: progress)
    .tint(.blue)
    .padding(.top, 2)
```

---

## 共用進度計算 Helper

BaseView 和 AdventureView 各自加入 private func（不跨 View 共用，避免不必要的耦合）：

```swift
private func taskProgress(_ task: TaskModel) -> Double {
    let total    = task.endsAt.timeIntervalSince(task.startedAt)
    let elapsed  = appState.tick.timeIntervalSince(task.startedAt)
    guard total > 0 else { return 1.0 }
    return min(1.0, max(0.0, elapsed / total))
}
```

- 使用 `appState.tick` 驅動（每秒更新，BaseView / AdventureView 已訂閱）
- `min(1.0, ...)` 確保不超過 100%
- `max(0.0, ...)` 防止負值（時鐘誤差）

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/BaseView.swift` | ✏️ 修改（npcGathererRow + npcBlacksmithRow 加進度條 + helper） |
| `Views/AdventureView.swift` | ✏️ 修改（出征 Banner 加進度條 + helper） |

---

## 驗收標準

- [ ] 採集者進行中時顯示綠色進度條，每秒推進
- [ ] 鑄造師進行中時顯示橙色進度條，每秒推進
- [ ] 出征進行中時 Banner 顯示藍色進度條，每秒推進
- [ ] 閒置（無任務）時不顯示進度條
- [ ] 任務到期（progress = 1.0）時進度條滿格，不溢出
- [ ] Build 無錯誤
