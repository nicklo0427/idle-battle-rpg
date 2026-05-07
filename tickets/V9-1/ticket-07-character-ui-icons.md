# V9-1 Ticket 07：角色頁面 SF Symbol → 客製 Icon

**狀態：** 📋 規劃中

**依賴：** T06 WebP bundle 方案已就位

---

## 目標

角色頁面中所有有意義的 SF Symbol 全部替換為客製 WebP icon。
小到 14pt 的屬性列也照換，全面統一視覺語言。

---

## 盤點結果

### A 群：職業徽章（4 張）

| # | 位置 | 目前 | 改法 | Asset 名稱 | 顯示尺寸 |
|---|---|---|---|---|---|
| 1 | 職業徽章 36×36 Circle 內<br>Line 209 | `classDef.iconName`（4 種 SF Symbol）| `Image(webp: "class_\(classDef.key)")` | `class_swordsman`<br>`class_archer`<br>`class_mage`<br>`class_paladin` | 24×24 pt |

---

### B 群：英雄基本資訊列（2 張）

目前 `infoRow(label:value:)` 只有文字，無 icon。需新增 `iconInfoRow` variant。

| # | 位置 | 目前 | 改法 | Asset 名稱 | 顯示尺寸 |
|---|---|---|---|---|---|
| 2 | 等級列 Line 238 | 純文字 label「等級」| `iconInfoRow` + WebP | `icon_level` | 16×16 pt |
| 3 | 金幣列 Line 239 | 純文字 label「金幣」| `iconInfoRow` + WebP | `icon_gold` | 16×16 pt |

---

### C 群：屬性分配列（5 張）

`statAllocRow(icon:)` 目前接受 SF Symbol name，改為接受 WebP name。

| # | 屬性 | 目前 Symbol | 新 Asset 名稱 |
|---|---|---|---|
| 4 | ATK | `figure.fencing` | `attr_atk` |
| 5 | DEF | `shield.fill` | `attr_def` |
| 6 | HP | `heart.fill` | `attr_hp` |
| 7 | AGI | `figure.run` | `attr_agi` |
| 8 | DEX | `scope` | `attr_dex` |

---

### D 群：累計統計列（移除）

> 預計整個統計列區塊從 CharacterView 移除，不需要 icon，也不需要圖片。

---

### E 群：其他（保留）

| 位置 | 不換原因 |
|---|---|
| 背包 Swipe 動作（hammer / trash）| 系統 swipeAction，symbol 不可換 |
| lock.fill / checkmark.seal 等多處 | 純狀態裝飾，caption 尺寸，SF Symbol 更適合 |
| EquipSelectSheet 屬性比較 10–11pt | 過小 |
| 技能點 badge、空技能槽 + | 過小或純裝飾 |

---

## 所需 Assets 總計：10 張

> 生成尺寸：128×128 px WebP，透明底

| Asset 名稱 | 用途 |
|---|---|
| `class_swordsman` | 劍士職業徽章 |
| `class_archer` | 弓手職業徽章 |
| `class_mage` | 法師職業徽章 |
| `class_paladin` | 聖騎士職業徽章 |
| `icon_level` | 等級列 icon |
| `icon_gold` | 金幣列 |
| `attr_atk` | ATK 屬性列 |
| `attr_def` | DEF 屬性列 |
| `attr_hp` | HP 屬性列 |
| `attr_agi` | AGI 屬性列 |
| `attr_dex` | DEX 屬性列 |

---

## 圖片 Prompt（生成尺寸：128×128 px WebP，透明底）

### A 群：職業徽章

> 以職業標誌性武器／副手為主體，無人物，無性別。

#### `class_swordsman`｜劍士（主手：闊劍 + 副手：盾牌）
```
A class emblem badge icon: a circular badge with a dark crimson red background,
a broad silver-grey sword pointing diagonally upward on the left and a round iron shield on the right,
arranged symmetrically inside the badge, small golden trim accent on the badge border,
multi-color: dark crimson badge, silver blade, iron shield, gold trim,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, character, person, face, photorealistic, 3D render, watermark, text, gradients
```

#### `class_archer`｜弓手（主手：弓 + 副手：箭袋）
```
A class emblem badge icon: a circular badge with a deep forest green background,
a light wooden recurve bow on the left and a brown leather quiver with golden arrow tips on the right,
arranged symmetrically inside the badge, earthy tan trim accent on the badge border,
multi-color: deep green badge, tan wood bow, brown quiver, golden arrow tips, earthy border,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, character, person, face, photorealistic, 3D render, watermark, text, gradients
```

