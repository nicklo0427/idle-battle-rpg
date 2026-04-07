# V2-2 Ticket 01：裝備強化靜態資料定義

**狀態：** ✅ 已完成

---

## 目標

定義裝備強化系統的靜態規則：強化等級上限、每級成本（金幣）、每級加成（依部位）。
這是強化系統的資料地基，後續 Ticket 在此之上建立 Service 與 UI。

---

## 設計決策

### 強化等級

- 範圍：+0（未強化）到 +5（滿強化）
- 固定上限，不依裝備稀有度變化（簡化設計）
- 每件裝備獨立計算等級（同款可有不同強化等級）

### 金幣成本（每「次」強化，不是累計）

| 強化等級 | 金幣成本 |
|---|---|
| +0 → +1 | 100 |
| +1 → +2 | 200 |
| +2 → +3 | 350 |
| +3 → +4 | 550 |
| +4 → +5 | 800 |

累計滿強化費用：2,000 金幣

> ⚠️ 數值為初稿，待 Ticket 06 數值平衡工單調整。

### 每級加成（固定值，非百分比）

| 部位 | 每 +1 等 ATK | 每 +1 等 DEF | 每 +1 等 HP |
|---|---|---|---|
| 武器 | +4 | 0 | 0 |
| 防具 | 0 | +3 | +8 |
| 飾品 | +2 | +2 | 0 |
| 副手 | 0 | +3 | +6 |

範例：裂牙獵刃（Boss 武器，rolledAtk=22）強化到 +3 → ATK = 22 + 4×3 = 34

> ⚠️ 數值為初稿，待 Ticket 06 調整。

### 拆解退還金幣（`DisassembleRule`）

拆解退還與裝備類別掛鉤（不考慮已花費的強化金幣，強化金幣視為消耗）：

| 類別 | 退還金幣 |
|---|---|
| V1 普通裝備 | 30 |
| V1 精良裝備 | 80 |
| V2-1 荒野邊境裝備 | 60 |
| V2-1 廢棄礦坑裝備 | 120 |
| V2-1 古代遺跡裝備 | 250 |
| V2-1 Boss 武器 | 300 |
| 初始破舊短劍 | 0（不可拆解）|

---

## 新增檔案

### `StaticData/EnhancementDef.swift`（新增）

```swift
struct EnhancementCostDef {
    let fromLevel: Int   // 0–4
    let goldCost: Int
}

struct EnhancementBonusDef {
    let slot: EquipmentSlot
    let atkPerLevel: Int
    let defPerLevel: Int
    let hpPerLevel:  Int
}

struct DisassembleRule {
    let equipmentKey: String   // 空字串 = 不可拆解
    let refundGold: Int
}

enum EnhancementDef {
    static let maxLevel = 5

    static let costs: [EnhancementCostDef] = [
        .init(fromLevel: 0, goldCost: 100),
        .init(fromLevel: 1, goldCost: 200),
        .init(fromLevel: 2, goldCost: 350),
        .init(fromLevel: 3, goldCost: 550),
        .init(fromLevel: 4, goldCost: 800),
    ]

    static let bonuses: [EnhancementBonusDef] = [
        .init(slot: .weapon,    atkPerLevel: 4, defPerLevel: 0, hpPerLevel:  0),
        .init(slot: .armor,     atkPerLevel: 0, defPerLevel: 3, hpPerLevel:  8),
        .init(slot: .accessory, atkPerLevel: 2, defPerLevel: 2, hpPerLevel:  0),
        .init(slot: .offhand,   atkPerLevel: 0, defPerLevel: 3, hpPerLevel:  6),
    ]

    static let disassembleRules: [String: Int] = [
        // V1
        "common_weapon": 30, "common_armor": 30, "common_accessory": 30,
        "refined_weapon": 80, "refined_armor": 80, "refined_accessory": 80,
        // V2-1 荒野邊境
        "wildland_accessory": 60, "wildland_armor": 60,
        "wildland_offhand": 60, "wildland_weapon_boss": 300,
        // V2-1 廢棄礦坑
        "mine_accessory": 120, "mine_armor": 120,
        "mine_offhand": 120, "mine_weapon_boss": 300,
        // V2-1 古代遺跡
        "ruins_accessory": 250, "ruins_armor": 250,
        "ruins_offhand": 250, "ruins_weapon_boss": 300,
        // 破舊短劍：不可拆解（不加入此 dict，Service 層查不到即禁止）
    ]

    // 便利查詢
    static func goldCost(fromLevel: Int) -> Int? {
        costs.first { $0.fromLevel == fromLevel }?.goldCost
    }

    static func bonus(for slot: EquipmentSlot) -> EnhancementBonusDef? {
        bonuses.first { $0.slot == slot }
    }

    static func disassembleRefund(defKey: String) -> Int? {
        disassembleRules[defKey]  // nil = 不可拆解
    }
}
```

---

## 刻意先不做的事

- **`EquipmentModel` 新增欄位**：留待 Ticket 02
- **EnhancementService**：留待 Ticket 03
- **UI**：留待 Ticket 04
- **拆解 Service / UI**：留待 Ticket 05

---

## 驗收標準

- [ ] `EnhancementDef.swift` 編譯通過，無 warning
- [ ] `EnhancementDef.goldCost(fromLevel:)` 可正確查詢各等級金幣成本
- [ ] `EnhancementDef.bonus(for:)` 可正確查詢各部位每級加成
- [ ] `EnhancementDef.disassembleRefund(defKey:)` 查不到 `"rusty_sword"` 時回傳 `nil`
- [ ] 不改動任何現有檔案（純新增）
