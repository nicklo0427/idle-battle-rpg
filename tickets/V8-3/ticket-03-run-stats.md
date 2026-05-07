# V8-3 Ticket 03：戰鬥統計摘要（Run Stats Summary）

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

地下城結算面板新增可折疊「戰鬥詳情」區塊，展示本次出征的統計數字（非持久化，Sheet 關閉即消失）。

---

## 修改細節

### `Services/BattleLogGenerator.swift` — BattleEvent 新增欄位

```swift
// BattleEvent struct 新增
let damageAmount: Int   // default: 0

// init 新增參數
damageAmount: Int = 0
```

填入 `damageAmount` 的事件：
- `.attack`：`heroDmg`（英雄普攻）
- `.damage`：`enemyDmg`（受到傷害）
- `.skill`（有傷害的）：`dmg`（各技能的傷害量）
- `.statusTick`（燃燒 / 中毒）：`dpt` / `poisonDmg`

### `Views/DungeonBattleSheet.swift`

**新增 State 變數：**
```swift
@State private var allCollectedEvents: [BattleEvent] = []
@State private var statsExpanded: Bool = false
```

**在 `startNextBattle()` 累積事件：**
```swift
allCollectedEvents.append(contentsOf: events)
```

**新增 `DungeonRunStats` struct 和 `computeRunStats()` 方法：**
```swift
private struct DungeonRunStats {
    var totalDamageDealt:    Int  = 0
    var totalDamageReceived: Int  = 0
    var critCount:           Int  = 0
    var skillsTriggered:     Int  = 0
    var potionUsed:          Bool = false
}
```

**`finishedPanel` 新增摺疊按鈕 + 展開後的 5 行統計數字。**

---

## 修改檔案

- `Services/BattleLogGenerator.swift`（BattleEvent + damageAmount）
- `Views/DungeonBattleSheet.swift`（stats 累積 + UI）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 結算面板出現「⚔️ 戰鬥詳情 ∨」摺疊列
- [ ] 展開後顯示造成傷害 / 承受傷害 / 暴擊次數 / 技能施放
- [ ] 使用藥水時顯示「藥水使用 ✓」
- [ ] 展開 / 收合動畫流暢，不影響其他按鈕
- [ ] 數字合理（造成傷害 > 0、暴擊次數 ≤ 普攻次數）
