# V9-1 Ticket 05：冒險分頁 UI Icon 與圖片補強

**狀態：** 📋 規劃中

**依賴：** T03（region / boss WebP 已就位）、T04（實作完成）

---

## 目標

盤點冒險主畫面（`AdventureView`）與冒險準備畫面（`FloorDetailSheet`）中，
尚未使用圖片或可以改善 SF Symbol 選擇的位置。

---

## 盤點結果

### 已完成（T03 / T04，僅供對照）

| 位置 | 狀態 |
|---|---|
| regionHeader 地區縮圖 | ✅ |
| floorRow Boss 圓圈頭像 | ✅ |
| floorInfoSection Boss 頭像 | ✅ |
| unlockAndEliteSection 菁英頭像 | ✅ |

---

### A 群：無需新圖，複用現有 WebP

| # | 畫面 | 位置 | 目前 | 改法 |
|---|---|---|---|---|
| 1 | AdventureView<br>`activeBannerSection` | 出征中 Banner 左側<br>Line 114 | `map.fill` + pulse + 區域色 | `Image(webp: "region_\(regionKey)")` 32×32，圓角 8，搭配 `.overlay` 加 pulse 光圈效果或保留 pulse 在外層 |
| 2 | FloorDetailSheet<br>`launchSection` | 出征中狀態左側<br>Line 670 | `map.fill` + pulse + 區域色 | `Image(webp: "region_\(floor.regionKey)")` 32×32，圓角 8 |

> 位置 1、2 直接用現有 `region_*.webp`，不需生成新圖，只改 code。

---

### B 群：SF Symbol → 客製 WebP Icon

| # | 畫面 | 位置 | 目前 | 改法 | Asset 名稱 | 顯示尺寸 |
|---|---|---|---|---|---|---|
| 3 | AdventureView<br>`floorRow` | 出征中樓層右側<br>Line 335 | `text.alignleft`（caption）| WebP icon | `icon_march` | 16×16 pt |
| 4 | AdventureView<br>`floorRow` | 推薦戰力文字前<br>Line 313 | 純文字（caption2）| SF Symbol `shield.fill` 保留<br>（caption2 = 11pt，圖片在此尺寸效果差）| — | — |
| 5 | AdventureView<br>`floorRow` | 勝率文字前<br>Line 321 | 純文字（caption2）| SF Symbol `swords` 保留<br>（同上，尺寸過小）| — | — |
| 6 | FloorDetailSheet<br>`unlockAndEliteSection` | 挑戰菁英按鈕<br>Line 616 | `shield.lefthalf.filled` | WebP icon | `icon_elite` | 20×20 pt |
| 7 | FloorDetailSheet<br>`launchSection` | 出發按鈕<br>Line 692 | `paperplane.fill` | WebP icon | `icon_launch` | 20×20 pt |

> 位置 4、5 維持 SF Symbol，因為 caption2（11pt）尺寸下客製圖片比 SF Symbol 更模糊。

---

### B 群 Icon Prompt（生成尺寸：64×64 px WebP，透明底）

#### `icon_march`｜出征中
```
A simple flat icon of a marching warrior silhouette, side profile walking forward
with a sword or spear, single solid warm orange color shape, very clean minimal shape,
no details, transparent background, square crop, WebP format, 64x64 pixels
Negative: outlines, gradients, photorealistic, multiple colors, text, watermark, complex details
```

#### `icon_elite`｜挑戰菁英
```
A simple flat icon of a shield with a lightning bolt symbol centered on it,
single solid deep orange color, very clean bold shape, high contrast,
no details, transparent background, square crop, WebP format, 64x64 pixels
Negative: outlines, gradients, photorealistic, multiple colors, text, watermark, complex details
```

#### `icon_launch`｜出發
```
A simple flat icon of a crossed sword and shield emblem, bold clean shape,
single solid color, vivid adventurer theme, centered composition,
no details, transparent background, square crop, WebP format, 64x64 pixels
Negative: outlines, gradients, photorealistic, multiple colors, text, watermark, complex details
```

---

### C 群：需新圖（各地區怪物 icon）

| # | 畫面 | 位置 | 目前 | 改法 | 備註 |
|---|---|---|---|---|---|
| 8 | AdventureView<br>`floorRow` | 普通樓層圓圈<br>Line 287 | 純數字 `Text(floor.floorIndex)` | 數字保留，背景圓圈內疊加地區主題怪物 silhouette（16×16，半透明）| 需 4 張地區怪物圖，各地區非 Boss 樓層共用同一張 |

#### 位置 8 說明

目前 Boss 樓層有頭像，普通樓層只有灰色數字，視覺落差大。
建議在圓圈背景加半透明怪物剪影，數字仍疊在上方，保持可讀性。

```
ZStack {
    Circle().fill(...)
    Image(webp: "mob_\(region.key)")   // 半透明 silhouette
        .resizable().scaledToFill()
        .frame(width: 22, height: 22).clipShape(Circle())
        .opacity(0.25)
    Text("\(floor.floorIndex)")        // 數字保留
        .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
}
```

---

## 優先順序

| 優先 | 項目 | 工時 |
|---|---|---|
| 🔴 高 | 位置 1、2（region thumbnail 替換 map.fill）| 改 code 10 min |
| 🟡 中 | 位置 3–7（SF Symbol 微調）| 改 code 15 min |
| 🟢 低 | 位置 8（普通樓層怪物 silhouette）| 需生成 4 張新圖 + 改 code |

---

## 位置 8 所需圖片 Prompt

> 生成尺寸：128×128 px WebP，透明底  
> 命名：`mob_wildland`、`mob_abandoned_mine`、`mob_ancient_ruins`、`mob_sunken_city`

#### `mob_wildland`｜荒野一般怪（野獸剪影）
```
A simple flat silhouette of a wild beast monster, wolf or boar shape,
low crouching aggressive stance, single solid color shape,
warm earthy amber color, no details, no texture, pure flat shape,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, multiple colors, gradients, photorealistic, text, watermark
```

#### `mob_abandoned_mine`｜暮色古林一般怪（林中妖精剪影）
```
A simple flat silhouette of a forest spirit monster, small gremlin or sprite shape,
crouching with claws out, single solid color shape,
deep forest purple color, no details, no texture, pure flat shape,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, multiple colors, gradients, photorealistic, text, watermark
```

#### `mob_ancient_ruins`｜血色曠野一般怪（草原戰士剪影）
```
A simple flat silhouette of a nomadic warrior monster, stocky figure with weapon raised,
single solid color shape, deep crimson red color,
no details, no texture, pure flat shape,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, multiple colors, gradients, photorealistic, text, watermark
```

#### `mob_sunken_city`｜烈焰沙海一般怪（沙漠亡靈剪影）
```
A simple flat silhouette of a desert undead monster, mummy or skeleton shape,
arms outstretched, single solid color shape,
bleached bone white or sandy yellow color, no details, no texture, pure flat shape,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, multiple colors, gradients, photorealistic, text, watermark
```

---

## 修改檔案（待實作時）

- `Views/AdventureView.swift`（位置 1、3、4、5、8）
- `Views/AdventureView.swift`（`FloorDetailSheet` 內：位置 2、6、7）
- `IdleBattleRPG/Resources/`（位置 8 新圖，若決定實作）
