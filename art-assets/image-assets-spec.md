# 圖片素材規格表 — 放置英雄 Idle Battle RPG

> 本文件列出所有需要美術素材的位置、尺寸、用途，以及 AI 生成用的 prompt。
> 生成格式：WebP（品質 90）。生成後放入對應 xcassets imageset。

---

## 使用方針

- **風格統一**：像素藝術（pixel art）+ 低多邊形（low-poly）混合，偏暗幻（dark fantasy），16-bit RPG 美感
- **色調對應**：各區域有固定主色（詳見各條目），與程式碼中的 `regionColor()` 一致
- **不使用寫實人物照片**：保持遊戲插畫風

---

## 1. 啟動畫面背景 — Launch Screen

| 欄位 | 值 |
|---|---|
| **用途** | App 啟動時的 Splash 背景 |
| **使用位置** | `project.yml` → `UILaunchScreen`，或 `LaunchBackground.imageset` |
| **Xcode 路徑** | `Assets.xcassets/LaunchBackground.imageset/launch_bg.webp` |
| **尺寸** | 1290×2796 px（iPhone 15 Pro Max @3x）；生成比例 9:16 |
| **主色調** | 深藍 / 金色 |
| **輸出檔** | `art-assets/generated/launch_bg.webp` |

**生成 Prompt：**
```
Dark fantasy idle RPG mobile game splash screen, vertical 9:16 composition.
A lone armored warrior silhouette stands at the entrance of a glowing dungeon portal.
Deep dark blue sky with golden particles floating upward. Ancient stone architecture.
Bottom: misty ground with subtle rune patterns. Top-center: empty space for game title text.
Pixel art meets painterly style, moody atmospheric lighting, no text, no UI elements.
Color palette: deep navy, midnight blue, gold, amber glow.
```

---

## 2. 地下城區域橫幅 — Region Banners

用於 `AdventureView` 各區域卡片 Header（`regionListSection`），目前為純文字，加入橫幅圖提升視覺。

**使用位置**：`AdventureView.swift` → `regionHeader(region:unlocked:completed:expanded:)` 函式內，`HStack` 左側加入 `Image("region_\(region.key)")`

---

### 2-1. 荒野邊境 — Wildland

| 欄位 | 值 |
|---|---|
| **Key** | `wildland` |
| **Xcode 路徑** | `Assets.xcassets/region_wildland.imageset/region_wildland.webp` |
| **尺寸** | 120×60 pt @2x = 240×120 px；生成比例 2:1（3:2 近似）|
| **主色調** | 橙色 / 黃褐 |
| **輸出檔** | `art-assets/generated/region_wildland.webp` |

**生成 Prompt：**
```
Pixel art RPG dungeon region banner, horizontal 2:1 crop, wide panorama.
Wildland frontier: rolling amber grasslands with dead twisted trees, orange sunset sky,
crumbling stone watchtower in the distance. Wolves lurking in tall dry grass.
Warm orange-yellow color palette, dramatic backlit silhouettes.
No text, no UI. Retro 16-bit game art style. Pixel art with dithering.
```

---

### 2-2. 廢棄礦坑 — Abandoned Mine

| 欄位 | 值 |
|---|---|
| **Key** | `abandoned_mine` |
| **Xcode 路徑** | `Assets.xcassets/region_abandoned_mine.imageset/region_abandoned_mine.webp` |
| **尺寸** | 120×60 pt @2x = 240×120 px；生成比例 2:1 |
| **主色調** | 藍灰 / 鐵銹 |
| **輸出檔** | `art-assets/generated/region_abandoned_mine.webp` |

**生成 Prompt：**
```
Pixel art RPG dungeon region banner, horizontal 2:1 crop, wide panorama.
Abandoned mine tunnel entrance: dark cave opening with rusty iron tracks leading into darkness,
broken mine carts, dripping water reflections, pale blue-grey flickering lanterns.
Crystal veins glowing faintly in rock walls. Oppressive atmosphere.
Cool blue-grey steel color palette. No text, no UI. Retro 16-bit pixel art with dithering.
```

---

### 2-3. 古代遺跡 — Ancient Ruins

| 欄位 | 值 |
|---|---|
| **Key** | `ancient_ruins` |
| **Xcode 路徑** | `Assets.xcassets/region_ancient_ruins.imageset/region_ancient_ruins.webp` |
| **尺寸** | 120×60 pt @2x = 240×120 px；生成比例 2:1 |
| **主色調** | 紫色 / 古銅 |
| **輸出檔** | `art-assets/generated/region_ancient_ruins.webp` |

