# V9-1 Ticket 03：圖片資源位置盤點

**狀態：** 📋 規劃中（本票為盤點，不含實作）

**依賴：** 無

---

## 目標

盤點戰鬥畫面、冒險主畫面、冒險準備畫面中，目前以 SF Symbol / emoji / 純色佔位呈現的視覺元素。
這些位置未來可替換為真實圖片資源（Asset Catalog `.imageset`）。

---

## 盤點結果

### 🗡️ 戰鬥畫面（`BattleLogSheet.swift`）

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 1 | Line 134<br>`heroColumn` 標頭 | `Image(systemName: "person.fill")` 藍色 | 英雄 | 英雄頭像圖（32×32 圓形）|
| 2 | Lines 161–165<br>`enemyColumn` 標頭右側 | `ZStack { RoundedRectangle(26×26) + skull }` 灰色佔位框 | 怪物 / Boss | **已設計為佔位**，直接替換為怪物或 Boss 圖片（26×26）|
| 3 | Line 119<br>`battleVisualsView` 中央 | `figure.fencing`（戰鬥）/ `map.fill`（探索）| 戰鬥/探索狀態指示 | 可替換為自訂交叉劍 / 地圖 icon（低優先）|
| 4 | Lines 301–312<br>`eventIconView()` | 各種 SF Symbol，依事件類型 | 技能、攻擊、治癒、勝敗等 | 可替換為自訂事件圖示（低優先，可能不需要）|

**最高優先替換：位置 2（敵人佔位框）**，架構已預留，圖片尺寸 26×26 pt。

---

### 🗺️ 冒險主畫面（`AdventureView.swift` — regionListSection）

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 5 | Lines 188–190<br>`regionHeader()` 左側 | `lock.fill` / `lock.open.fill` / `checkmark.seal.fill` SF Symbol | 地區解鎖狀態 | 替換為地區縮圖（40×40），解鎖狀態疊加 overlay 而非替換 |
| 6 | Lines 248–264<br>`floorRow()` 左側圓圈 | `ZStack { Circle(30×30) + crown.fill（Boss）/ 樓層數字（普通）}` | 單一樓層 / Boss 樓層 | Boss 樓層：替換為 Boss 頭像（30×30 圓形裁切）；普通樓層：保留數字或加樓層主題圖示 |
| 7 | Lines 113–116<br>`activeBannerSection` 左側 | `map.fill` + symbolEffect(.pulse) | 出征中狀態 | 可替換為對應地區小 icon（低優先）|

**最高優先替換：位置 5（地區縮圖）**，視覺影響最大，每個地區一張圖。

---

### ⚔️ 冒險準備畫面（`AdventureView.swift` — FloorDetailSheet）

| # | 位置 | 目前呈現 | 代表實體 | 替換方向 |
|---|---|---|---|---|
| 8 | Lines 516–518<br>`floorInfoSection` | `Label(bossName, systemImage: "crown.fill")` | Boss 名稱標頭 | 在 Boss 名稱左側加 Boss 頭像（24×24），與 crown icon 二選一 |
| 9 | `unlockAndEliteSection`<br>菁英名稱行 | 純文字 `Text(elite.name)` + 已擊敗 Badge | 地區菁英 | 菁英名稱左側加頭像佔位（24×24），與位置 2 共用同一張圖 |

---

## 圖片規格建議

| 類型 | 尺寸 | Asset 命名建議 |
|---|---|---|
| 地區縮圖 | 40×40 pt（@2x = 80px）| `region_wildland`、`region_mine`、`region_ruins`、`region_sunken` |
| Boss / 菁英頭像 | 26–32×26–32 pt | `boss_<floorKey>`（例如 `boss_wildland_4`）|
| 英雄頭像 | 32×32 pt | `hero_avatar` |

---

## 替換優先順序

1. **位置 2：敵人佔位框**（戰鬥畫面）— 架構已就緒，直接放圖，效果立竿見影
2. **位置 5：地區縮圖**（冒險主畫面 regionHeader）— 視覺改善最大
3. **位置 6：Boss 樓層圓圈**（floorRow）— 搭配地區縮圖一起做
4. **位置 1：英雄頭像**（戰鬥畫面）— 需要設計稿確認風格後再做
5. 其餘位置（事件圖示、出征 Banner 圖示）低優先，SF Symbol 功能足夠

---

## 圖片生成 Prompt

### 風格基準（套用至所有圖片）

