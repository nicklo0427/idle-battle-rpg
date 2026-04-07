# V2-4 Ticket 02：MerchantSheet V2-1 素材分組 UI

**狀態：** ✅ 完成

**依賴：** Ticket 01（TradeCategory + 12 筆定義）

---

## 目標

商人 Sheet 的「出售素材」Section 目前只有 4 種 V1 素材。
本 ticket 新增「區域素材出售」Section，顯示 12 種 V2-1 素材的出售按鈕，依地區分組。

---

## 修改檔案

`IdleBattleRPG/Views/MerchantSheet.swift`

### 變更：出售區塊拆成兩個 Section

**現有：**
```
Section("出售素材")  ← 4 種素材（forEach MerchantTradeDef.all）
```

**修改後：**
```
Section("基礎素材出售")  ← filter category == .basicMaterial
Section("區域素材出售")  ← filter category == .areaMaterial
```

### 實作細節

```swift
// 基礎素材（原有邏輯，只改 Section 標題）
let basicTrades = MerchantTradeDef.all.filter { $0.category == .basicMaterial }

// 區域素材（新增）
let areaTrades = MerchantTradeDef.all.filter { $0.category == .areaMaterial }
```

兩個 Section 的 row 結構完全相同（給出素材量、持有數量、獲得金幣、出售按鈕），
直接複用現有邏輯，不重複撰寫。可抽成 `@ViewBuilder func tradeRow(_ trade: MerchantTradeDef) -> some View`。

「區域素材出售」Section footer：
```swift
Text("地下城掉落的區域素材，可出售換取金幣。")
```

### Row 邏輯（兩個 Section 共用）

```swift
let have      = inventory?.amount(of: trade.giveMaterial) ?? 0
let canAfford = have >= trade.giveAmount

HStack(spacing: 10) {
    VStack(alignment: .leading, spacing: 2) {
        Text("\(trade.giveMaterial.icon) \(trade.giveMaterial.displayName) ×\(trade.giveAmount)")
            .fontWeight(.medium)
            .foregroundStyle(canAfford ? .primary : .secondary)
        Text("持有 \(have)")
            .font(.caption2)
            .foregroundStyle(canAfford ? .secondary : .red)
    }
    Spacer()
    Text("💰 +\(goldAmt)")
        .fontWeight(.semibold)
        .foregroundStyle(canAfford ? .yellow : .secondary)
    Button("出售") {
        execute { MerchantService(context: context).executeSellTrade(tradeKey: trade.key) }
    }
    .buttonStyle(.borderedProminent)
    .tint(.green)
    .disabled(!canAfford)
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/MerchantSheet.swift` | ✏️ 修改（出售區拆分 + 新增區域素材 Section） |

---

## 驗收標準

- [ ] 商人頁出現「基礎素材出售」Section（原 4 種）
- [ ] 商人頁出現「區域素材出售」Section（12 種，依荒野→礦坑→遺跡排序）
- [ ] 持有 0 時按鈕 disabled、顯示紅色「持有 0」
- [ ] 成功出售後金幣即時更新（@Query 驅動）
- [ ] 原有補給採購（金幣 → 古代碎片）無回歸
- [ ] Build 無錯誤
