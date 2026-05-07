# V9-1 Ticket 04：圖片資源位置盤點（基地 Tab）

**狀態：** 📋 規劃中（本票為盤點，不含實作）

**依賴：** T03 已完成（WebP bundle 方案已驗證可用）

---

## 目標

盤點基地（`BaseView.swift`、`GathererDetailSheet.swift`）及冒險畫面剩餘位置中，目前以 SF Symbol / emoji 呈現的視覺元素，整理替換方向與 prompt。

---

## 盤點結果

### 🏘️ 基地主畫面（`BaseView.swift`）

#### 採集 Tab — 採集者營地

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 1 | `npcGathererRow()` 左側<br>Line ~337 | `Image(systemName: def.icon)` 綠色（tree.fill / mountain.2.fill / leaf.fill / fish.fill）| 伐木工 / 採礦工 / 採藥師 / 漁夫 | NPC 頭像（32×32 圓形裁切）|
| 2 | `npcFarmerSection()` 左側<br>Line ~519 | `Image(systemName: "leaf.fill")` 綠色 | 農夫 | NPC 頭像（32×32 圓形裁切）|

#### 生產 Tab — 生產者小屋

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 3 | `npcBlacksmithRow()` 左側<br>Line ~398 | `Image(systemName: "hammer.fill")` 橙色 | 鑄造師 | NPC 頭像（32×32 圓形裁切）|
| 4 | `npcChefRow()` 左側<br>Line ~459 | `Image(systemName: "fork.knife")` 紫色 | 廚師 | NPC 頭像（32×32 圓形裁切）|
| 5 | `npcPharmacistRow()` 左側<br>Line ~271 | `Image(systemName: "cross.vial.fill")` 青色 | 製藥師 | NPC 頭像（32×32 圓形裁切）|

#### 商店 Tab

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 6 | `npcMerchantRow()` 左側<br>Line ~554 | `Image(systemName: "storefront.fill")` 黃色 | 商人 | NPC 頭像（32×32 圓形裁切）|

**最高優先：位置 1（採集者 × 4）**，視覺改善最大、NPC 識別度最高。

---

### 🎒 採集者詳細頁（`GathererDetailSheet.swift`）

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 7 | `detailSection` 標題列左側<br>Line 137 | `Image(systemName: npcDef.icon)` 綠色 | 採集者 NPC | 與位置 1 共用同一張 NPC 頭像，顯示稍大（40×40）|
| 8 | `locationRow()` 左側<br>Line ~363 | `Text(location.outputMaterial.icon)` emoji | 採集地點 | 地點縮圖（32×32）——低優先，emoji 已可辨識 |

---

### 🗺️ 冒險畫面剩餘（`AdventureView.swift`）

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 9 | `floorInfoSection` Boss 名稱列<br>Line 545 | `Label(bossName, systemImage: "crown.fill")` 橙色 | Boss | Boss 頭像（24×24）放在名稱左側，與 floorRow 共用同張圖，`crown.fill` 移除 |
| 10 | `unlockAndEliteSection` 菁英名稱列<br>Line 576 | 純文字 `Text(elite.name)` | 菁英 | 與位置 9 共用同一張 Boss 頭像（24×24），不需額外生成 |
| 11 | `activeBannerSection` 出征中左側圖示<br>Line 114 | `Image(systemName: "map.fill")` + pulse | 出征地區 | 地區縮圖（24×24），與 T03 regionHeader 共用同張圖——低優先 |

---

## 圖片規格

| 類型 | Asset 命名 | 顯示尺寸 | 生成尺寸 |
|---|---|---|---|
| NPC 頭像 × 9 | `npc_gatherer_1`、`npc_gatherer_2`、`npc_gatherer_3`、`npc_gatherer_4`<br>`npc_farmer`、`npc_blacksmith`、`npc_chef`、`npc_pharmacist`、`npc_merchant` | 32–40 pt | 128×128 px WebP |

> 位置 9、10、11 不需新圖，直接複用 T03 的 `boss_*_4.webp` 和 `region_*.webp`。

