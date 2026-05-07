# V10-1 T13 — 飾品師 NPC（AccessorySheet）

## 狀態：🔲 待實作

## 目標

新增「飾品師」NPC（actorKey: `jeweler`），專門鑄造 `.accessory` slot 裝備。
教程完成後（`onboardingStep >= 3`）即出現在生產 Tab，無教程門檻。

## 設計

- actorKey: `jeweler`
- 預設名: `飾品師`
- 顯示條件：`onboardingStep >= 3`（職業選擇後立即可見）
- 台詞：「珠寶？不，我做的是戰鬥飾品。攻擊、防禦、生命——看你需要什麼，我替你鑲嵌。」
- 無升級系統（留後續版本）
- 專屬 Sheet：`AccessorySheet`（複用 ArmorSheet 架構，filter `.accessory` slot）
- 任務使用獨立 actorKey（不共用 blacksmith slot）

## NPC 圖片 Prompt（npc_jeweler.webp，512×512）

```
Fantasy idle RPG NPC portrait, pixel-art-inspired digital painting style.
Consistent with existing NPC art: warm lighting, bust portrait (waist-up),
slightly stylized proportions, expressive face, clean line art with soft shading.

Character: Older male jeweler/enchanter, early 60s, small and sharp-eyed.
Wearing a jeweler's loupe on a headband, a dark quilted vest over a plain shirt.
Holding a glowing amulet up to the light, examining it with intense focus.
Expression: calculating, mysterious, a hint of mischief — he knows things you don't.
Background: Cluttered shelves of rings, pendants, talismans; small magical glow from enchanted items;
cool blue-purple ambient light mixed with warm candlelight.
Color palette: Deep purples, midnight blue, gold accents on jewelry, cool shadows.
No overly bright or saturated colors.
Output: WebP format, 512×512px, portrait framing.
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `static let jeweler = "jeweler"` |
| `StaticData/NpcIntroDef.swift` | 新增 jeweler 條目（defaultName: "飾品師"，introLine: 上方台詞） |
| `Views/AccessorySheet.swift`（新增）| `.accessory` slot 配方列表；複用 ArmorSheet 架構，無教程 Section |
| `Views/BaseView.swift` | `npcJewelerCard(player:)`；加至 `npcProduceSection`（step >= 3） |
| `Services/TaskCreationService.swift` | `createAccessoryCraftTask(recipeKey:)`（actorKey=jeweler） |

## AccessorySheet 架構

複用 ArmorSheet，差異：
- `availableRecipes` filter：`.slot == .accessory`
- `actorKey: AppConstants.Actor.jeweler`
- 無 tutorialStep Section
- 標題：`player.npcDisplayName(for: "jeweler")`（自訂名 or "飾品師"）

## createAccessoryCraftTask

```swift
func createAccessoryCraftTask(recipeKey: String) throws {
    // 驗證 jeweler 閒置（inProgress 無 actorKey == jeweler 的任務）
    // 查找配方，檢查素材 & 金幣，扣除後建立 .craft TaskModel
    // actorKey: AppConstants.Actor.jeweler
}
```

## 驗收

1. 職業選擇後生產 Tab 出現「飾品師」卡片
2. 點開 AccessorySheet 顯示所有 `.accessory` slot 配方
3. 委派後卡片顯示「鑄造中」狀態
4. 結算後飾品裝備入背包，可裝備
5. NPC 首次對話流程正常（NpcIntroSection）
6. 不影響鑄造師（blacksmith）和副手師（weaponsmith）任務槽位
