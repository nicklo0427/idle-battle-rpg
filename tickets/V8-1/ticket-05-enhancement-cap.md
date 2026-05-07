# V8-1 Ticket 05：強化上限 +5 → +8

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

將裝備強化上限從 +5 提升至 +8，新增 +6 / +7 / +8 三個強化等級。延續現有純金幣成本設計，不新增材料欄位（維持 EnhancementService 不動）。

---

## 修改細節

### `StaticData/EnhancementDef.swift`

#### 1. 更新 maxLevel

```swift
// 原：static let maxLevel = 5
static let maxLevel = 8
```

#### 2. costs 新增 3 條

```swift
static let costs: [EnhancementCostDef] = [
    .init(fromLevel: 0, goldCost:  100),
    .init(fromLevel: 1, goldCost:  200),
    .init(fromLevel: 2, goldCost:  350),
    .init(fromLevel: 3, goldCost:  550),
    .init(fromLevel: 4, goldCost:  800),
    // 新增 ↓
    .init(fromLevel: 5, goldCost: 1200),
    .init(fromLevel: 6, goldCost: 1800),
    .init(fromLevel: 7, goldCost: 2800),
]
```

金幣成本總覽：
| 等級 | 單次金幣 | 累積金幣 |
|------|---------|---------|
| +1   | 100  | 100   |
| +2   | 200  | 300   |
| +3   | 350  | 650   |
| +4   | 550  | 1200  |
| +5   | 800  | 2000  |
| +6（新）| 1200 | 3200  |
| +7（新）| 1800 | 5000  |
| +8（新）| 2800 | 7800  |

#### 3. 各槽 +6→+8 累積增益（按現有 perLevel 加乘，3 個等級）

| 槽位 | +6~+8 增益 |
|------|-----------|
| weapon | +12 ATK |
| armor | +9 DEF, +24 HP |
| offhand | +9 DEF, +18 HP |
| accessory | +6 ATK, +6 DEF |

---

## 修改檔案

- `StaticData/EnhancementDef.swift`（只改這一個檔案）

> `EnhancementService` 使用 `EnhancementDef.maxLevel` 作邊界判斷，無需修改。
> UI（CraftSheet 強化按鈕）同樣依 `maxLevel` 動態判斷是否可繼續強化，無需修改。

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 裝備強化至 +5 後，仍可繼續強化（按鈕不 disabled）
- [ ] +6 顯示費用 1200 金、+7 顯示 1800 金、+8 顯示 2800 金
- [ ] 強化至 +8 後按鈕變 disabled（已達上限）
- [ ] 強化至 +8 的武器 ATK 增益 = 基礎 + (8 × 4) = 基礎 +32
