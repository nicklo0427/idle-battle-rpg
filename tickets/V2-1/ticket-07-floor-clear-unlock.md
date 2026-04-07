# V2-1 Ticket 07：首通裝備解鎖邏輯

**狀態：** ✅ 已完成

**依賴：** Ticket 03（DungeonProgressionService），Ticket 04（AdventureView 接入推進狀態）

---

## 目標

讓每層首通在遊戲內產生實際回饋：解鎖對應裝備部位的鑄造配方，並在 UI 上明確告知玩家「首通獎勵」。

這是規格 §10.2 的核心：
> 每層首通至少承擔：解鎖新的裝備部位 / 建立該區裝備追求方向

---

## 解鎖對應關係

`DungeonFloorDef` 已有 `unlocksEquipmentKey`（裝備 key）與 `unlocksSlot`（裝備部位）欄位，本 Ticket 讓這兩個欄位正式生效。

| 首通樓層 | 解鎖內容 |
|---|---|
| 荒野邊境 F1 | 前哨護符配方（飾品）|
| 荒野邊境 F2 | 荒徑皮甲配方（防具）|
| 荒野邊境 F3 | 裂角臂扣配方（副手）|
| 荒野邊境 F4 Boss | 裂牙獵刃配方（武器）+ 廢棄礦坑解鎖 |
| 廢棄礦坑 F1 | 礦燈墜飾配方（飾品）|
| …（依此類推）| … |

---

## 功能需求

### 首通解鎖觸發時機

- 地下城任務結算時（`SettlementService.markDungeonProgression()`）
- 已由 Ticket 03 記錄首通狀態，本 Ticket 只需在結算後展示解鎖提示

### 解鎖提示 UI

**選項 A（建議）：結算 Sheet 內新增解鎖行**

在 `SettlementSheet` 的獎勵列表底部，若本次首通，新增：

```
🔓 解鎖鑄造配方：荒徑皮甲
```

**選項 B：Toast**

利用現有 `AppState.showToast()` 機制。較輕量但資訊量少。

### 首通狀態來源

`DungeonProgressionService.isFloorCleared(regionKey:floorIndex:)` 在結算前後各查一次，判斷是否為「本次首通」：

```swift
let wasCleared = progressionService.isFloorCleared(...)
// ... markFloorCleared(...)
let isFirstClear = !wasCleared && progressionService.isFloorCleared(...)
```

---

## 實作規範

### 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Services/SettlementService.swift` | ✏️ 修改 | `markDungeonProgression()` 回傳是否為本次首通（`Bool`）|
| `Models/TaskModel.swift` | ✏️ 修改 | 新增 `resultFirstClearedFloorKey: String?`（首通時填入樓層 key）|
| `ViewModels/SettlementViewModel.swift` | ✏️ 修改 | `makeRewardLines()` 加入首通解鎖行 |
| `Views/SettlementSheet.swift` | ✏️ 修改 | 顯示首通解鎖的裝備名稱 |

### 不做的事

- 動畫（留後續）
- 音效（留後續）
- 成就系統（V3）

---

## 驗收標準

- [ ] 首通某層後，結算 Sheet 顯示「解鎖鑄造配方：XXX」
- [ ] 重刷同一層不再顯示解鎖提示
- [ ] Boss 首通同時顯示：配方解鎖 ＋ 下一區域解鎖（若適用）
- [ ] CraftSheet 內對應配方在首通後出現
