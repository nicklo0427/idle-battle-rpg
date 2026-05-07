# V10-1 T12 — 副手師 NPC（OffhandSheet）

## 狀態：🔲 待實作

## 目標

新增「副手師」NPC（actorKey: `weaponsmith`），專門鑄造 `.offhand` slot 裝備。
教程完成後（`onboardingStep >= 3`）即出現在生產 Tab，無教程門檻。

## 設計

- actorKey: `weaponsmith`
- 預設名: `副手師`
- 顯示條件：`onboardingStep >= 3`（職業選擇後立即可見）
- 台詞：「副手武器嘛，一般人都不重視。但我告訴你，一把好的格擋刃或箭筒，關鍵時刻能救你一命。」
- 無升級系統（留後續版本）
- 專屬 Sheet：`OffhandSheet`（複用 ArmorSheet 架構，filter `.offhand` slot）
- 任務使用獨立 actorKey（不共用 blacksmith slot）

## NPC 圖片 Prompt（npc_weaponsmith.webp，512×512）

```
Fantasy idle RPG NPC portrait, pixel-art-inspired digital painting style.
Consistent with existing NPC art: warm lighting, bust portrait (waist-up),
slightly stylized proportions, expressive face, clean line art with soft shading.

Character: Male weaponsmith specializing in secondary weapons, late 30s, lean and wiry build.
Wearing a leather half-apron over a rolled-sleeve shirt, arm wraps.
Holding a small parry dagger in one hand and inspecting it critically.
Expression: precise, focused, slightly smug — a craftsman proud of overlooked work.
Background: Workshop corner — wall rack of small shields, daggers, quivers, off-hand items,
warm forge glow from the left side.
Color palette: Warm charcoal grays, burnt sienna leather, dull steel glints.
No bright or saturated colors.
Output: WebP format, 512×512px, portrait framing.
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `static let weaponsmith = "weaponsmith"` |
| `StaticData/NpcIntroDef.swift` | 新增 weaponsmith 條目（defaultName: "副手師"，introLine: 上方台詞） |
| `Views/OffhandSheet.swift`（新增）| `.offhand` slot 配方列表；複用 ArmorSheet 架構，無教程 Section |
| `Views/BaseView.swift` | `npcWeaponsmithCard(player:)`；加至 `npcProduceSection`（step >= 3） |
| `Services/TaskCreationService.swift` | `createOffhandCraftTask(recipeKey:)`（actorKey=weaponsmith） |

## OffhandSheet 架構

複用 ArmorSheet，差異：
- `availableRecipes` filter：`.slot == .offhand`
- `actorKey: AppConstants.Actor.weaponsmith`
- 無 tutorialStep Section
- 標題：`player.npcDisplayName(for: "weaponsmith")`（自訂名 or "副手師"）

## createOffhandCraftTask

```swift
func createOffhandCraftTask(recipeKey: String) throws {
    // 驗證 weaponsmith 閒置（inProgress 無 actorKey == weaponsmith 的任務）
    // 查找配方，檢查素材 & 金幣，扣除後建立 .craft TaskModel
    // actorKey: AppConstants.Actor.weaponsmith
}
```

## 驗收

1. 職業選擇後生產 Tab 出現「副手師」卡片
2. 點開 OffhandSheet 顯示所有 `.offhand` slot 配方
3. 委派後卡片顯示「鑄造中」狀態
4. 結算後副手裝備入背包，可裝備
5. NPC 首次對話流程正常（NpcIntroSection）
6. 不影響鑄造師（blacksmith）任務槽位
