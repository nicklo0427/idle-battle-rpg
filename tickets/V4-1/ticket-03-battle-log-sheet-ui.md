# V4-1 Ticket 03：BattleLogSheet UI + FloorDetailSheet 入口

**狀態：** ✅ 完成

**依賴：** T01 BattleLogGenerator

---

## 目標

建立 `BattleLogSheet` 共用元件（V4-1 與 V4-2 共用），並在 `FloorDetailSheet` 進行中狀態新增「查看過程」入口。

---

## 新建檔案

`Views/BattleLogSheet.swift`

## 修改檔案

`Views/AdventureView.swift`（FloorDetailSheet 內部）

---

## BattleLogSheet 結構

```
┌──────────────────────────────┐
│  🧙 英雄  ████████░░  85/100 │  ← heroHP 條
│  👹 敵名  ████░░░░░░  42/80  │  ← enemyHP 條
├──────────────────────────────┤
│  [ScrollView 逐回合文字]       │
│  英雄攻擊 → 造成 45 傷害        │
│  礦坑菁英反擊 → 造成 18 傷害    │
│  ...                          │
└──────────────────────────────┘
```

### Props

```swift
struct BattleLogSheet: View {
    let events: [BattleEvent]
    let title: String            // 例："第 3 層 — 廢棄礦坑"
    // 可選：菁英戰鬥模式（V4-2 使用）
    var eliteResult: EliteBattleOutcome? = nil
    var onRetry: (() -> Void)? = nil
}
```

### HP 條邏輯

- 跟隨最新顯示 event 的 `heroHpAfter` / `enemyHpAfter` 更新
- 首個 event 的 `heroMaxHp` / `enemyMaxHp` 作為血量上限（整個 sheet 固定）
- 用 `ProgressView(value:total:)` 顯示（iOS 17 原生）

### 文字播放（AFK 查看模式）

- `@State private var displayedCount = 0`
- `Timer.scheduledTimer(withTimeInterval: 0.3, ...)` → 每 0.3 秒追加一個 event
- Timer 在 `.onDisappear` 停止

### 菁英模式底部（V4-2 預留）

- `eliteResult == .won` → 顯示勝利文字 + 關閉按鈕
- `eliteResult == .lost` → 顯示「落敗… 再試一次」按鈕（呼叫 `onRetry`）
- AFK 模式（`eliteResult == nil`）→ 不顯示底部 UI

### Sheet 設定

```swift
.presentationDetents([.medium, .large])
.navigationTitle(title)
.navigationBarTitleDisplayMode(.inline)
```

---

## FloorDetailSheet 修改

在進行中狀態區塊（`task.status == .inProgress`）新增：

```swift
Button("查看過程") {
    let idx = BattleLogGenerator.currentBattleIndex(for: task)
    battleEvents = BattleLogGenerator.generate(task: task, floor: floor, fromBattleIndex: idx)
    showBattleLog = true
}
.buttonStyle(.bordered)
```

- `.sheet(isPresented: $showBattleLog) { BattleLogSheet(events: battleEvents, title: floor.name) }`
- 只在 `task.status == .inProgress` 時顯示此按鈕

---

## 驗收標準

- [ ] BattleLogSheet 顯示英雄與敵人 HP 條
- [ ] 文字以每 0.3 秒逐行播放
- [ ] HP 條跟隨最新顯示 event 更新
- [ ] FloorDetailSheet 進行中時出現「查看過程」按鈕
- [ ] 點擊後正確開啟 BattleLogSheet
- [ ] `eliteResult` 預留介面存在（V4-2 會填入）
