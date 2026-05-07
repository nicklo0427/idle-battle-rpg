# V9-1 Ticket 06：怪物圖片資源（普通怪 × 12 + 菁英怪 × 16）

**狀態：** 📋 規劃中（本票含 Prompt + 實作說明）

**依賴：** T03 WebP bundle 方案已就位

---

## 目標

每一個非 Boss 樓層各配一張普通怪圖，每個菁英各配一張菁英怪圖。  
Boss 圖（`boss_*_4.webp`）已在 T03 完成，本票不重複。

---

## 資產清單

| 類型 | 數量 | 命名規則 | 範例 |
|---|---|---|---|
| 普通怪 | 12（每區 3 層）| `mob_{prefix}_{index}.webp` | `mob_wildland_1.webp` |
| 菁英怪 | 16（每區 4 層）| `elite_{prefix}_{index}.webp`<br>（= `EliteDef.key` + `.webp`）| `elite_wildland_1.webp` |

prefix 對照：`wildland` / `mine` / `ruins` / `sunken`

---

## Code 查詢方式（待實作）

```swift
// DungeonBattleSheet.swift 或 AdventureView.swift
static func mobImageName(for floorKey: String) -> String? {
    let parts = floorKey.split(separator: "_").map(String.init)
    guard parts.count >= 3, let index = parts.last, Int(index) != nil else { return nil }
    return "mob_\(parts[0])_\(index)"
}
// 菁英：直接用 elite.key 當圖片名
// Image(webp: elite.key)  →  elite_wildland_1.webp
```

---

## 圖片規格

**尺寸：128×128 px，透明底，WebP**  
風格基準（同所有資產）：
```
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

## 普通怪 Prompt（12 張）

### 金穗之野（wildland）｜色調：金黃 / 琥珀

#### `mob_wildland_1`｜穀倉前道
```
A small wild wolf monster bust portrait, snarling fangs, tattered fur,
amber yellow glowing eyes, compact muscular body, golden wheat field creature vibe,
warm amber and earthy brown color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_wildland_2`｜荒廢農舍
```
A corrupted wild boar monster bust portrait, cracked tusks wrapped in dark vine,
matted dirty fur, angry glowing orange eyes, abandoned farm creature vibe,
dark brown, muddy orange and rust color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_wildland_3`｜豐收穀倉
```
A cursed scarecrow monster bust portrait, tattered straw hat, button eyes glowing yellow,
crooked stitched mouth grinning, hay and straw bursting from body, harvest barn guardian vibe,
faded gold, straw yellow and shadow black color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 暮色古林（mine）｜色調：深林綠 / 暗紫

#### `mob_mine_1`｜林道入口
```
A small mischievous forest goblin monster bust portrait, pointy ears, mossy green skin,
wide yellow eyes, leaf-covered head, tiny sharp teeth, forest path ambusher vibe,
forest green and dark moss color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_mine_2`｜古樹迷宮
```
A twisted ancient treant monster bust portrait, gnarled wooden face with hollow glowing eyes,
bark-like skin with vines growing from head, ancient labyrinth guardian vibe,
deep forest brown, sickly green and ghostly grey color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_mine_3`｜幽暗深處
```
A dark shadow wraith monster bust portrait, smoky ethereal form with hollow glowing purple eyes,
wispy dark tendrils where hair should be, menacing void creature vibe,
deep void black, eerie purple and midnight blue color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 血色曠野（ruins）｜色調：深紅 / 青銅

#### `mob_ruins_1`｜草原邊緣
```
A nomadic barbarian warrior monster bust portrait, tribal face paint,
worn leather helmet, fierce expression, crude axe visible at shoulder, grassland raider vibe,
crimson red and dark bronze color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_ruins_2`｜遊牧廢營
```
A nomadic camp raider monster bust portrait, scarred face, makeshift armor from scavenged parts,
war-painted cheeks, aggressive smirk, abandoned camp warrior vibe,
dark iron grey, blood red and burnt sienna color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_ruins_3`｜衝突前線
```
A heavy armored front-line soldier monster bust portrait, full iron battle helmet with visor,
blood-stained shoulder guard, battle-hardened stoic expression, front-line fighter vibe,
dark iron, deep crimson and battle-scarred bronze color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 烈焰沙海（sunken）｜色調：沙金 / 骨白