**生成 Prompt：**
```
Pixel art RPG dungeon region banner, horizontal 2:1 crop, wide panorama.
Ancient mystical ruins: collapsed temple pillars with glowing purple arcane runes carved into stone,
giant broken stone face statue, floating magical orbs, ancient altar with violet energy.
Dense jungle vines reclaiming the ruins. Purple-violet moonlight from above.
Rich purple, dark teal, bronze color palette. No text, no UI. Retro 16-bit pixel art.
```

---

### 2-4. 沉落王城 — Sunken City

| 欄位 | 值 |
|---|---|
| **Key** | `sunken_city` |
| **Xcode 路徑** | `Assets.xcassets/region_sunken_city.imageset/region_sunken_city.webp` |
| **尺寸** | 120×60 pt @2x = 240×120 px；生成比例 2:1 |
| **主色調** | 靛藍 / 深海青 |
| **輸出檔** | `art-assets/generated/region_sunken_city.webp` |

**生成 Prompt：**
```
Pixel art RPG dungeon region banner, horizontal 2:1 crop, wide panorama.
Sunken underwater royal city: submerged grand palace towers draped in dark seaweed,
bioluminescent deep sea creatures floating by, ancient stone crown half-buried in sea floor,
eerie indigo water lit from within by cursed blue-violet light, drowned throne visible.
Deep indigo, midnight blue, cyan bioluminescence color palette. No text, no UI. Retro 16-bit pixel art.
```

---

## 3. NPC 立繪 — NPC Portraits

用於 `BaseView.swift` NPC 列表列（`npcGathererRow`、`npcBlacksmithRow`、`npcMerchantRow`），目前顯示 SF Symbol 圖示，改為小型 NPC 頭像。

**使用位置**：各 NPC row 的 `Image(systemName:)` 替換為 `Image("npc_*")`，尺寸 40×40 pt。

---

### 3-1. 採集者 1（伐木工）

| 欄位 | 值 |
|---|---|
| **Key** | `gatherer_1` |
| **Xcode 路徑** | `Assets.xcassets/npc_gatherer_1.imageset/npc_gatherer_1.webp` |
| **尺寸** | 40×40 pt @2x = 80×80 px；生成比例 1:1 |
| **主色調** | 綠色 / 棕色 |
| **輸出檔** | `art-assets/generated/npc_gatherer_1.webp` |

**生成 Prompt：**
```
Pixel art RPG character portrait, 1:1 square, bust shot (head and shoulders).
Male woodcutter NPC: weathered face, green hooded cloak, worn leather armor,
wood axe visible over shoulder, kind but tired eyes, bark-stained gloves.
Fantasy RPG style, warm green-brown palette, simple black outline.
Transparent or solid dark background. Clean pixel art, 32x32 sprite style scaled up.
```

---

### 3-2. 採集者 2（礦工）

| 欄位 | 值 |
|---|---|
| **Key** | `gatherer_2` |
| **Xcode 路徑** | `Assets.xcassets/npc_gatherer_2.imageset/npc_gatherer_2.webp` |
| **尺寸** | 40×40 pt @2x = 80×80 px；生成比例 1:1 |
| **主色調** | 灰色 / 藍灰 |
| **輸出檔** | `art-assets/generated/npc_gatherer_2.webp` |

**生成 Prompt：**
```
Pixel art RPG character portrait, 1:1 square, bust shot (head and shoulders).
Dwarf miner NPC: stout build, coal-dusted face, iron helmet with headlamp, grey reinforced vest,
pickaxe visible, squinting determined eyes, braided beard with small rock clips.
Fantasy RPG style, grey-blue steel palette, simple black outline.
Transparent or solid dark background. Clean pixel art, 32x32 sprite style scaled up.
```

---

### 3-3. 鑄造師（鐵匠）

| 欄位 | 值 |
|---|---|
| **Key** | `blacksmith` |
| **Xcode 路徑** | `Assets.xcassets/npc_blacksmith.imageset/npc_blacksmith.webp` |
| **尺寸** | 40×40 pt @2x = 80×80 px；生成比例 1:1 |
| **主色調** | 橙色 / 鐵灰 |
| **輸出檔** | `art-assets/generated/npc_blacksmith.webp` |

