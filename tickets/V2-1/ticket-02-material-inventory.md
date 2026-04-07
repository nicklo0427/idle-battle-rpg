# V2-1 Ticket 02：區域素材 SwiftData 正式化

**狀態：** ✅ 已完成（commit `a7da9df`）

---

## 目標

將 V2-1 新增的 12 個區域素材，完整打通「可存 / 可結算 / 可入帳 / 可顯示」的正式資料鏈。移除 Ticket 01 的 bridge no-op，升級為正式 SwiftData 欄位。

---

## 新增 / 修改檔案

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Models/MaterialInventoryModel.swift` | ✏️ 修改 | 新增 12 個 SwiftData 欄位；`amount()` / `add()` / `deduct()` 全部展開為 exhaustive switch，移除 bridge no-op |
| `Models/TaskModel.swift` | ✏️ 修改 | 新增 12 個 `result*` Int 欄位（預設 0）；新增 `resultAmount(of:)` 便利讀取 + `setResult(_:of:)` 便利寫入 |
| `Services/DungeonSettlementEngine.swift` | ✏️ 修改 | 新增 `FloorDungeonResult` 結構（`[MaterialType:Int]`）；新增 `settle(task:floor:)` V2-1 路徑；V1 路徑完整保留 |
| `Services/SettlementService.swift` | ✏️ 修改 | `fillDungeonResults()` 改為雙路徑：V1 先試 `DungeonAreaDef.find()`，miss 再試 `DungeonFloorDef` |
| `Services/TaskClaimService.swift` | ✏️ 修改 | `accumulateMaterials()` 改為迭代 `MaterialType.allCases`，一次涵蓋全部 17 種素材 |
| `ViewModels/SettlementViewModel.swift` | ✏️ 修改 | `makeRewardLines()` 改為迭代 `MaterialType.allCases`，12 個區域素材自動顯示 |

---

## 資料鏈流程

```
地下城任務（V2-1 floor key）
  ↓ SettlementService.fillDungeonResults（V2-1 路徑）
  ↓ DungeonSettlementEngine.settle(task:floor:) → FloorDungeonResult
  ↓ task.setResult(_:of:) 寫入 12 個 result 欄位
  ↓ 結算 Sheet 顯示（SettlementViewModel.makeRewardLines）
  ↓ 玩家點「收下」→ TaskClaimService.claimAllCompleted()
  ↓ task.resultAmount(of:) 讀取 → inventory.add(_:of:)
  ↓ MaterialInventoryModel 12 個欄位更新
  ↓ SwiftData 持久化
```

---

## 關鍵決策

**`resultAmount(of:)` / `setResult(_:of:)` 集中在 TaskModel：**
讓 Service 層不需要 17 個 switch case。Model 只做純資料存取（getter/setter），符合 CLAUDE.md 規範。

**迭代 `MaterialType.allCases`：**
`TaskClaimService` 和 `SettlementViewModel` 皆改為 `for mat in MaterialType.allCases`，未來新增素材時不需修改這兩個檔案。

**V1 / V2-1 雙路徑完全隔離：**
`SettlementService` 先試 V1 路徑，miss 再試 V2-1 路徑，確保現有 MVP 任務完全不受影響。

**`FloorDungeonResult` 使用 `[MaterialType: Int]`：**
引擎不硬編碼素材欄位，任何 `DungeonFloorDef.dropTable` 的 `MaterialType` 皆可直接傳出，未來新增素材不需修改引擎。