#### `mob_sunken_1`｜沙丘入口
```
A desert mummy monster bust portrait, wrapped in fraying bandages,
hollow glowing orange eye sockets, sand-dusted cracked wrappings,
dry desert undead rising from sand vibe,
bleached bone white, sandy tan and faded gold color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_sunken_2`｜沙暴迴廊
```
A sandstorm elemental monster bust portrait, swirling sand forming a face with hollow glowing eyes,
wind-whipped sandy body, volatile storm energy, sandstorm corridor creature vibe,
sandy orange, golden yellow and dusty grey color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `mob_sunken_3`｜法老深墓
```
A jackal-headed tomb guardian monster bust portrait, anubis-like dark jackal face,
ceremonial golden collar and headdress, stern divine guardian expression,
deep tomb guardian vibe,
obsidian black, ancient gold and dark sand color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

## 菁英怪 Prompt（16 張）

> 菁英比普通怪更威嚇、更精緻，比 Boss 低一階

### 金穗之野 菁英（wildland）｜穀道裂爪衛 / 田野獵禍首 / 田界收割者 / 穀禍裂牙・狂噬態

#### `elite_wildland_1`｜穀道裂爪衛
```
A scarred veteran barn-path warden elite monster bust portrait, weathered leather farm guard
armor with golden grain emblem on chest, deep claw scars crossing battle-worn face,
stern expression of a soldier who has guarded the harvest road for decades,
golden wheat field sentinel vibe, warm amber, aged leather brown and harvest gold color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_wildland_2`｜田野獵禍首
```
A feral farm-beast trophy hunter elite monster bust portrait, boar tusk and crow feather
trophies hanging from neck, wild beast-marking tattoos covering face earned from hunting
farmland creatures, unhinged grin of an apex predator of the golden fields,
marauding wildland poacher vibe, earthy rust red, beast-tan and dark ochre color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_wildland_3`｜田界收割者
```
A cursed harvest reaper elite monster bust portrait, wide shadowed hat brim, hollow glowing
amber eyes beneath, tattered wheat-straw cloak with dark dried bloodstains,
scythe silhouette visible at shoulder, relentless enforcer who slays any who cross the
field boundary vibe, withered harvest gold, shadow black and burnt amber color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_wildland_4`｜穀禍裂牙・狂噬態
```
An alpha beast overlord in berserk harvest rampage bust portrait, massive predator head with
grain-stained cracked fangs blazing with cursed amber energy, golden wheat chaff and blood
swirling in the rage aura around head, eyes burning with unstoppable frenzy,
destroyer of the golden harvest fields vibe,
blazing amber, furious harvest red and cracked bone color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 暮色古林 菁英（mine）｜林道截殺者 / 迷林古木傀儡 / 幽林靈脈守將 / 腐林吞木獸・狂蝕態

#### `elite_mine_1`｜林道截殺者
```
An elite forest ambush hunter bust portrait, vine-wrapped hood and camouflage bark armor,
sharp predator eyes hidden under shadow, fanged grin, hidden trap setter vibe,
deep forest green, shadow black and mossy brown color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_mine_2`｜迷林古木傀儡
```
An elite ancient wooden puppet monster bust portrait, thousand-year-old tree spirit face
carved into gnarled bark, hollow glowing teal eyes filled with corrupted spirit energy,
cracked wood grain skin with living vines coiling around head, labyrinth guardian vibe,
deep bark brown, ghostly teal and corrupted purple color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_mine_3`｜幽林靈脈守將
```
An elite night beast spirit forest general bust portrait, massive wolf-bear hybrid with
bark-plated armor fused to body, glowing dark purple spirit veins running across face,
commanding snarl, ancient ley line guardian vibe,
midnight black, deep forest green and pulsing purple color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_mine_4`｜腐林吞木獸・狂蝕態
```
An elite corrupted wood-devouring ancient beast in frenzied corrosion mode bust portrait,
enormous maw wide open with thousand-year tree hearts being consumed, rotten wood and dark
sap erupting from cracked hide, eyes blazing with unstoppable decay energy,
frenzied destroyer of the ancient forest throne vibe,
rotting dark green, corroded black and sickly amber color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 血色曠野 菁英（ruins）｜草原前哨斥候長 / 遊牧巫祭首領 / 衝鋒鐵甲統帥 / 血旗戰令者・狂王附體

