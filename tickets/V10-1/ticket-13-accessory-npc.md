# V10-1 T13 — 飾品師 NPC（AccessorySheet）

## 狀態：✅ 已完成

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

## NPC 圖片 Prompt（npc_jeweler.webp，128×128）

```
An older male jeweler NPC bust portrait, small and sharp-eyed, wearing a jeweler's
loupe on a headband, dark quilted vest over a plain shirt, holding a glowing amulet
up to examine it, expression calculating and mysterious, deep purple and gold color
palette, can include a small display of rings or pendants on the side.
Flat design illustration, solid color shapes, no outlines, no linework, clean
cartoon style, mobile game icon art, vibrant colors, simple geometric shapes,
minimal shading, transparent background, square crop, WebP format, 128x128 pixels.

Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry,
watermark, text, gradients
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `static let jeweler = "jeweler"` ✅ |
| `StaticData/NpcIntroDef.swift` | 新增 jeweler 條目（defaultName: "飾品師"） ✅ |
| `Views/AccessorySheet.swift`（新增）| `.accessory` slot 配方列表；複用 ArmorSheet 架構 ✅ |
| `Views/BaseView.swift` | `npcJewelerCard(player:)`；加至 `npcProduceSection`（step >= 3） ✅ |
| `Services/TaskCreationService.swift` | `createAccessoryCraftTask(recipeKey:)`（actorKey=jeweler） ✅ |

## 驗收

1. 職業選擇後生產 Tab 出現「飾品師」卡片
2. 點開 AccessorySheet 顯示所有 `.accessory` slot 配方
3. 委派後卡片顯示「鑄造中」狀態
4. 結算後飾品裝備入背包，可裝備
5. NPC 首次對話流程正常（NpcIntroSection）
6. 不影響鑄造師（blacksmith）和鍛造學徒（weaponsmith）任務槽位