---

## 替換優先順序

1. **位置 1：採集者 × 4**（NPC row 左側）— 角色識別度最高，效果立竿見影
2. **位置 3–5：生產 NPC × 3**（鑄造師、廚師、製藥師）
3. **位置 2、6：農夫、商人**
4. **位置 7：GathererDetailSheet 標題**（共用位置 1 圖，無需額外生成）
5. **位置 9、10：Boss 頭像複用**（已有圖，改實作即可）
6. **位置 8、11**（emoji / region 圖複用）— 低優先

---

## 圖片生成 Prompt

### 風格基準（同 T03）

```
Style: flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors,
simple geometric shapes, minimal shading, transparent background, square crop, WebP format
Negative: outlines, linework, black outline, pencil sketch, detailed texture,
photorealistic, 3D render, blurry, watermark, text, busy background, gradients
```

---

### NPC 頭像（128×128 px，透明底）

#### `npc_gatherer_1`｜伐木工
```
A cheerful lumberjack NPC bust portrait, worn leather vest and suspenders,
red plaid shirt, sturdy woodcutter axe over shoulder, sawdust in hair,
friendly grinning face, forest green and earthy brown color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_gatherer_2`｜採礦工
```
A stout miner NPC bust portrait, yellow hard hat with headlamp, dirt-stained
overalls, pickaxe resting on shoulder, coal dust on cheeks, confident sturdy expression,
stone grey, earthy yellow and dark brown color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_gatherer_3`｜採藥師
```
A wise herbalist NPC bust portrait, wide-brimmed straw hat adorned with herbs and flowers,
green apron with herb pouches, serene gentle smile, holding a bundle of medicinal plants,
forest green, soft lavender and cream color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_gatherer_4`｜漁夫
```
A jolly fisherman NPC bust portrait, weathered fishing hat with lures, ocean-blue
rain jacket, rope coiled over shoulder, big cheerful smile with sun-tanned face,
ocean blue, sandy beige and seafoam green color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_farmer`｜農夫
```
A hardworking farmer NPC bust portrait, wide straw sunhat, denim overalls with
patches, wheat stalk in mouth, rosy cheeks and big friendly smile, holding a
small sprouting seedling, warm golden yellow and earthy green color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_blacksmith`｜鑄造師
```
A burly blacksmith NPC bust portrait, leather apron with burn marks, thick arm guards,
hammer resting on shoulder, forge-lit ruddy face with determined expression,
short beard with sweat on brow, fiery orange and iron grey color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_chef`｜廚師
```
A plump cheerful chef NPC bust portrait, tall white toque blanche hat, purple
neckerchief, double-breasted chef coat with buttons, holding a ladle with
a satisfied grin, warm skin tone, cream white and rich purple color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_pharmacist`｜製藥師
```
A meticulous pharmacist NPC bust portrait, round glasses, teal lab coat with
pockets full of tiny vials, small mortar and pestle visible, focused calm
expression, neat hair pulled back, teal and soft mint green color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `npc_merchant`｜商人
```
A jovial merchant NPC bust portrait, wide velvet traveling hat with a feather,
rich golden-trimmed robe, coin purse visible at belt, one hand gesturing as if
making a deal, warm welcoming smile, golden yellow and deep burgundy color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

## 實作前置作業（不在本 ticket 內）

- [ ] 用上方 prompt 生成 9 張 NPC 頭像，確認風格一致
- [ ] 圖片放入 `IdleBattleRPG/Resources/`，跑一次 `xcodegen generate`
- [ ] 確認命名完全匹配（例如 `npc_gatherer_1.webp`）

---

## 修改檔案（待實作時）

- `Views/BaseView.swift`（位置 1–6：NPC row 左側圖示替換）
- `Views/GathererDetailSheet.swift`（位置 7：detailSection 標題）
- `Views/AdventureView.swift`（位置 9、10：floorInfoSection + unlockAndEliteSection Boss 頭像複用）
