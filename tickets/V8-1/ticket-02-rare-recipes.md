# V8-1 Ticket 02：稀有套組鑄造配方

**狀態：** ✅ 完成

**依賴：** T01（rare 裝備定義）

---

## 目標

新增 4 條稀有（rare）鑄造配方，原料跨系統：沉沒之城地下城素材 + V7 採集素材（靈草、深淵魚、古代木材）。沉沒之城 floor 2 清關後解鎖配方。

---

## 修改細節

### `StaticData/CraftRecipeDef.swift`

在現有 `all` 陣列末尾，沉沒之城配方之後加入：

```swift
// ── V8-1 稀有套組（稀有素材 + 採集素材）────────────────────────────
CraftRecipeDef(
    key:               "recipe_rare_accessory",
    name:              "鑄造深海護符",
    slot:              .accessory,
    rarity:            .rare,
    durationSeconds:   75 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .sunkenKingSeal, amount: 1),
        MaterialRequirement(material: .abyssFish,      amount: 5),
        MaterialRequirement(material: .spiritHerb,     amount: 5),
    ],
    goldCost:           3000,
    outputEquipmentKey: "rare_accessory",
    unlockedByFloorKey: "sunken_floor_2"
),
CraftRecipeDef(
    key:               "recipe_rare_offhand",
    name:              "鑄造古木戰盾",
    slot:              .offhand,
    rarity:            .rare,
    durationSeconds:   75 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .drownedCrownFragment, amount: 2),
        MaterialRequirement(material: .ancientWood,          amount: 12),
    ],
    goldCost:           2000,
    outputEquipmentKey: "rare_offhand",
    unlockedByFloorKey: "sunken_floor_2"
),
CraftRecipeDef(
    key:               "recipe_rare_armor",
    name:              "鑄造深淵重甲",
    slot:              .armor,
    rarity:            .rare,
    durationSeconds:   90 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .abyssalCrystalDrop, amount: 3),
        MaterialRequirement(material: .abyssFish,          amount: 8),
    ],
    goldCost:           2500,
    outputEquipmentKey: "rare_armor",
    unlockedByFloorKey: "sunken_floor_2"
),
CraftRecipeDef(
    key:               "recipe_rare_weapon",
    name:              "鑄造靈火劍",
    slot:              .weapon,
    rarity:            .rare,
    durationSeconds:   90 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .sunkenRuneShard, amount: 3),
        MaterialRequirement(material: .spiritHerb,     amount: 8),
    ],
    goldCost:           2500,
    outputEquipmentKey: "rare_weapon",
    unlockedByFloorKey: "sunken_floor_2"
),
```

---

## 修改檔案

- `StaticData/CraftRecipeDef.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 進入 CraftSheet，沉沒之城 floor 2 清關後顯示 4 條稀有配方
- [ ] 配方所需素材列表正確（sunkenRuneShard / abyssalCrystalDrop / drownedCrownFragment / sunkenKingSeal + 採集素材）
- [ ] 鑄造完成後獲得對應稀有裝備（key 對應正確）
- [ ] 沉沒之城 floor 2 未清關時配方隱藏
