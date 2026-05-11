# V10-3 Ticket 04：引導按鈕整合進原生 UI（Steps 0 / 2 / 6 / 7）

## 目標

移除所有引導專屬的捷徑按鈕，讓玩家透過與正常遊戲相同的 UI 操作完成引導。引導期間的「2 秒加速」保留，但由正常按鈕觸發而非引導按鈕。

---

## 影響範圍

### Step 0 — GathererDetailSheet（採集木材）

**現況**
- 獨立引導按鈕「派遣採集（2 秒）」
- 下方同時顯示正常地點列表

**目標**
- 移除 `tutorialDispatchSection`
- 保留氣泡文字說明（HStack bubble，無按鈕）
- 正常地點列表照常顯示
- 使用者點選**任意地點**時，若 `onboardingStep == 0`，內部呼叫 `createTutorialGatherTask()` 而非正常採集任務

**實作決策**：在 `startGather(location:duration:)` 判斷：
```swift
if player?.onboardingStep == 0 {
    try TaskCreationService(context: context).createTutorialGatherTask()
} else {
    // 正常建立採集任務
}
```

**⚠️ 注意**：`createTutorialGatherTask()` 目前硬編碼採集 gatherer_1 + 木材。若玩家點其他地點，體驗上還是採集木材（因為這是引導固定需求），不顯示地點名稱差異。可接受。

---

### Step 2 — CraftSheet（打造初始武器）

**現況**
- 獨立引導按鈕「打造初始武器（2 秒）」
- 下方同時顯示完整配方列表

**目標**
- 移除 `tutorialCraftSection`
- 保留氣泡文字說明（無按鈕）
- 配方列表照常顯示，starter weapon 配方加上 **「推薦」** 標籤（橙色膠囊）
- 使用者點選 starter weapon 配方時，若 `onboardingStep == 2`，內部呼叫 `createTutorialCraftTask()` 而非正常鑄造

**實作決策**：在配方列 row 的點擊處理判斷：
```swift
if player?.onboardingStep == 2, recipe.key == starterWeaponKey {
    try TaskCreationService(context: context).createTutorialCraftTask(for: classDef)
} else {
    // 正常建立鑄造任務
}
```

**視覺提示**：starter weapon row 旁加「推薦」標籤，幫助玩家識別目標配方。

---

### Step 6 — AdventureView（探索金穗之野）

**現況**
- 獨立引導按鈕「金穗之野探索（2 秒）」置於列表頂部
- 下方顯示所有區域（包含尚未解鎖的廢棄礦坑等）

**目標**
- 移除 `tutorialStep6ExploreSection`
- 保留氣泡文字說明（無按鈕）
- 正常地下城列表照常顯示
- 「穀倉前道」（wildland_floor_1）row 加上高亮樣式（橙色邊框或「推薦」標籤）
- 使用者點選 wildland_floor_1 時，若 `onboardingStep == 6`，內部呼叫 `createTutorialExploreTask()` 而非正常地下城任務

**實作決策**：在 `launchFloor()` 判斷：
```swift
if player?.onboardingStep == 6,
   floor.regionKey == "wildland", floor.floorIndex == 1 {
    try TaskCreationService(context: context).createTutorialExploreTask()
} else {
    // 正常建立地下城任務
}
```

---

### Step 7 — TailorSheet（打造初始防具）

**現況**
- 獨立引導按鈕「打造初始防具（2 秒）」
- 下方顯示可用配方列表

**目標**
- 移除 `tutorialCraftArmorSection`
- 保留氣泡文字說明（無按鈕）
- `wildland_armor` 配方 row 加上「推薦」標籤
- 使用者點選 `wildland_armor` 配方時，若 `onboardingStep == 7`，內部呼叫 `createTutorialArmorTask()` 而非正常鑄造

---

## 氣泡文字的去留

移除按鈕後，原本 Section 內的氣泡說明文字（`bubble.left.fill` + 提示語）**保留**，因為它提供情境說明，不造成操作混淆。只是移除「🎯 引導任務」header 和按鈕本身。

調整後每個步驟的 Section 內容：

```
[圓形氣泡圖示] NPC 台詞式說明文字
（無按鈕）
```

---

## 改動檔案

| 檔案 | 改動 |
|---|---|
| `GathererDetailSheet.swift` | 移除 tutorialDispatchSection 按鈕；在 startGather() 插入 step 0 判斷 |
| `CraftSheet.swift` | 移除 tutorialCraftSection 按鈕；在 recipe tap handler 插入 step 2 判斷；starter weapon 加推薦標籤 |
| `AdventureView.swift` | 移除 tutorialStep6ExploreSection；在 launchFloor() 插入 step 6 判斷；floor row 加高亮 |
| `TailorSheet.swift` | 移除 tutorialCraftArmorSection 按鈕；在 recipe tap handler 插入 step 7 判斷；wildland_armor 加推薦標籤 |

---

## 驗證

1. Step 0：開啟 gatherer_1，看到氣泡文字 + 地點列表；點選任一地點 → 2 秒採集任務啟動，然後關閉 Sheet
2. Step 2：開啟鑄造師，看到氣泡文字 + 配方列表（starter weapon 有「推薦」標籤）；點選 starter weapon → 2 秒鑄造任務啟動
3. Step 6：開啟冒險頁，看到氣泡文字 + 地下城列表（穀倉前道有高亮）；點選 → 2 秒探索任務啟動
4. Step 7：開啟裁縫師，看到氣泡文字 + 配方（wildland_armor 有「推薦」）；點選 → 2 秒防具任務啟動
5. 正常模式（step >= 3 / step 已完成）：點選相同按鈕走正常任務建立流程，確認不受影響

## 狀態：✅ 已完成

## 實作後確認

- `GathererDetailSheet`：step 0 已移除獨立引導按鈕，點地點 row 觸發 `createTutorialGatherTask()`。
- `CraftSheet`：step 2 已移除獨立引導按鈕，武器配方 row 觸發 `createTutorialCraftTask(for:)`，基礎武器顯示「推薦」。
- `AdventureView`：step 6 已移除獨立探索按鈕，`wildland_floor_1` row 顯示「推薦」，點該樓層觸發 `createTutorialExploreTask()`。
- `TailorSheet`：step 7 已移除獨立防具按鈕，`wildland_armor` row 顯示「推薦」，點該配方觸發 `createTutorialArmorTask()`。
