# V4-3 Ticket 02：第四地下城區域「沉落王城」靜態資料

**狀態：** ✅ 已完成（V6-4 涵蓋）

**依賴：** 無（靜態資料獨立）

---

## 目標

新增第四地下城區域「沉落王城」（key: `sunken_city`），包含新素材、新裝備、新配方，以及對應的 V4-2 菁英定義。

---

## 修改檔案

- `StaticData/MaterialType.swift`
- `StaticData/DungeonRegionDef.swift`（或 `DungeonAreaDef.swift`，視現有命名）
- `StaticData/EquipmentDef.swift`
- `StaticData/CraftRecipeDef.swift`
- `StaticData/EliteDef.swift`（新增沉落王城菁英）

---

## 新素材（MaterialType.swift）

新增 4 種沉落系素材：

```swift
// 沉落王城素材
case sunkPalaceRubble      // 沉宮碎石（通用，F1 掉落）
case corrodedIronShard     // 蝕鐵碎片（通用，F2 掉落）
case ancientCrownFragment  // 古冠碎紋（通用，F3 掉落）
case abyssalKingCore       // 深淵王核（Boss 特材，F4 掉落）
```

---

## 新地下城區域（DungeonRegionDef/DungeonAreaDef）

```
區域 key: "sunken_city"
名稱: "沉落王城"
推薦戰力: 450–620
解鎖條件: 古代遺跡 Boss 菁英通關（ruins_floor_4 elite cleared）
主題色: .indigo
圖示: "building.columns.fill"（或類似 SF Symbol）
```

### 樓層設計（4 層 + Boss）

| 層 | key | 名稱 | 推薦戰力 | 敵人 | 素材掉落 |
|---|---|---|---|---|---|
| F1 | sunken_floor_1 | 沉宮前庭 | 450 | 沉宮衛兵 | sunkPalaceRubble（50%）|
| F2 | sunken_floor_2 | 腐鐵走廊 | 490 | 蝕甲守衛 | corrodedIronShard（50%）|
| F3 | sunken_floor_3 | 古冠廳堂 | 540 | 古冠祭典 | ancientCrownFragment（45%）|
| F4 | sunken_floor_4 | 深淵王座 | 590 | 深淵王靈 | abyssalKingCore（35%）|
| Boss | sunken_boss | 深淵王 | 620 | 深淵王 | abyssalKingCore + ancientFragment |

金幣範圍：25–50（勝場），敗場 20% 安慰金幣

---

## 新裝備（EquipmentDef.swift）

新增 4 件精良裝備：

| key | 名稱 | 部位 | ATK | DEF | HP |
|---|---|---|---|---|---|
| sunken_accessory | 沉宮印符 | 飾品 | +6 | +8 | +25 |
| sunken_armor | 蝕鐵戰甲 | 防具 | +0 | +20 | +60 |
| sunken_offhand | 古冠護盾 | 副手 | +4 | +16 | +40 |
| sunken_weapon | 深淵王刃 | 武器 | +35 | +5 | +10 |

---

## 新配方（CraftRecipeDef.swift）

| key | 名稱 | 時長 | 素材 | 金幣 | 解鎖樓層 |
|---|---|---|---|---|---|
| recipe_sunken_accessory | 鑄造沉宮印符 | 60 分鐘 | sunkPalaceRubble × 2 + ancientFragment × 1 | 300 | sunken_floor_1 |
| recipe_sunken_armor | 鑄造蝕鐵戰甲 | 70 分鐘 | corrodedIronShard × 2 + ore × 4 | 450 | sunken_floor_2 |
| recipe_sunken_offhand | 鑄造古冠護盾 | 80 分鐘 | ancientCrownFragment × 2 + ancientFragment × 1 | 600 | sunken_floor_3 |
| recipe_sunken_weapon | 鑄造深淵王刃 | 90 分鐘 | abyssalKingCore × 1 + ancientCrownFragment × 1 + ancientFragment × 2 | 1000 | sunken_floor_4 |

---

## EliteDef 補充（沉落王城 4 層）

| 樓層 key | 名稱 | HP | ATK | DEF | 最低戰力 | 獎勵 |
|---|---|---|---|---|---|---|
| sunken_floor_1 | 沉宮守門衛 | 600 | 80 | 40 | 480 | 300 金 + sunkPalaceRubble × 2 |
| sunken_floor_2 | 蝕甲重騎 | 800 | 95 | 55 | 520 | 420 金 + corrodedIronShard × 2 |
| sunken_floor_3 | 古冠祭司長 | 1050 | 112 | 68 | 560 | 580 金 + ancientCrownFragment × 2 |
| sunken_floor_4 | 深淵王靈魂 | 1400 | 135 | 80 | 610 | 900 金 + abyssalKingCore × 1 |

---

## 驗收標準

- [ ] 4 種新素材加入 MaterialType enum
- [ ] 沉落王城區域正確定義（4 樓 + Boss）
- [ ] 4 件新裝備在 EquipmentDef 中存在
- [ ] 4 個新配方在 CraftRecipeDef.v4Recipes 中存在，unlockedByFloorKey 正確
- [ ] 4 個新菁英在 EliteDef.all 中存在
- [ ] 不引入 SwiftData
