# V8-1 Ticket 03：史詩套組鑄造配方

**狀態：** ✅ 完成

**依賴：** T01（epic 裝備定義）

---

## 目標

新增 4 條史詩（epic）鑄造配方。原料跨三個系統：沉沒之城 Boss 掉落（sunkenKingSeal）+ V7 採集素材（靈草、深淵魚、古代木材）+ V7-4 頂級農作物（✦品質）。沉沒之城 floor 4（Boss）清關後解鎖。

設計意圖：頂級農作物成為史詩鑄造的必要材料，讓農業系統與裝備鍊形成閉環。

---

## 修改細節

### `StaticData/CraftRecipeDef.swift`

在稀有配方之後繼續加入：

```swift
// ── V8-1 史詩套組（Boss 掉落 + 採集 + 頂級農作物）──────────────────
CraftRecipeDef(
    key:               "recipe_epic_accessory",
    name:              "鑄造深淵聖環",
    slot:              .accessory,
    rarity:            .epic,
    durationSeconds:   120 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .sunkenKingSeal,    amount: 3),
        MaterialRequirement(material: .spiritGrainTop,    amount: 5),
        MaterialRequirement(material: .abyssFish,         amount: 8),
        MaterialRequirement(material: .spiritHerb,        amount: 8),
    ],
    goldCost:           6000,
    outputEquipmentKey: "epic_accessory",
    unlockedByFloorKey: "sunken_floor_4"
),
CraftRecipeDef(
    key:               "recipe_epic_offhand",
    name:              "鑄造虛空之盾",
    slot:              .offhand,
    rarity:            .epic,
    durationSeconds:   110 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .drownedCrownFragment, amount: 4),
        MaterialRequirement(material: .wheatTop,             amount: 5),
        MaterialRequirement(material: .ancientWood,          amount: 15),
    ],
    goldCost:           4000,
    outputEquipmentKey: "epic_offhand",
    unlockedByFloorKey: "sunken_floor_4"
),
CraftRecipeDef(
    key:               "recipe_epic_armor",
    name:              "鑄造神域護甲",
    slot:              .armor,
    rarity:            .epic,
    durationSeconds:   120 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .sunkenKingSeal,    amount: 2),
        MaterialRequirement(material: .fruitTop,          amount: 3),
        MaterialRequirement(material: .abyssFish,         amount: 10),
    ],
    goldCost:           5000,
    outputEquipmentKey: "epic_armor",
    unlockedByFloorKey: "sunken_floor_4"
),
CraftRecipeDef(
    key:               "recipe_epic_weapon",
    name:              "鑄造永恆刃",
    slot:              .weapon,
    rarity:            .epic,
    durationSeconds:   120 * 60,
    requiredMaterials: [
        MaterialRequirement(material: .sunkenKingSeal, amount: 2),
        MaterialRequirement(material: .spiritGrainTop, amount: 3),
        MaterialRequirement(material: .spiritHerb,     amount: 10),
    ],
    goldCost:           5000,
    outputEquipmentKey: "epic_weapon",
    unlockedByFloorKey: "sunken_floor_4"
),
```

---

## 修改檔案

- `StaticData/CraftRecipeDef.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 沉沒之城 Boss（floor 4）清關後，CraftSheet 顯示 4 條史詩配方
- [ ] 配方中包含頂級農作物（✦小麥、✦果實、✦靈穗）以及沉沒之城 Boss 素材
- [ ] 鑄造完成後獲得對應史詩裝備（key 對應正確）
- [ ] 沉沒之城 floor 4 未清關時配方隱藏