#### `elite_ruins_1`｜草原前哨斥候長
```
An elite grassland vanguard scout commander bust portrait, lightweight leather scout helmet
with clan feather marking, sharp piercing eyes of a relentless tracker, blood-flag tribal
war paint slashed across cheek, swift raider on horseback vibe,
crimson red, dark leather brown and earthy ochre color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_ruins_2`｜遊牧巫祭首領
```
An elite nomadic shaman chief bust portrait, elaborate bone and feather tribal headdress,
blood ritual tattoos glowing on face, wild feverish eyes channeling war god power,
last shaman of the abandoned warcamp vibe,
deep crimson, bone white and cursed blood red color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_ruins_3`｜衝鋒鐵甲統帥
```
An elite charging iron-plate commander bust portrait, heavy battle-worn full iron helmet
with blood-splattered visor raised, scarred face of an undefeated field marshal,
cavalry charge aura radiating from shoulders, unstoppable grassland warlord vibe,
dark iron grey, deep crimson and battle-scarred bronze color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_ruins_4`｜血旗戰令者・狂王附體
```
An elite blood-flag war decree commander possessed by mad king bust portrait,
crimson tribal war banner erupting behind head, dual personality face split between
disciplined commander and berserk ruler, king's wrathful energy blazing from eyes,
blood-flag grassland king's avatar vibe,
blood crimson, war-banner scarlet and dark iron color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

### 烈焰沙海 菁英（sunken）｜沙丘哨守統領 / 沙暴迴廊祭主 / 法老禁衛統帥 / 焰獄法老・神力覺醒（覺醒態）

#### `elite_sunken_1`｜沙丘哨守統領
```
An elite desert dune sentinel commander bust portrait, sun-bleached pharaoh military helmet
with scorpion crest, hollow glowing amber undead eyes, sun-scorched ceremonial armor,
tireless undead desert warden vibe,
bleached gold, bone white and scorched iron color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_sunken_2`｜沙暴迴廊祭主
```
An elite sandstorm corridor ritual master bust portrait, ancient pharaoh priest with
curse-rune inscribed ceremonial headdress, swirling sand and scorching wind erupting
around face, glowing red cursed eyes, sandstorm summoner vibe,
scorched gold, burning orange and desert sand color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_sunken_3`｜法老禁衛統帥
```
An elite pharaoh royal guard commander bust portrait, magnificent golden ceremonial helmet
with cobra emblem, cold regal undead eyes, pristine ornate tomb guard armor,
last line of defense before the pharaoh's deep tomb vibe,
ancient gold, obsidian black and regal crimson color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

#### `elite_sunken_4`｜焰獄法老・神力覺醒（覺醒態）
```
An elite infernal pharaoh in divine power awakening bust portrait, ancient desert pharaoh
reborn with blazing solar deity energy, cracked golden death mask revealing scorching
flames beneath, desert fire and curse runes erupting from crown and eyes,
awakened god-pharaoh of the scorching sun vibe,
blazing solar gold, hellfire orange and cursed obsidian color palette,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, vibrant colors, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, pencil sketch, photorealistic, 3D render, blurry, watermark, text, gradients
```

---

## 實作計畫

### 步驟 1：生成 + 交付
將 28 張 PNG 放入 `art-assets/generated/`，我來統一轉 WebP + 放入 Resources。

### 步驟 2：Code 改動

#### `DungeonBattleSheet.swift`（新增 helper）
```swift
static func mobImageName(for floorKey: String) -> String? {
    let parts = floorKey.split(separator: "_").map(String.init)
    guard parts.count >= 3, let index = parts.last, Int(index) != nil else { return nil }
    guard Int(index) != 4 else { return nil }  // Boss 樓層用 bossImageName
    return "mob_\(parts[0])_\(index)"
}
```

#### `AdventureView.swift`（floorRow 普通樓層圓圈）
```swift
} else if let imgName = DungeonBattleSheet.mobImageName(for: floor.key) {
    Image(webp: imgName)
        .resizable().scaledToFill()
        .frame(width: 22, height: 22).clipShape(Circle())
        .opacity(0.85)
} else {
    Text("\(floor.floorIndex)")  // fallback
        .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
}
```

#### `BattleLogSheet.swift` + `EliteBattleSheet.swift`（菁英怪圖）
- `enemyImageName` 已支援，只需傳入 `elite.key`（即 `"elite_wildland_1"` 等）

#### `AdventureView.swift`（FloorDetailSheet unlockAndEliteSection）
```swift
// 已有 boss portrait，改為用 elite key
Image(webp: elite.key)
```

### 修改檔案
- `Views/AdventureView.swift`
- `Views/DungeonBattleSheet.swift`
- `Views/BattleLogSheet.swift`（enemyImageName 傳 elite.key）
- `Views/EliteBattleSheet.swift`（enemyImageName 傳 elite.key）
- `IdleBattleRPG/Resources/`（28 張 WebP）