```
Style: flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors,
simple geometric shapes, minimal shading, transparent background, square crop, PNG format
Negative: outlines, linework, black outline, pencil sketch, detailed texture,
photorealistic, 3D render, blurry, watermark, text, busy background, gradients
```

---

### 地區縮圖

> UI 顯示：40×40 pt｜Asset Catalog：@1x 40px・@2x 80px・@3x 120px｜**生成尺寸：256×256 px，PNG 透明底**

#### `region_wildland`｜金穗之野
```
A golden wheat farmland landscape icon, rolling fertile fields under warm sunset, 
rustic medieval farmhouse in background, wild beasts lurking at the edge, 
warm golden-orange and amber color palette, harvest festival atmosphere,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 256x256 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `region_abandoned_mine`｜暮色古林
```
A mystical ancient forest landscape icon, towering corrupted old trees at twilight, 
glowing spirit orbs drifting between trunks, dark elven ruins overgrown with vines,
deep forest green, violet purple and moonlight silver color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 256x256 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `region_ancient_ruins`｜血色曠野
```
A vast crimson grassland battlefield landscape icon, nomadic war banners planted 
in scorched earth, blood-red sunset sky, weathered stone ruins on distant horizon,
warriors silhouettes clashing, deep crimson, burnt orange and iron grey palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 256x256 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `region_sunken_city`｜烈焰沙海
```
A scorching desert landscape icon, ancient Egyptian-style cursed ruins half-buried 
in sand, blazing sun overhead, heat haze distortion, pharaoh tomb entrance visible,
golden yellow, fiery orange and bleached bone white color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 256x256 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### Boss 頭像

> UI 顯示：26–32×26–32 pt｜Asset Catalog：@1x 32px・@2x 64px・@3x 96px｜**生成尺寸：128×128 px，PNG 透明底**

#### `boss_wildland_4`｜豐收惡神
```
A menacing corrupted harvest deity monster bust portrait, twisted grain sheaves 
form its crown and claws, glowing malevolent yellow eyes, decayed scarecrow body 
merged with a wrathful spirit, sickle weapon visible, dark ritual markings,
gold and rotted green color palette with deep shadow,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `boss_mine_4`｜千年古林王
```
A massive ancient corrupted forest king monster bust portrait, enormous tree-spirit 
form with gnarled bark skin, hollow glowing purple eyes deep in twisted wood,
dark corrupted vines and thorns erupting from body, ancient crown of dead branches,
deep forest brown, sickly purple and dark moss green palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `boss_ruins_4`｜血旗草原王
```
A fearsome nomadic warlord king bust portrait, battle-scarred face with tribal war paint,
ornate blood-stained bronze battle helmet with horns, fur-lined war cloak,
crimson war banner visible behind him, fierce warrior expression,
crimson red, bronze and dark iron color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `boss_sunken_4`｜不死沙漠法老
```
A terrifying undead pharaoh bust portrait, mummified face with golden ceremonial 
death mask cracked to reveal glowing cursed eyes beneath, tattered royal headdress,
ancient golden breastplate with hieroglyphs, dark desert curse energy emanating,
cracked obsidian, ancient gold and cursed violet color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 英雄頭像

> UI 顯示：32×32 pt｜Asset Catalog：@1x 32px・@2x 64px・@3x 96px｜**生成尺寸：128×128 px，PNG 透明底**

#### `hero_avatar`｜英雄
```
A young brave fantasy adventurer hero bust portrait, determined confident expression,
simple iron adventurer helmet with visor up, modest but sturdy chainmail armor,
sword hilt visible at shoulder, generic yet heroic medieval fantasy protagonist,
blue, silver and warm skin tone color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

## 實作前置作業（不在本 ticket 內）

- [ ] 確認美術風格（平面色塊、無描線、卡通感，詳見上方風格基準）
- [ ] 用上方 prompt 生成圖片，確認風格一致後批量產出
- [ ] 產出地區縮圖 4 張 + Boss 頭像 4 張 + 英雄頭像 1 張
- [ ] 圖片匯入 Asset Catalog，確認 @2x / @3x 規格
- [ ] 確認 Boss floorKey 對應：`wildland_floor_4`、`mine_floor_4`、`ruins_floor_4`、`sunken_floor_4`

---

## 修改檔案（待實作時）

- `Views/BattleLogSheet.swift`（位置 1、2、3）
- `Views/AdventureView.swift`（位置 5、6、7、8、9）
- `Assets.xcassets`（新增 imageset）
