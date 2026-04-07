# V2-3 Ticket 02：PlayerStateModel 新增 NPC 升級等級欄位

**狀態：** ✅ 完成

**依賴：** Ticket 01（NpcUpgradeDef）

---

## 目標

在 `PlayerStateModel` 中新增 3 個 SwiftData 欄位，分別記錄兩位採集者與鑄造師的升級 Tier，並提供便利查詢方法。

---

## 修改檔案

`IdleBattleRPG/Models/PlayerStateModel.swift`

### 新增欄位（預設 0）

```swift
var gatherer1Tier: Int = 0
var gatherer2Tier: Int = 0
var blacksmithTier: Int = 0
```

### 新增便利方法

```swift
/// 根據 actorKey 回傳對應 NPC 的升級 Tier
func tier(for actorKey: String) -> Int {
    switch actorKey {
    case "gatherer_1": return gatherer1Tier
    case "gatherer_2": return gatherer2Tier
    case "blacksmith":  return blacksmithTier
    default:            return 0
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/PlayerStateModel.swift` | ✏️ 修改（+3 欄位 + 1 方法）|

### SwiftData Migration 說明

新增有預設值的欄位，SwiftData 自動處理 migration（iOS 17+ 行為），不需額外 Migration Plan。

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] `PlayerStateModel` 有 `gatherer1Tier`、`gatherer2Tier`、`blacksmithTier` 三個 `Int` 欄位
- [ ] `player.tier(for: "gatherer_1")` 回傳 `gatherer1Tier`
- [ ] `player.tier(for: "blacksmith")` 回傳 `blacksmithTier`
- [ ] `player.tier(for: "unknown")` 回傳 `0`
- [ ] 現有 build target 無回歸
