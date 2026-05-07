# V10-1 T10 — 素材不足引導 & 教程探索

## 狀態：✅ 已完成

## 目標

教程第六步：皮甲師發現素材不足 → 引導玩家去冒險探索 → 一鍵 5 秒探索保底獲得防具素材。

## 設計

- ArmorSheet step 5 Section：點擊「去探索材料」→ `onboardingStep = 6`，`dismiss`，`selectedTab = 1`（0.35s 延遲）
- AdventureView：`tutorialStep6ExploreSection`
  - 顯示條件：`step == 6`，無進行中探索任務
  - 按鈕：`createTutorialExploreTask()`（5 秒出征）
- SettlementService `tutorial_explore` 早返回：
  - `resultDriedHideBundle = 3`、`resultHide = 3`、`resultGold = 30`
  - `player.onboardingStep = 7`

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Views/ArmorSheet.swift` | Step 5 Section：切 Tab + step=6 |
| `Views/AdventureView.swift` | `tutorialStep6ExploreSection` |
| `Services/TaskCreationService.swift` | `createTutorialExploreTask()`（5 秒 `.dungeon` 任務） |
| `Services/SettlementService.swift` | `tutorial_explore` 早返回邏輯 |

## 驗收

1. Step 5 ArmorSheet 顯示素材不足 Section
2. 點擊後切換到冒險 Tab（step → 6）
3. 冒險頁顯示一鍵探索按鈕
4. 5 秒後結算：`driedHideBundle×3`、`hide×3`、`gold+30`，step → 7