**生成 Prompt：**
```
Pixel art RPG character portrait, 1:1 square, bust shot (head and shoulders).
Blacksmith NPC: muscular build, short dark beard flecked with ash, worn leather apron with burn marks,
orange forge-glow on face, hammer held nearby, confident proud expression, soot on forehead.
Fantasy RPG style, warm orange-grey palette, simple black outline.
Transparent or solid dark background. Clean pixel art, 32x32 sprite style scaled up.
```

---

### 3-4. 商人

| 欄位 | 值 |
|---|---|
| **Key** | `merchant` |
| **Xcode 路徑** | `Assets.xcassets/npc_merchant.imageset/npc_merchant.webp` |
| **尺寸** | 40×40 pt @2x = 80×80 px；生成比例 1:1 |
| **主色調** | 金黃 / 紫色 |
| **輸出檔** | `art-assets/generated/npc_merchant.webp` |

**生成 Prompt：**
```
Pixel art RPG character portrait, 1:1 square, bust shot (head and shoulders).
Merchant NPC: plump cheerful face, wide-brimmed hat with coin pin, rich purple velvet coat,
gold chain necklace, one eye slightly winking, coin bag visible at shoulder, knowing smile.
Fantasy RPG style, gold-purple rich palette, simple black outline.
Transparent or solid dark background. Clean pixel art, 32x32 sprite style scaled up.
```

---

## 4. 英雄立繪 — Hero Portrait

用於 `CharacterView.swift` 英雄屬性 Section 頂部，顯示英雄外觀（隨裝備或等級改變為未來規劃）。

| 欄位 | 值 |
|---|---|
| **Xcode 路徑** | `Assets.xcassets/hero_portrait.imageset/hero_portrait.webp` |
| **尺寸** | 80×80 pt @2x = 160×160 px；生成比例 1:1 |
| **主色調** | 銀色 / 紫色（裝備反光）|
| **輸出檔** | `art-assets/generated/hero_portrait.webp` |

**生成 Prompt：**
```
Pixel art RPG character portrait, 1:1 square, bust shot (head and upper torso).
The player's hero character: young warrior with short silver-white hair, determined sharp eyes,
light steel armor with purple gem embedded in chest plate, glowing sword hilt visible at hip,
heroic expression, slight smile of confidence. Androgynous design suitable for any player.
Fantasy RPG style, silver-purple palette with subtle gold trim, simple black outline.
Transparent or solid very dark background. Clean pixel art, 64x64 sprite style scaled up.
```

---

## 總覽

| # | 名稱 | 輸出檔案 | 比例 | 狀態 |
|---|---|---|---|---|
| 1 | 啟動畫面背景 | `launch_bg.webp` | 9:16 | 待生成 |
| 2 | 荒野邊境橫幅 | `region_wildland.webp` | 3:2 | 待生成 |
| 3 | 廢棄礦坑橫幅 | `region_abandoned_mine.webp` | 3:2 | 待生成 |
| 4 | 古代遺跡橫幅 | `region_ancient_ruins.webp` | 3:2 | 待生成 |
| 5 | 沉落王城橫幅 | `region_sunken_city.webp` | 3:2 | 待生成 |
| 6 | NPC：採集者1 | `npc_gatherer_1.webp` | 1:1 | 待生成 |
| 7 | NPC：採集者2 | `npc_gatherer_2.webp` | 1:1 | 待生成 |
| 8 | NPC：鑄造師 | `npc_blacksmith.webp` | 1:1 | 待生成 |
| 9 | NPC：商人 | `npc_merchant.webp` | 1:1 | 待生成 |
| 10 | 英雄立繪 | `hero_portrait.webp` | 1:1 | 待生成 |

---

## 整合方式（Swift 程式碼）

### Region Banners
```swift
// AdventureView.swift → regionHeader()
Image("region_\(region.key)")
    .resizable()
    .scaledToFill()
    .frame(width: 60, height: 30)
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .opacity(unlocked ? 1.0 : 0.3)
```

### NPC Portraits
```swift
// BaseView.swift → npcGathererRow()
Image("npc_\(def.actorKey)")
    .resizable()
    .scaledToFill()
    .frame(width: 40, height: 40)
    .clipShape(Circle())
```

### Hero Portrait
```swift
// CharacterView.swift → gearSegment 頂部
Image("hero_portrait")
    .resizable()
    .scaledToFit()
    .frame(width: 80, height: 80)
    .clipShape(Circle())
    .overlay(Circle().stroke(Color.purple.opacity(0.4), lineWidth: 2))
```
