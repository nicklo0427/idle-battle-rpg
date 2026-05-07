# V10-1 Ticket 01：開場敘事屏

**狀態：** ✅ 已完成

**依賴：** 無

---

## 目標

新玩家首次啟動時完全沒有世界觀說明，直接進入職業選擇。加入 3 張全屏敘事卡，建立「廢墟甦醒 → 被救回要塞 → 重新出發」的世界觀框架。

---

## 設計

**觸發條件：** `player.hasSeenIntro == false`（新玩家或從未看過的舊存檔）

**3 張卡片內容：**

| # | SF Symbol | 標題 | 摘要 |
|---|-----------|------|------|
| 1 | `rays` | 廢墟之中 | 在黑暗中甦醒，身旁是廢石與破牆，手邊攥著生鏽短劍 |
| 2 | `house.lodge.fill` | 邊境要塞 | 被採集者、鑄造師、商人等人救回簡陋要塞 |
| 3 | `figure.fencing` | 重新出發 | 地下城的陰影蔓延，曾經是什麼人決定如何走下去 |

**UI 規格：**
- 黑色背景，白色大標題 + 內文
- 底部 Page Indicator（3 圓點）
- 「下一頁」按鈕（最後一張改「繼續」）
- 右上角「跳過」可隨時結束

**完成後：** `hasSeenIntro = true`，進入 T02 英雄命名

---

## 新增檔案

### `Views/IntroNarrativeView.swift`

```swift
struct IntroNarrativeView: View {
    var onFinished: () -> Void
    @State private var currentPage = 0

    // 3 張 Slide（icon / title / body）
    // 跳過 / 繼續 → finish() → hasSeenIntro = true → onFinished()
}
```

### `Views/NewPlayerFlowView.swift`

由 ContentView 傳入已確認存在的 `PlayerStateModel`，同步決定起始步驟，無 @Query 時序問題：

```swift
struct NewPlayerFlowView: View {
    let player: PlayerStateModel
    private enum Step { case intro, naming, classSelection }
    @State private var step: Step

    init(player: PlayerStateModel) {
        _step = State(initialValue: player.hasSeenIntro ? .naming : .intro)
    }
}
```

---

## 修改檔案

### `ContentView.swift`

移除 BaseView fullScreenCover 觸發方式，改在 ContentView 層直接閘門：

```swift
if needsNewPlayerFlow(player) {
    NewPlayerFlowView(player: player)
} else {
    mainTabView(appState: appState)
}

private func needsNewPlayerFlow(_ player: PlayerStateModel) -> Bool {
    !player.hasSeenIntro || player.classKey.isEmpty
}
```

### `Models/PlayerStateModel.swift`

新增欄位（需在 `init` 中明確賦值，避免 @Model backing store 回傳非預期值）：

```swift
var hasSeenIntro: Bool = false
```

### `Models/DatabaseSeeder.swift`

新增 `backfillHasSeenIntro`：classKey 非空的舊存檔設 `hasSeenIntro = true`，避免升級後再次看到開場。

---

## 舊存檔相容

- 新欄位 `hasSeenIntro` 預設 `false`，SwiftData 輕量遷移自動處理
- `DatabaseSeeder.backfillHasSeenIntro()` 在每次啟動時執行，對 classKey 非空的存檔補設 `true`

---

## 驗證

1. 新裝置首次安裝 → 看到 3 張敘事卡 → 可用「下一頁」逐頁瀏覽
2. 點「跳過」→ 直接進英雄命名
3. 舊存檔升級（classKey 非空）→ 不顯示敘事卡