#### `class_mage`｜法師（主手：法杖 + 副手：魔法書）
```
A class emblem badge icon: a circular badge with a deep indigo purple background,
a dark wooden wizard staff topped with a glowing cyan-blue orb on the left,
and a closed dark grimoire tome with a glowing teal rune symbol on the cover on the right,
arranged symmetrically inside the badge, silver arcane trim on the badge border,
multi-color: indigo badge, dark wood staff, glowing cyan orb, dark tome, teal rune, silver border,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, character, person, face, photorealistic, 3D render, watermark, text, gradients
```

#### `class_paladin`｜聖騎士（主手：聖錘 + 副手：聖盾）
```
A class emblem badge icon: a circular badge with a royal navy blue background,
a golden holy warhammer on the left and a kite shield with a bold gold cross emblem on the right,
arranged symmetrically inside the badge, bright gold trim on the badge border,
multi-color: navy blue badge, gold warhammer head, silver handle, gold-cross shield, bright gold border,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, character, person, face, photorealistic, 3D render, watermark, text, gradients
```

---

### B 群：基本資訊列

#### `icon_level`｜等級
```
A simple flat icon of a glowing upward arrow with a star burst at the tip,
representing hero level up, single vivid gold yellow color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

#### `icon_gold`｜金幣（B3 + D9 共用）
```
A simple flat icon of a shiny gold coin with a subtle shine mark,
single vivid warm gold color, clean round coin shape,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

---

### C 群：屬性列

#### `attr_atk`｜攻擊力
```
A simple flat icon of a single sharp sword pointing upward, bold clean blade shape,
vivid crimson red color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

#### `attr_def`｜防禦力
```
A simple flat icon of a round shield with a centered emblem, bold clean shield shape,
vivid steel blue color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

#### `attr_hp`｜生命值
```
A simple flat icon of a bold heart shape with a subtle inner glow,
vivid warm red or pink color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

#### `attr_agi`｜敏捷（ATB速度）
```
A simple flat icon of a swift wind whoosh arc or lightning speed lines forming a motion blur,
representing agility and ATB speed, vivid teal green color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

#### `attr_dex`｜靈巧（暴擊率）
```
A simple flat icon of a bullseye target with a centered dot, representing precision and
critical hit rate, vivid orange amber color,
flat design illustration, solid color shapes, no outlines, no linework,
clean cartoon style, mobile game icon art, simple geometric shapes, minimal shading,
transparent background, square crop, WebP format, 128x128 pixels
Negative: outlines, linework, photorealistic, 3D render, watermark, text, gradients
```

---

## Code 修改計畫

### 1. 職業徽章（Line 209）

```swift
// 原：
Image(systemName: classDef.iconName)
    .font(.system(size: 16, weight: .semibold))
    .foregroundStyle(classDef.themeColor)

// 改：
Image(webp: "class_\(classDef.key)")
    .resizable()
    .scaledToFit()
    .frame(width: 24, height: 24)
```

`ClassDef.swift` 的 `iconName` computed property 可移除。

---

### 2. 等級 / 金幣列（Lines 238–239）

新增 `iconInfoRow` helper（現有 `infoRow` 不動，只加一個 variant）：

```swift
// 新增：
private func iconInfoRow(webp: String, label: String, value: String) -> some View {
    HStack {
        HStack(spacing: 4) {
            Image(webp: webp)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .opacity(0.7)
            Text(label).foregroundStyle(.secondary)
        }
        Spacer()
        Text(value).fontWeight(.medium)
    }
}

// 呼叫：
iconInfoRow(webp: "icon_level", label: "等級", value: "Lv.\(player.heroLevel)")
iconInfoRow(webp: "icon_gold",  label: "金幣", value: "\(player.gold)")
```

---

### 3. 屬性列 statAllocRow（Lines 244–248）

`statAllocRow` 的 `icon: String` 參數語意從 systemName 改為 WebP name，
函式內 `Image(systemName: icon)` 改為：

```swift
Image(webp: icon)
    .resizable()
    .scaledToFit()
    .frame(width: 14, height: 14)
    .opacity(0.7)
```

呼叫改為：
```swift
statAllocRow(icon: "attr_atk", label: "ATK", ...)
statAllocRow(icon: "attr_def", label: "DEF", ...)
statAllocRow(icon: "attr_hp",  label: "HP",  ...)
statAllocRow(icon: "attr_agi", label: "AGI", hint: "ATB 速度", ...)
statAllocRow(icon: "attr_dex", label: "DEX", hint: "暴擊率",   ...)
```

---

### 4. 累計統計列（Lines 341–345）

整個區塊移除，不換 icon，直接刪除。

---

## 修改檔案（待實作時）

- `Views/CharacterView.swift`（3 個改動區塊 + 統計列刪除）
- `StaticData/ClassDef.swift`（移除 `iconName` property，或保留備用）
- `IdleBattleRPG/Resources/`（10 張新 WebP）
