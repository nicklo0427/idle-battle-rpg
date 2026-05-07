# Icon Style Guide — 放置英雄

> 本指南定義所有要替換 emoji 的圖示的統一規格與風格。
> 各功能區域的 prompt 在實作該功能時才建立對應子資料夾，不提前生成。

---

## 技術規格

| 欄位 | 值 |
|---|---|
| **生成尺寸** | 512 × 512 px |
| **格式** | WebP（透明背景，品質 90）|
| **xcassets 設定** | Single Scale |
| **命名規則** | 與程式碼 key 一致，例如 `icon_outpost_badge.webp` |

> **工作流程**：GPT 生成 PNG → [remove.bg](https://www.remove.bg) 去背 → [Squoosh](https://squoosh.app)（免費，瀏覽器）轉成 WebP 品質 90 → 放入 `art-assets/generated/`。

---

## 視覺風格

- **Flat 2D 遊戲 Icon 風格**（類似 Supercell / 放置手遊道具圖示）
- 顏色數量：**最多 3 種主色**（不含黑色輪廓）
- 無漸層（no gradients）
- 無紋理（no textures）
- 輪廓清晰（clean black outline or no outline）
- 輕微投影（optional: very subtle soft shadow for depth）
- 無文字、無 UI、無品牌標誌

---

## Base Prompt 模板（GPT / DALL-E）

```
Flat 2D game item icon, [物品描述（英文）], 
minimal flat colors, 3 colors maximum, simple geometric shapes, 
no gradients, no textures, clean bold outlines, 
white background, mobile RPG UI icon style, 512x512, 
square composition, centered, no text, no UI elements
```

---

## 各功能區域的 Prompt 檔位置

| 功能 | 子資料夾 | 何時建立 |
|---|---|---|
| 地下城素材 Icon | `prompts/materials/` | 實作 MaterialType 圖片整合時 |
| 裝備 Icon | `prompts/equipment/` | 實作裝備圖示替換時 |
| NPC 頭像 | `prompts/npcs/` | 實作 NPC portrait 時 |
| 地區橫幅 | `prompts/regions/` | 實作 AdventureView 地區圖時 |
| 職業 Icon | `prompts/classes/` | 實作職業選擇畫面圖時 |
| 英雄 / 角色 | `prompts/hero/` | 實作 CharacterView 圖時 |

---

## 色調參考（各地下城地區）

各地區素材圖示應在 base 風格內使用對應色系，以視覺區分地區歸屬：

| 地區 | 主色 |
|---|---|
| 金穗之野（農場） | 橙黃 / 土棕 |
| 暮色古林（森林） | 深綠 / 深棕 |
| 血色曠野（草原） | 磚紅 / 橘 |
| 烈焰沙海（沙漠） | 沙黃 / 橘紅 |
| 採集素材（木材/礦石） | 自然色（棕 / 灰） |
