# V6-2 Ticket 04：CharacterView 天賦 Tab

**狀態：** 📋 延後（天賦樹設計待確認）
**版本：** V6-2
**依賴：** T01、T02、T03

---

## 說明

在 `CharacterView` 的 Segment Picker 新增「天賦」Tab，展示玩家職業的 2 條天賦路線及 10 個節點，支援手動投入天賦點。

---

## CharacterSegment 修改

```swift
// 新增 .talent 到現有 enum
enum CharacterSegment: String, CaseIterable {
    case gear    = "裝備"
    case skills  = "技能"
    case talent  = "天賦"   // 新增
    case stats   = "屬性"
}
```

---

## UI 結構

### talentSegment（`@ViewBuilder`）

```
if let player {
    talentContent(player:)
} else {
    Section { Text("讀取中…") }
}
```

### talentContent(player:)

```
┌─────────────────────────────────────────┐
│  可用天賦點：N 點                          │  ← Header badge（橘色或主題色）
│                                         │
│  ┌─ Section：[路線名稱] ─────────────────┐  │
│  │  [路線主題描述]                        │  │
│  │  ┌─ 節點 1 ──────────────────────────┐ │  │
│  │  │  🟢 名稱        效果描述  [已投入] │ │  │
│  │  └─────────────────────────────────┘ │  │
│  │  ┌─ 節點 2 ──────────────────────────┐ │  │
│  │  │  🔵 名稱        效果描述  [投入]  │ │  │  ← 可投入：顯示按鈕
│  │  └─────────────────────────────────┘ │  │
│  │  ┌─ 節點 3 ──────────────────────────┐ │  │
│  │  │  🔒 名稱        效果描述  [locked]│ │  │  ← 未解鎖：灰色
│  │  └─────────────────────────────────┘ │  │
│  └─────────────────────────────────────┘  │
│                                         │
│  ┌─ Section：[路線名稱 2] ───────────────┐  │
│  │  ... 同上 ...                         │  │
│  └─────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 節點狀態視覺規則

| 狀態 | 圓點顏色 | 按鈕 | 文字 |
|---|---|---|---|
| 已投入 | ✅ 綠色 | 無 | "已投入" label（灰） |
| 可投入（有點數 + 前置滿足） | 🔵 藍色 | `Button("投入")` | 正常顯示 |
| 前置未解鎖 | ⬜ 灰色 | 無（🔒 icon） | 灰色淡化 |
| 有點數但前置未解鎖 | ⬜ 灰色 | 無 | 灰色淡化 |

---

## 投入邏輯

```swift
// 在 View 內（或透過 CharacterViewModel）
func investTalent(nodeKey: String) {
    guard let player = player else { return }
    try? appState.talentService.investPoint(nodeKey: nodeKey, for: player)
    // SwiftData @Query 會自動 re-render
}
```

`TalentService.investPoint` 成功後，SwiftData `@Query private var players` 的變更會自動觸發 View 更新，無需手動 `objectWillChange.send()`。

---

## 可用天賦點 Badge

```swift
// 在 talent tab label 上顯示數量（類似 iOS 通知 badge）
if player.availableTalentPoints > 0 {
    Text("\(player.availableTalentPoints)")
        .font(.caption2)
        .foregroundStyle(.white)
        .padding(4)
        .background(Color.orange, in: Circle())
}
```

或在 Picker label 上以 `Label` + badge overlay 形式顯示，視現有 Picker 樣式決定。

---

## 注意事項

- `CharacterView` 使用 `@ViewBuilder guard` 的已知問題：使用 `if let player { ... } else { ... }` 而非 `guard let player else { return }`（見 V6-1 T05 先例）
- `TalentService` 透過 `AppState` 注入，方式與現有 `EquipmentService`、`PlayerStateService` 一致
- 路線順序：`TalentRouteDef.all(for: player.classKey)` 回傳的順序即為顯示順序

---

## 實作位置

- 修改：`IdleBattleRPG/Views/CharacterView.swift`

---

## 驗收標準

- [ ] `CharacterSegment` 包含 `.talent = "天賦"`
- [ ] 天賦 Tab 顯示目前職業的 2 條路線
- [ ] 每條路線顯示 5 個節點，依序排列
- [ ] 已投入節點：綠色圓點 + "已投入" 標示，無按鈕
- [ ] 可投入節點：投入按鈕，點擊後立即反映（天賦點 -1、節點標綠）
- [ ] 前置未解鎖節點：灰色 + 🔒
- [ ] `availableTalentPoints == 0` 時，所有未投入節點按鈕消失
- [ ] 投入後角色頁戰力數值同步更新（因 HeroStatsService 重算）
- [ ] `xcodebuild` 通過，無新警告
