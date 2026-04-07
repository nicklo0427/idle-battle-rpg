# V2-1 Ticket 03：地下城推進狀態模型

**狀態：** ✅ 已完成（commit `a7da9df`）

---

## 目標

建立 V2-1 的 progression 資料層，讓地下城具備「首通 / 解鎖 / 推進 / 區域完成 / 可見但未解鎖」等中期可玩性所需的長期狀態記錄。

---

## 新增 / 修改檔案

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Models/DungeonProgressionModel.swift` | 🆕 新增 | SwiftData @Model 單例；`clearedFloorKeysJSON` / `unlockedRegionKeysJSON` 兩個 JSON String 欄位 |
| `Services/DungeonProgressionRepository.swift` | 🆕 新增 | 薄層 CRUD；`fetch()` / `fetchOrCreate()` / `save()`；不含業務邏輯 |
| `Services/DungeonProgressionService.swift` | 🆕 新增 | 推進規則引擎；5 個查詢方法 + 1 個變更方法；無副作用，可單元測試 |
| `IdleBattleRPGApp.swift` | ✏️ 修改 | ModelContainer schema 加入 `DungeonProgressionModel.self` |
| `Models/DatabaseSeeder.swift` | ✏️ 修改 | 新增 `seedDungeonProgression()`；初始狀態：`wildland` 已解鎖，無首通紀錄 |
| `Services/SettlementService.swift` | ✏️ 修改 | init 加入 `DungeonProgressionService`；dungeon 結算後自動呼叫 `markDungeonProgression()` |
| `AppState.swift` | ✏️ 修改 | 持有並公開 `progressionService: DungeonProgressionService`，供 ViewModel 查詢 |
| `ViewModels/AdventureViewModel.swift` | ✏️ 修改 | 新增 5 個 V2-1 progression 查詢方法（接受 `service: DungeonProgressionService` 參數）|

---

## 資料模型設計

```swift
// DungeonProgressionModel（SwiftData 單例）
var clearedFloorKeysJSON:   String  // JSON [String]，已首通樓層 keys
var unlockedRegionKeysJSON: String  // JSON [String]，已解鎖區域 keys（初始含 "wildland"）
```

儲存格式選用 JSON-encoded String（基本型別）而非 `[String]`，確保 SwiftData iOS 17 相容性。

---

## 解鎖規則

```
區域解鎖：
  wildland        → 預設解鎖（DatabaseSeeder 初始值）
  abandoned_mine  → wildland Boss 層（floor_4）首通後自動解鎖
  ancient_ruins   → abandoned_mine Boss 層首通後自動解鎖

樓層解鎖（within 已解鎖區域）：
  floor_1 → 區域解鎖即可挑戰
  floor_N → floor_(N-1) 已首通才可挑戰

首通定義：任務完成一次即記錄，不論勝負場次（idle game 語義）
冪等保證：markFloorCleared() 重複呼叫不累積
```

---

## DungeonProgressionService 查詢能力

| 方法 | 說明 |
|---|---|
| `isRegionUnlocked(_:)` | 區域是否已解鎖 |
| `isRegionCompleted(_:)` | 區域是否已完成（Boss 層首通）|
| `isFloorUnlocked(regionKey:floorIndex:)` | 樓層是否可挑戰 |
| `isFloorCleared(regionKey:floorIndex:)` | 樓層是否已首通 |
| `hasSeenBossMaterial(_:)` | Boss 材料是否已見過 |

---

## 刻意先不做的事

- **AdventureView 樓層選擇 UI**：UI 改版留待 Ticket 04
- **首通動畫 / Toast**：視覺回饋留待 UI 工單
- **詳細 sheet / panel**：Boss 材料詳情頁留待後續
- **每日任務 / 成就**：V3 以後

---

## 關鍵決策

**progression 責任與 TaskModel 完全分離：**
`TaskModel` 只負責任務生命週期；首通狀態由 `DungeonProgressionModel` 持有，透過 `SettlementService.markDungeonProgression()` 銜接。

**冪等設計：**
`markFloorCleared()` 在寫入前先檢查 `!cleared.contains(floor.key)`，重刷同一樓層不觸發任何副作用。

**V1 / V2-1 雙軌並存：**
`markDungeonProgression()` 只在 `definitionKey` 對應到 V2-1 `DungeonFloorDef` 時才觸發，V1 任務自動略過。

**AdventureViewModel 保持薄：**
新增的查詢方法皆接受 `service:` 參數，由 View 從 `AppState.progressionService` 傳入。ViewModel 不持有 Service。

---

## 下一張工單

**Ticket 04**：V2-1 冒險頁（AdventureView）重構，接入 DungeonProgressionService 驅動區域 / 樓層的可見性、可挑戰狀態、首通標記顯示。
