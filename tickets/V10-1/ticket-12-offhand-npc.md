# V10-1 T12 — 鍛造學徒 NPC（OffhandSheet）

## 狀態：✅ 已完成

## 目標

新增「鍛造學徒」NPC（actorKey: `weaponsmith`），專門鑄造 `.offhand` slot 裝備。
教程完成後（`onboardingStep >= 3`）即出現在生產 Tab，無教程門檻。

## 設計

- actorKey: `weaponsmith`
- 預設名: `鍛造學徒`
- 顯示條件：`onboardingStep >= 3`（職業選擇後立即可見）
- 台詞：「師父說我只能做些小件的，什麼盾牌、刀刃之類的。不過我覺得這挺有意思——副手武器關鍵時刻能救你一命，你信嗎？」
- 無升級系統（留後續版本）
- 專屬 Sheet：`OffhandSheet`（複用 ArmorSheet 架構，filter `.offhand` slot）
- 任務使用獨立 actorKey（不共用 blacksmith slot）

## NPC 圖片 Prompt（npc_weaponsmith.webp，128×128）

```
A young male blacksmith apprentice NPC bust portrait, wearing a worn leather
apron over a simple shirt, sleeves rolled up, holding a small parry dagger he
just finished, looking proud but slightly uncertain, warm brown and charcoal
gray color palette, can include a small anvil or tools on the side.
Flat design illustration, solid color shapes, no outlines, no linework, clean
cartoon style, mobile game icon art, vibrant colors, simple geometric shapes,
minimal shading, transparent background, square crop, WebP format, 128x128 pixels.

Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry,
watermark, text, gradients
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `static let weaponsmith = "weaponsmith"` ✅ |
| `StaticData/NpcIntroDef.swift` | 新增 weaponsmith 條目（defaultName: "鍛造學徒"） ✅ |
| `Views/OffhandSheet.swift`（新增）| `.offhand` slot 配方列表；複用 ArmorSheet 架構 ✅ |
| `Views/BaseView.swift` | `npcWeaponsmithCard(player:)`；加至 `npcProduceSection`（step >= 3） ✅ |
| `Services/TaskCreationService.swift` | `createOffhandCraftTask(recipeKey:)`（actorKey=weaponsmith） ✅ |

## 驗收

1. 職業選擇後生產 Tab 出現「鍛造學徒」卡片
2. 點開 OffhandSheet 顯示所有 `.offhand` slot 配方
3. 委派後卡片顯示「鑄造中」狀態
4. 結算後副手裝備入背包，可裝備
5. NPC 首次對話流程正常（NpcIntroSection）
6. 不影響鑄造師（blacksmith）任務槽位
