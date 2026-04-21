# V6-4 Ticket 01：英雄等級上限 10→20 + 技能解鎖擴充

**狀態：** ✅ 完成
**版本：** V6-4
**依賴：** V6-1 職業 / 技能系統

**修改檔案：**
- `IdleBattleRPG/AppConstants.swift`
- `IdleBattleRPG/Services/CharacterProgressionService.swift`
- `IdleBattleRPG/StaticData/SkillDef.swift`
- `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

原本英雄等級上限為 10，無法解鎖 Lv.15 / Lv.20 技能（第 4、第 5 個技能槽）。
本 Ticket 將上限提升至 20，補齊高等技能的成長曲線。

## 數值

`AppConstants.Game.heroMaxLevel = 20`

**技能解鎖等級分佈（每職業 5 個技能）：**

| 等級門檻 | 解鎖技能（範例）|
|---|---|
| Lv.3  | 重擊斬 / 急速連射 / 火球術 / 聖光打擊 |
| Lv.6  | 戰吼 / 穿甲箭 / 冰霜新星 / 神聖護盾 |
| Lv.10 | 旋風斬 / 毒箭 / 雷鏈 / 聖焰爆裂 |
| Lv.15 | 血月斬 / 爆破箭 / 時空裂縫 / 神聖審判 |
| Lv.20 | 死亡打擊 / 致命瞄準 / 流星術 / 天罰 |

## CharacterView UI

- 技能 Tab 顯示「需 Lv.XX」解鎖提示
- 達最高等級時顯示 `Label("已達最高等級 Lv.20")`
- EXP 面板、升級進度條配合 20 級上限運作

## 驗收標準

- [x] `heroMaxLevel = 20`，可升至 20 級
- [x] Lv.15 / Lv.20 技能在對應等級正確解鎖並可裝備
- [x] CharacterView 顯示正確的解鎖門檻與「已達最高等級」提示
- [x] `xcodebuild` 通過，無新警告
