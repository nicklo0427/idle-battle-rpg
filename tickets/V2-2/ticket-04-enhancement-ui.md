# V2-2 Ticket 04：強化 UI（CharacterView 接入）

**狀態：** ✅ 已完成

**依賴：** Ticket 02（displayName +N）、Ticket 03（EnhancementService）

---

## 目標

讓玩家可以在 `CharacterView` 對背包中的裝備進行強化與拆解操作，並即時看到戰力變化。

---

## 功能需求

### 裝備槽（裝備 Segment）

- 已裝備的裝備若 `enhancementLevel > 0`，名稱直接顯示 `+N` 後綴（由 `displayName` 自動處理，不需額外改動）
- 強化等級視覺標示（可選）：在裝備名稱後顯示橙色 `+N` 標籤

### 背包（背包 Segment）— 主要操作入口

未裝備的裝備 row 新增「強化 / 拆解」入口：

**方案：** SwipeActions（左滑 → 拆解；右滑 → 強化）

```
[裂牙獵刃 +2]  ATK +30   [已鑄造]
  右滑 → 強化（橙色）：顯示「強化 +3 需 350 金」確認按鈕
  左滑 → 拆解（紅色）：顯示「拆解退還 300 金」確認按鈕
```

**或：** 點擊 row 開啟 `EquipmentActionSheet`（與目前「點選裝備」行為衝突，需調整）

> 建議用 **SwipeActions**，不改變點擊=裝備的現有行為

### EquipmentActionSheet（可選，若 SwipeActions 空間不足）

若 SwipeActions 難以實作，改為點擊未裝備裝備 row 顯示 ActionSheet：
```
「裂牙獵刃 +2」
● 裝備
● 強化（需 350 金）
● 拆解（退還 300 金）
● 取消
```

---

## 強化確認流程

1. 玩家滑動 / 選擇強化
2. Alert 顯示：
   ```
   強化 裂牙獵刃 至 +3
   消耗：350 金幣
   目前金幣：XXX
   [確認] [取消]
   ```
3. 確認後：`enhancementService.enhance(equipment:player:)` → 成功即時更新 UI

**已達滿強化（+5）：** 強化 SwipeAction / 選項 disabled，不顯示

### 拆解確認流程

1. 玩家滑動 / 選擇拆解
2. Alert 顯示：
   ```
   確認拆解 裂牙獵刃 +2？
   退還：300 金幣（強化費用不退）
   此操作不可復原。
   [確認拆解] [取消]
   ```
3. 確認後：`enhancementService.disassemble(equipment:player:)` → 裝備消失、金幣更新

---

## 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Views/CharacterView.swift` | ✏️ 修改 | 背包 Segment 的裝備 row 加入 SwipeActions（強化 / 拆解）；Alert 狀態管理 |
| `ViewModels/CharacterViewModel.swift` | ✏️ 修改 | 新增 `enhance(equipment:context:)` / `disassemble(equipment:context:)` 委派方法；error → message 轉換 |

---

## 不做的事

- 強化動畫 / 粒子特效
- 批次強化（全強化按鈕）
- 強化預覽（+3 後戰力將達 XXX）：可選，若實作簡單可加，否則跳過

---

## 驗收標準

- [ ] 背包裝備 row 支援右滑強化、左滑拆解（或 ActionSheet 替代方案）
- [ ] 強化確認 Alert 正確顯示等級、金幣費用、目前金幣
- [ ] 強化成功後 `displayName` 即時顯示 `+N`，戰力即時更新
- [ ] 已達 +5 時，強化選項 disabled 或不顯示
- [ ] 拆解確認 Alert 顯示退還金幣，並說明不可復原
- [ ] 拆解成功後裝備消失、金幣入帳
- [ ] 已裝備的裝備（裝備 Segment）無拆解選項
- [ ] 錯誤（金幣不足等）以 Alert 顯示，不 crash
