# V6-4 Ticket 03：成就系統

**狀態：** ✅ 完成
**版本：** V6-4
**依賴：** V3-1（玩家累計統計）、V2-1（地下城推進）

**修改檔案：**
- `IdleBattleRPG/StaticData/AchievementDef.swift`（新增）
- `IdleBattleRPG/Services/AchievementService.swift`（新增）
- `IdleBattleRPG/Models/AchievementProgressModel.swift`（新增，或整合入 PlayerStateModel）
- `IdleBattleRPG/AppState.swift`
- `IdleBattleRPG/Services/TaskClaimService.swift`
- `IdleBattleRPG/Services/DungeonProgressionService.swift`
- `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

提供玩家長期目標，解鎖成就的同時記錄遊戲里程碑。

## 10 個成就

| Key | 名稱 | 條件 |
|---|---|---|
| first_blood | 第一滴血 | 贏得 1 場戰鬥 |
| veteran_warrior | 百戰老兵 | 累計勝利 100 場 |
| first_craft | 鑄造起步 | 完成 1 件裝備 |
| equipment_master | 裝備大師 | 累計鑄造 15 件 |
| gold_tycoon | 黃金富豪 | 累計獲得 50,000 金幣 |
| wildland_conqueror | 荒野征服者 | 首通荒野邊境 F4 |
| mine_explorer | 礦坑探索家 | 首通廢棄礦坑 F4 |
| ruins_guardian | 遺跡守誓者 | 首通古代遺跡 F4 |
| abyss_conqueror | 深淵征服者 | 首通沉落王城 F4 |
| legend_hero | 傳奇英雄 | 英雄升至 Lv.20 |

## 架構

```
AchievementDef.all（靜態定義）
    ↓
AchievementService.checkAll()（冪等掃描，條件評估）
    ↓
AchievementProgressModel（持久化已解鎖 keys）
```

**觸發點：**
- `TaskClaimService.claimAllCompleted()` 收下後觸發（battlesWon / goldEarned / itemsCrafted / heroLevel）
- `DungeonProgressionService.markFloorCleared()` 首通後觸發（floorCleared）

## CharacterView UI

- 獨立 Segment「成就」Tab
- 進度顯示：`X / 10`
- 每個成就顯示圖示、標題、說明，已解鎖以金色 `checkmark.seal.fill` 標記

## 驗收標準

- [x] 所有 10 個成就條件正確評估
- [x] `checkAll()` 冪等，重複呼叫不重複解鎖
- [x] CharacterView 成就 Tab 顯示正確解鎖狀態
- [x] `xcodebuild` 通過，無新警告
