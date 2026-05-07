# V8-1 Ticket 01：稀有度枚舉擴充 + 新裝備定義

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

在 `EquipmentRarity` 新增 `rare`（稀有）與 `epic`（史詩）兩個 case，並定義 8 件新裝備（稀有套組 4 件、史詩套組 4 件）。

---

## 修改細節

### `StaticData/EquipmentDef.swift`

#### 1. EquipmentRarity 擴充

```swift
enum EquipmentRarity: String, CaseIterable, Codable {
    case common  = "common"
    case refined = "refined"
    case rare    = "rare"    // 新增：稀有
    case epic    = "epic"    // 新增：史詩

    var displayName: String {
        switch self {
        case .common:  return "普通"
        case .refined: return "精良"
        case .rare:    return "稀有"
        case .epic:    return "史詩"
        }
    }
}
```

#### 2. 稀有套組（rare）裝備定義

加入 `all` 靜態陣列（依現有格式）：

```swift
// ── V8-1 稀有套組 ────────────────────────────────────
EquipmentDef(
    key:      "rare_weapon",
    name:     "靈火劍",
    slot:     .weapon,
    rarity:   .rare,
    atkBonus: 110,
    defBonus: 0,
    hpBonus:  0
),
EquipmentDef(
    key:      "rare_armor",
    name:     "深淵重甲",
    slot:     .armor,
    rarity:   .rare,
    atkBonus: 0,
    defBonus: 58,
    hpBonus:  130
),
EquipmentDef(
    key:      "rare_offhand",
    name:     "古木戰盾",
    slot:     .offhand,
    rarity:   .rare,
    atkBonus: 0,
    defBonus: 38,
    hpBonus:  75
),
EquipmentDef(
    key:      "rare_accessory",
    name:     "深海護符",
    slot:     .accessory,
    rarity:   .rare,
    atkBonus: 28,
    defBonus: 14,
    hpBonus:  48
),
```

#### 3. 史詩套組（epic）裝備定義

```swift
// ── V8-1 史詩套組 ────────────────────────────────────
EquipmentDef(
    key:      "epic_weapon",
    name:     "永恆刃",
    slot:     .weapon,
    rarity:   .epic,
    atkBonus: 145,
    defBonus: 0,
    hpBonus:  0
),
EquipmentDef(
    key:      "epic_armor",
    name:     "神域護甲",
    slot:     .armor,
    rarity:   .epic,
    atkBonus: 0,
    defBonus: 78,
    hpBonus:  175
),
EquipmentDef(
    key:      "epic_offhand",
    name:     "虛空之盾",
    slot:     .offhand,
    rarity:   .epic,
    atkBonus: 0,
    defBonus: 50,
    hpBonus:  100
),
EquipmentDef(
    key:      "epic_accessory",
    name:     "深淵聖環",
    slot:     .accessory,
    rarity:   .epic,
    atkBonus: 37,
    defBonus: 20,
    hpBonus:  65
),
```

#### 4. 拆解回收值（disassembleRefunds）

在現有字典加入 8 個新 key（稀有回收 500，史詩回收 1200）：

```swift
"rare_weapon":     500,
"rare_armor":      500,
"rare_offhand":    500,
"rare_accessory":  500,
"epic_weapon":     1200,
"epic_armor":      1200,
"epic_offhand":    1200,
"epic_accessory":  1200,
```

---

## 修改檔案

- `StaticData/EquipmentDef.swift`

---

## 驗收標準

- [ ] Build 無錯誤，無新 warning
- [ ] `EquipmentRarity.allCases` 包含 4 個 case
- [ ] `EquipmentDef.find(key: "rare_weapon")` 回傳正確定義
- [ ] 8 件新裝備的 `displayName`、`slot`、`rarity`、`atkBonus`/`defBonus`/`hpBonus` 數值正確
