# V2-1 Ticket 04：AdventureView 重構

**狀態：** ✅ 已完成

---

## 目標

重構 `AdventureView`，接入 Ticket 03 建立的 `DungeonProgressionService`，正式呈現 V2-1 的樓層推進結構。

---

## 功能需求

### 區域 / 樓層顯示結構

- 顯示 3 個區域卡片（展開 / 收合）
- 每個區域卡片展開後，列出該區 4 層
- 未解鎖區域：可見但灰化，顯示解鎖條件（需首通上一區 Boss）
- 未解鎖樓層：可見但灰化，顯示解鎖條件（需首通前一層）

### 每層資訊顯示

| 欄位 | 說明 |
|---|---|
| 層名稱 | 樓層名稱（e.g. 殘木前哨）|
| 首通標記 | 是否已首通（✓ / 未通關）|
| 推薦戰力 | 與目前戰力對比 |
| Boss 標記 | 第 4 層顯示 Boss 名稱 |
| 解鎖部位 | 首通可解鎖的裝備部位 |

### 出征 Sheet / Panel

點擊某層後開啟詳細 sheet，顯示：

- 掉落表 + 機率 %
- 推薦戰力 vs 目前戰力
- 可選時長（15 分 / 1 小時 / 8 小時）
- 首通解鎖裝備預覽
- 出發按鈕（進行中時 disabled）

---

## 實作規範

### 資料來源

- 區域 / 樓層靜態資料：`DungeonRegionDef.all`
- 推進狀態：`AppState.progressionService`（由 View 傳入 ViewModel）
- 出征任務狀態：`@Query TaskModel`（現有機制）

### 分層責任

- **View**：讀 ViewModel 資料、呼叫 ViewModel 方法
- **AdventureViewModel**：組合靜態資料 + 推進狀態，產出 UI 所需 struct；委派出征建立給 `TaskCreationService`
- **DungeonProgressionService**：只做查詢，不持有 UI 狀態

### 不做的事

- 首通動畫（留後續）
- Boss 材料詳情 modal（留後續）
- V1 `DungeonAreaDef` 相關 UI（本工單全面改用 V2-1 樓層結構）

---

## 驗收標準

- [ ] 3 個區域正確顯示，未解鎖區域灰化並顯示解鎖條件
- [ ] 每區 4 層正確顯示，未解鎖樓層灰化
- [ ] 已首通樓層有標記
- [ ] 點擊可挑戰樓層可開啟出征 Sheet
- [ ] 出征中按鈕 disabled，顯示倒數
- [ ] 首通後 `DungeonProgressionService` 狀態即時反映至 UI
