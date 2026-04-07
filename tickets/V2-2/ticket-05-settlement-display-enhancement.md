# V2-2 Ticket 05：結算 Sheet 強化裝備顯示 + 已裝備裝備強化入口

**狀態：** ✅ 已完成

**依賴：** Ticket 04（強化 UI 基礎）

---

## 目標

補齊兩個強化流程的顯示缺口：
1. 結算 Sheet 中「掉落裝備」需顯示 `+N` 後綴（雖然掉落時 `enhancementLevel = 0`，未來版本可能有預強化掉落）
2. **已裝備裝備的強化入口**：玩家換裝後想強化目前裝備，需在「裝備 Segment」的裝備槽提供強化入口

> 這兩點在 Ticket 04 未涵蓋（Ticket 04 只處理背包未裝備裝備）

---

## 功能需求

### 1. 裝備 Segment — 已裝備裝備強化入口

目前裝備槽 row 的互動：
- 點整列 → 開啟 `EquipSelectSheet`（換裝）
- 右側 `×` → 卸除

新增：
- 長按裝備 row → 開啟 `EquipmentActionSheet`（ActionSheet 或 contextMenu）
  ```
  武器槽：裂牙獵刃 +2
  ● 更換（開啟 EquipSelectSheet）
  ● 卸除
  ● 強化（需 350 金）← 新增
  ```

**或更簡單方案：** 在裝備槽 row 右側加入「強化」小按鈕（圖示 `hammer`），避免改變現有交互行為：

```
[🗡️ 武器]  裂牙獵刃 +2  ATK +30    [🔨] [×]
```

`[🔨]` 點擊 → 強化確認 Alert（與 Ticket 04 相同流程）

> 建議「小按鈕」方案，改動最小

### 2. 結算 Sheet 裝備掉落行顯示

目前 `SettlementSheet` 顯示掉落裝備名稱，從 `resultCraftedEquipKey` 查 `EquipmentDef.name`。
修改為使用 `EquipmentModel.displayName`（若有實體）或保持現有顯示（掉落時 `enhancementLevel = 0`，無 `+N`）。

**實際影響：** 目前掉落裝備均為 +0，`displayName` 與 `def.name` 相同，無視覺差異。
此項主要是確認資料鏈一致性，避免未來版本引入預強化掉落時出錯。

---

## 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Views/CharacterView.swift` | ✏️ 修改 | 裝備槽 row 加入強化小按鈕（`hammer`）；Alert 狀態管理（可複用 Ticket 04 的 Alert 邏輯）|
| `Views/SettlementSheet.swift` | ✏️ 修改（輕量）| 裝備掉落行確認使用 `def.name`（目前行為），加 comment 說明未來可換 `displayName` |

---

## 驗收標準

- [ ] 裝備 Segment 的已裝備裝備 row 有強化按鈕（🔨 或同等方案）
- [ ] 點擊強化按鈕顯示確認 Alert（費用正確）
- [ ] 強化成功後裝備槽即時顯示 `+N`、戰力即時更新
- [ ] 結算 Sheet 裝備掉落行顯示正確（無回歸）
- [ ] 已裝備 +5 裝備的強化按鈕 disabled 或不顯示
