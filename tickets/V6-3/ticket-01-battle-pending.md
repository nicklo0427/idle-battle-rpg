# V6-3 Ticket 01：TaskModel battlePending + SettlementService 分離

**狀態：** 🔲 待實作
**版本：** V6-3
**依賴：** 無

**修改檔案：**
- `IdleBattleRPG/Models/TaskModel.swift`
- `IdleBattleRPG/Services/SettlementService.swift`

---

## 說明

地下城 AFK 出征的戰鬥結果不應在任務到期時預先計算，
而應保留「戰鬥待發起」狀態，等玩家回到 App 後即時進行。

本 Ticket 只做分離：到期後只標記 `battlePending = true`，
不呼叫 `DungeonSettlementEngine`，result* 欄位全部保留為 0。

Gather / Craft 任務流程不受影響。

---

## TaskModel 新增欄位

```swift
// V6-3 T01：地下城戰鬥未結算標記
// SwiftData 輕量遷移，有預設值
var battlePending: Bool = false
```

**無需**新增 computed property，直接用 `task.battlePending` 判斷。

---

## SettlementService 修改

現有 `markCompleted(_ task: TaskModel)` 方法內的 dungeon 路徑：

```swift
// 修改前（節錄）
case .dungeon:
    if let floor = DungeonRegionDef.findFloor(key: task.definitionKey) {
        DungeonSettlementEngine.settle(task: task, floor: floor)
        progressionService.markDungeonProgression(task: task)
    }
    task.status = .completed

// 修改後
case .dungeon:
    // 不計算戰鬥結果，改為即時戰鬥路徑
    task.battlePending = true
    task.status = .completed
    // 注意：首通標記、result* 欄位全部移至 DungeonBattleSheet.finalizeBattle() 處理
```

Gather / craft 的路徑維持原封不動。

---

## 向後相容

- 已存在的 `.completed` 舊任務（`battlePending = false`）：正常顯示結果、正常收下，不受影響。
- SwiftData 新增 `battlePending` 欄位預設為 `false`，舊存檔自動遷移，無需 VersionedSchema。

---

## 驗收標準

- [ ] dungeon 任務到期後：`battlePending == true`，`resultBattlesWon == 0`，`resultGold == 0`
- [ ] gather 任務到期後：`resultWood` / `resultOre` 等正常填入，`battlePending == false`
- [ ] craft 任務到期後：`resultCraftedEquipKey` 正常填入，`battlePending == false`
- [ ] 舊存檔的 `battlePending` 預設為 `false`，不影響現有已完成任務
- [ ] `xcodebuild` 通過，無新警告
