# V10-1 T11 — 教程防具打造完成

## 狀態：✅ 已完成

## 目標

教程最終步驟：引導玩家打造初始防具，完成後發放「荒徑皮甲」（精良防具，自動裝備）。

## 設計

- ArmorSheet step 7 Section：「打造初始防具（5 秒）」按鈕 → `createTutorialArmorTask()`
- SettlementService `tutorial_armor` 早返回：
  - `EquipmentService.grantTutorialArmor()`（wildland_armor, .refined, isEquipped: true）
  - `player.onboardingStep = 8`（教程完成）
- `DatabaseSeeder.backfillOnboardingStep`：舊存檔 step < 8 直接升至 8

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Views/ArmorSheet.swift` | Step 7 Section：教程打造按鈕 |
| `Services/TaskCreationService.swift` | `createTutorialArmorTask()`（5 秒 `.craft` 任務，actorKey=armorer） |
| `Services/SettlementService.swift` | `tutorial_armor` 早返回邏輯 |
| `Services/EquipmentService.swift` | `grantTutorialArmor()` |
| `Models/DatabaseSeeder.swift` | `backfillOnboardingStep` 目標改為 8 |

## 驗收

1. Step 7 ArmorSheet 顯示教程打造按鈕
2. 5 秒後結算：背包出現「荒徑皮甲」（精良，已裝備）
3. `onboardingStep = 8`，後續不再顯示任何教程 Section
4. 舊存檔：`backfillOnboardingStep` 確認 step 直接到 8
