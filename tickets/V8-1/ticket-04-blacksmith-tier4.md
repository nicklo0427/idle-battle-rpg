# V8-1 Ticket 04：鑄造師第 4 階

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

在鑄造師（blacksmith）NPC 升級定義中加入第 4 階，解鎖後鑄造速度提升至 0.55x（45% 加速）。升級材料使用沉沒之城 Boss 掉落（sunkenKingSeal），確保第 4 階屬於後期解鎖。

---

## 修改細節

### `StaticData/NpcUpgradeDef.swift`

#### 1. blacksmithCosts 新增第 4 筆

```swift
static let blacksmithCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost:  80,  materialCosts: [(.ore,              10)], goldCost:   400),
    .init(fromTier: 1, expCost: 250,  materialCosts: [(.crystalShard,      5)], goldCost:  1200),
    .init(fromTier: 2, expCost: 700,  materialCosts: [(.ancientFragment,   3)], goldCost:  2500),
    // 新增 ↓
    .init(fromTier: 3, expCost: 2000, materialCosts: [(.sunkenKingSeal,    3)], goldCost:  8000),
]
```

#### 2. craftMultipliers 新增第 5 個值

```swift
// 原：[1.0, 0.85, 0.75, 0.65]
private static let craftMultipliers: [Double] = [1.0, 0.85, 0.75, 0.65, 0.55]
```

效果對照：
| 階級 | 倍率 | 120 min 配方實際耗時 |
|------|------|---------------------|
| 0（無升） | 1.00x | 120 min |
| 1 | 0.85x | 102 min |
| 2 | 0.75x | 90 min |
| 3 | 0.65x | 78 min |
| 4（新） | 0.55x | 66 min |

---

## 修改檔案

- `StaticData/NpcUpgradeDef.swift`（只改這一個檔案）

> `NpcUpgradeService` 使用 `blacksmithCosts.count` 動態判斷最高階，不需另外更新上限常數。

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] SettlementSheet（鑄造師升級頁）顯示第 4 階升級選項
- [ ] 升級費用顯示：2000 EXP + sunkenKingSeal ×3 + 8000 金
- [ ] 升級後鑄造師描述顯示「0.55x 速度」或等效文字
- [ ] 120 min 史詩配方在第 4 階鑄造師下耗時約 66 min（測試用 dev 加速確認）
