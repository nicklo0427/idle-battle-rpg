# V10-1 T08 — 菁英戰教程（必勝 + 防具配方解鎖）

## 狀態：✅ 已完成

## 目標

教程第四步：引導玩家挑戰荒野邊境菁英，必勝後解鎖「荒徑皮甲」防具配方。

## 設計

- `onboardingStep == 4`：AdventureView 顯示「挑戰菁英」引導橫幅
- FloorDetailSheet：`isTutorialElite == true` 時繞過戰力門檻，允許挑戰
- EliteBattleSheet：tutorial 模式下用 `EliteDef.copying(overrideHP:1, overrideATK:0, overrideDEF:0)` 確保必勝
- 勝利後：`tutorialArmorRecipeUnlocked = true`，`onboardingStep = 5`
- `isTutorialElite`：`step == 4 && regionKey == "wildland" && floorIndex == 1`

## NPC 圖片 Prompt（npc_armorer.webp，512×512）

```
Fantasy idle RPG NPC portrait, pixel-art-inspired digital painting style.
Consistent with existing NPC art: warm lighting, bust portrait (waist-up),
slightly stylized proportions, expressive face, clean line art with soft shading.

Character: Female leatherworker/armorer, mid-30s, sturdy and capable build.
Wearing a thick leather apron over a linen shirt, sleeves rolled up.
Holding a half-finished leather pauldron and inspecting the stitching.
Expression: focused, practical, quietly proud of her craft.
Background: Workshop corner — rolls of hide, tools hanging on the wall,
warm lantern light from the right side.
Color palette: warm browns, deep tans, muted greens, dull metal tools.
No bright or saturated colors.
Output: WebP format, 512×512px, portrait framing.
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Models/PlayerStateModel.swift` | 新增 `tutorialArmorRecipeUnlocked: Bool = false` |
| `StaticData/EliteDef.swift` | 新增 `func copying(overrideHP:overrideATK:overrideDEF:)` |
| `AppState.swift` | `showToast` 改為 internal |
| `Views/AdventureView.swift` | `tutorialStep4BannerSection`；FloorDetailSheet `isTutorialElite` |
| `Views/EliteBattleSheet.swift` | `isTutorialElite` 參數；tutorial 勝利寫入配方解鎖 + step=5 |

## 驗收

1. Step 4：冒險頁顯示菁英挑戰引導
2. 荒野邊境一樓菁英：戰力不足也能挑戰
3. 必勝（HP=1、ATK=0、DEF=0 的弱化版）
4. 勝利後 toast 提示，`tutorialArmorRecipeUnlocked = true`，step=5
