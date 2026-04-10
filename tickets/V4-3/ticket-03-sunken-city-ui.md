# V4-3 Ticket 03：沉落王城 UI 整合

**狀態：** 🔲 待實作

**依賴：** T02 沉落王城靜態資料、V4-2 T05 FloorDetailSheet 菁英整合

---

## 目標

將沉落王城區域整合至 AdventureView，確保新區域卡片、樓層解鎖、菁英按鈕、掉落表全部正常運作。

---

## 修改檔案

`Views/AdventureView.swift`

---

## 確認事項

以下功能已透過 V4-2 的通用實作覆蓋，**不需要額外程式碼**，只需確認新靜態資料正確接上：

| 功能 | 確認點 |
|---|---|
| 區域卡片 | `DungeonAreaDef.all` 包含 `sunken_city` → 自動顯示 |
| 解鎖門檻 | `isFloorUnlocked()` 依 `ruins_floor_4` elite cleared 判斷 |
| 樓層列表 | `sunken_city` 的 floors 正確渲染 |
| 菁英按鈕 | `EliteDef.find(floorKey:)` 找到沉落王城 4 個菁英 |
| 配方解鎖 | `CraftRecipeDef.available()` 依樓層 key 過濾 |

---

## 沉落王城色調（V4-5 T01 預留）

區域主題色 `.indigo` 在 V4-5 T01 統一實作，此 ticket 不需要處理。

---

## 解鎖入口

沉落王城的解鎖條件：古代遺跡第 4 層菁英（`ruins_floor_4`）已通關。

AdventureView 對於「區域已鎖定」的顯示邏輯：

```swift
// 沉落王城區域卡片：若 ruins_floor_4 elite 未通關，顯示鎖定狀態
if !progressionService.isEliteCleared(floorKey: "ruins_floor_4") {
    // 顯示鎖定樣式（灰色 overlay + 鎖頭圖示）
}
```

---

## 測試清單（手動驗證）

- [ ] AdventureView 顯示沉落王城區域卡片
- [ ] 初始狀態：沉落王城鎖定（古代遺跡 ruins_floor_4 菁英未通關）
- [ ] 古代遺跡 ruins_floor_4 菁英通關後：沉落王城解鎖
- [ ] 進入沉落王城：sunken_floor_1 可出征（第一層預設解鎖）
- [ ] sunken_floor_2 鎖定，挑戰 sunken_floor_1 菁英後解鎖
- [ ] 掉落表正確顯示（sunkPalaceRubble 等新素材）
- [ ] 配方在鑄造師處隱藏，首通對應樓層後顯示

---

## 驗收標準

- [ ] 沉落王城在 AdventureView 正確顯示
- [ ] 解鎖機制與其他區域行為一致
- [ ] 菁英挑戰按鈕在沉落王城 4 個樓層正確運作
- [ ] 無 compile error
