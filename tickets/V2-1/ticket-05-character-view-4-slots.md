# V2-1 Ticket 05：CharacterView 4 部位裝備槽

**狀態：** ✅ 已完成

---

## 目標

將 `CharacterView` 的裝備欄從 V1 的 3 部位（武器 / 防具 / 飾品）擴充為 V2-1 的 4 部位，加入副手（`.offhand`）槽位，讓玩家可以裝備 / 卸除地下城掉落的副手裝備。

`.offhand` 已在 Ticket 01 加入 `EquipmentSlot` 與 `EquipmentDef`，本 Ticket 只做 UI 層接入。

---

## 功能需求

### 裝備槽顯示順序

```
武器
副手
防具
飾品
```

（由攻擊 → 輔助 → 防禦排列，符合視覺習慣）

### 副手槽行為

- 與其他三個槽完全一致：
  - 有裝備 → 顯示裝備名稱 + 屬性加成 + 右側 `×` 卸除按鈕
  - 無裝備 → 顯示「空槽」提示
  - 點擊整列 → 開啟 `EquipSelectSheet`（篩選 `.offhand` 部位未裝備裝備）
- 背包中 `.offhand` 裝備顯示於「背包」Segment 的未裝備列表

---

## 實作規範

### 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Views/CharacterView.swift` | ✏️ 修改 | 裝備槽列表加入 `.offhand`；`EquipSelectSheet` 已支援任意 slot，無需改動 |

### 戰力即時更新

`HeroStatsService.compute(player:equipped:)` 已支援任意 `EquipmentSlot`，副手裝備後戰力自動更新，無需額外修改。

### `EquipmentSlot` 顯示順序

建議在 `EquipmentSlot` 加入 `var displayOrder: Int` 或直接在 View 定義固定陣列：

```swift
let slotOrder: [EquipmentSlot] = [.weapon, .offhand, .armor, .accessory]
```

---

## 驗收標準

- [ ] CharacterView 裝備 Segment 顯示 4 個槽位（武器 / 副手 / 防具 / 飾品）
- [ ] 副手槽空時顯示空槽提示
- [ ] 點擊副手槽開啟 EquipSelectSheet，僅列出 `.offhand` 裝備
- [ ] 裝備副手後戰力即時更新
- [ ] 點擊 `×` 可卸除副手裝備
- [ ] 背包 Segment 正確顯示未裝備的副手裝備
