# V10-1 T14 — 裁縫師 NPC（TailorSheet）

## 狀態：✅ 已完成

## 目標

新增「裁縫師」NPC（actorKey: `tailor`），專門鑄造 `.armor` slot 裝備。
教程完成後（`onboardingStep >= 3`）即出現在生產 Tab，無教程門檻。
與皮甲師（armorer）使用不同任務槽，可同時委派。

## 設計

- actorKey: `tailor`
- 預設名: `裁縫師`
- 顯示條件：`onboardingStep >= 3`（職業選擇後立即可見）
- 台詞：「皮料、布料、鏈環——什麼材料我都能用。想要輕盈的還是厚實的？說出需求，我替你量身裁製。」
- 無升級系統（留後續版本）
- 專屬 Sheet：`TailorSheet`（複用 ArmorSheet 架構，filter `.armor` slot）
- 任務使用獨立 actorKey，不與皮甲師（armorer）衝突
- 卡片主色：teal（青綠）

## NPC 圖片 Prompt（npc_tailor.webp，128×128）

```
A female tailor NPC bust portrait, wearing a neat apron with pockets full of
needles and thread spools, holding a pair of fabric scissors, a half-finished
leather vest visible on the table beside her, warm smile, confident expression,
teal and cream color palette.
Flat design illustration, solid color shapes, no outlines, no linework, clean
cartoon style, mobile game icon art, vibrant colors, simple geometric shapes,
minimal shading, transparent background, square crop, WebP format, 128x128 pixels.

Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry,
watermark, text, gradients
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `static let tailor = "tailor"` ✅ |
| `StaticData/NpcIntroDef.swift` | 新增 tailor 條目（defaultName: "裁縫師"） ✅ |
| `Views/TailorSheet.swift`（新增）| `.armor` slot 配方列表；複用 ArmorSheet 架構，無教程 Section ✅ |
| `Views/BaseView.swift` | `npcTailorCard(player:)`；`showTailorSheet`；加至 `npcProduceSection`（step >= 3） ✅ |
| `Services/TaskCreationService.swift` | `createTailorCraftTask(recipeKey:)`（actorKey=tailor） ✅ |

## 驗收

1. 職業選擇後生產 Tab 出現「裁縫師」卡片（teal 主色）
2. 點開 TailorSheet 顯示所有 `.armor` slot 配方
3. 委派後卡片顯示「製作中」狀態
4. 結算後防具入背包，可裝備
5. NPC 首次對話流程正常（NpcIntroSection）
6. 皮甲師（armorer）與裁縫師（tailor）可同時進行各自任務
