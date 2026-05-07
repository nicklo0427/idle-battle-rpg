# V10-1 T07 — 裝備引導 & 冒險解鎖

## 狀態：✅ 已完成

## 目標

教程第三步：引導玩家裝備武器後，解鎖「冒險」Tab。

## 設計

- `onboardingStep == 3`：角色頁顯示「裝備武器」引導 Section
- 玩家點擊「裝備起始短劍」後 → `onboardingStep = 4`（解鎖冒險 Tab）
- ContentView：`onboardingStep < 4` 時隱藏冒險 Tab（僅顯示「生產」「角色」）

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Models/DatabaseSeeder.swift` | `backfillOnboardingStep` 門檻改為 `< 8`，目標設為 `8` |
| `Views/ContentView.swift` | `onboardingStep < 4` 時隱藏冒險 Tab |
| `Views/CharacterView.swift` | Step 3 引導 Section：一鍵裝備武器 |

## 驗收

1. 新玩家：冒險 Tab 隱藏，角色頁顯示裝備引導
2. 舊存檔：`backfillOnboardingStep` 直接設 step=8，跳過所有教程
3. 裝備武器後冒險 Tab 出現
