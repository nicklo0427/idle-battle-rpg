# V7-4 Ticket 07：商人更新（種子購買 + 農作物出售）

**狀態：** ✅ 完成

**依賴：** Ticket 01（新素材 MaterialType）

---

## 目標

1. 商人新增「基礎種子購買」（小麥種子 / 蔬菜種子）
2. 商人新增「農作物出售」區塊，讓玩家將多餘農作物換成金幣

---

## MerchantTradeDef 修改

### `StaticData/MerchantTradeDef.swift`

**種子購買**（金幣 → 種子，依現有 `goldTrades` 格式）：

```swift
// 補給：購買種子（V7-4）
MerchantTradeDef(key: "buy_wheat_seed",     category: .supply,
                 goldCost: 80,  materialGain: .wheatSeed,    gainAmount: 3),
MerchantTradeDef(key: "buy_vegetable_seed", category: .supply,
                 goldCost: 120, materialGain: .vegetableSeed, gainAmount: 3),
```

**農作物出售**（素材 → 金幣，依現有 `sellTrades` 格式）：

| 農作物 | 出售比率（每顆→金幣）|
|---|---|
| 普通品質 | 10 金 |
| 高級品質（★）| 25 金 |
| 頂級品質（✦）| 60 金 |

```swift
// 出售：農作物（V7-4）— 普通品質
MerchantTradeDef(key: "sell_wheat",         category: .cropSell,
                 materialCost: .wheat,        costAmount: 1, goldGain: 10),
MerchantTradeDef(key: "sell_vegetable",     category: .cropSell,
                 materialCost: .vegetable,    costAmount: 1, goldGain: 10),
MerchantTradeDef(key: "sell_fruit",         category: .cropSell,
                 materialCost: .fruit,        costAmount: 1, goldGain: 10),
MerchantTradeDef(key: "sell_spirit_grain",  category: .cropSell,
                 materialCost: .spiritGrain,  costAmount: 1, goldGain: 10),

// 高級品質
MerchantTradeDef(key: "sell_wheat_high",        category: .cropSell,
                 materialCost: .wheatHigh,       costAmount: 1, goldGain: 25),
MerchantTradeDef(key: "sell_vegetable_high",    category: .cropSell,
                 materialCost: .vegetableHigh,   costAmount: 1, goldGain: 25),
MerchantTradeDef(key: "sell_fruit_high",        category: .cropSell,
                 materialCost: .fruitHigh,       costAmount: 1, goldGain: 25),
MerchantTradeDef(key: "sell_spirit_grain_high", category: .cropSell,
                 materialCost: .spiritGrainHigh, costAmount: 1, goldGain: 25),

// 頂級品質
MerchantTradeDef(key: "sell_wheat_top",         category: .cropSell,
                 materialCost: .wheatTop,        costAmount: 1, goldGain: 60),
MerchantTradeDef(key: "sell_vegetable_top",     category: .cropSell,
                 materialCost: .vegetableTop,    costAmount: 1, goldGain: 60),
MerchantTradeDef(key: "sell_fruit_top",         category: .cropSell,
                 materialCost: .fruitTop,        costAmount: 1, goldGain: 60),
MerchantTradeDef(key: "sell_spirit_grain_top",  category: .cropSell,
                 materialCost: .spiritGrainTop,  costAmount: 1, goldGain: 60),
```

若 `MerchantTradeDef` 目前無 `cropSell` category，需新增：

```swift
enum TradeCategory {
    // 現有 case...
    case cropSell   // V7-4 農作物出售
}
```

---

## MerchantSheet UI 修改

### `Views/MerchantSheet.swift`

**新增種子購買 Section**（插入現有「補給品」或獨立一區）：

```swift
Section("種子補給") {
    ForEach(MerchantTradeDef.seedSupply, id: \.key) { trade in
        merchantBuyRow(trade: trade)   // 依現有 goldTrades row 格式
    }
}
```

**新增農作物出售 Section**：

```swift
Section(header: Text("農作物出售"), footer: Text("頂級品質可獲得更多金幣。")) {
    let cropSellTrades = MerchantTradeDef.cropSell.filter {
        (inventory?.amount(of: $0.materialCost!) ?? 0) > 0
    }
    if cropSellTrades.isEmpty {
        Text("尚無農作物可出售")
            .font(.caption)
            .foregroundStyle(.secondary)
    } else {
        ForEach(cropSellTrades, id: \.key) { trade in
            merchantSellRow(trade: trade)  // 依現有 sellTrades row 格式
        }
    }
}
```

> 農作物出售 Section 僅顯示庫存 > 0 的品項，避免列表過長。若全數庫存為 0，顯示「尚無農作物可出售」提示。

---

## 套利防護

依 CLAUDE.md 原則：
- **種子購買**：單向（金幣→種子），無反向出售種子功能
- **農作物出售**：單向（農作物→金幣），不設農作物→種子的兌換
- 避免農作物循環套利（種→收→售→買種）：金幣到種子的購買成本 > 農作物出售收入（確認數值）

**數值檢查：**
- 80 金買 3 顆小麥種子（26.7 金/顆）
- 種下後收穫 4 顆：全普通 = 40 金，全頂級 = 240 金
- 種植時長 30 分鐘最短，屬於時間投資，非即時套利
- 結論：數值合理，無明顯套利循環

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 商人顯示「小麥種子 ×3 / 80金」與「蔬菜種子 ×3 / 120金」購買選項
- [ ] 購買種子後庫存正確增加，金幣正確扣除
- [ ] 商人顯示「農作物出售」Section
- [ ] 只有庫存 > 0 的農作物出現在出售列表
- [ ] 庫存全為 0 時顯示「尚無農作物可出售」
- [ ] 出售後金幣正確增加，農作物庫存正確扣除
- [ ] 普通 / 高級 / 頂級金幣差異正確（10 / 25 / 60）
