# V7-4 Ticket 01：新素材 — 種子 + 農作物品質

**狀態：** ✅ 已完成

**依賴：** 無

---

## 目標

新增 16 個 `MaterialType` case（4 種種子 + 12 種農作物品質變體），並同步更新所有相關資料模型與靜態資料。

---

## MaterialType 新增 case

```swift
// V7-4 種子（作為農田任務的消耗輸入）
case wheatSeed        // 小麥種子
case vegetableSeed    // 蔬菜種子
case fruitSeed        // 果實種子（地下城掉落）
case spiritGrainSeed  // 靈穗種子（地下城掉落）

// V7-4 農作物（4 種 × 3 品質）
case wheat;      case wheatHigh;      case wheatTop       // 小麥
case vegetable;  case vegetableHigh;  case vegetableTop   // 蔬菜
case fruit;      case fruitHigh;      case fruitTop       // 果實
case spiritGrain; case spiritGrainHigh; case spiritGrainTop // 靈穗
```

**displayName 規則：**
- 普通：直接名稱（小麥、蔬菜、果實、靈穗）
- 高級：前綴 `★`（★小麥、★蔬菜…）
- 頂級：前綴 `✦`（✦小麥、✦蔬菜…）

**icon 規則：**
- 種子：🌱
- 農作物普通：各自專屬 emoji（🌾 小麥 / 🥦 蔬菜 / 🍎 果實 / 🌿 靈穗）
- 農作物高級：同 emoji，displayName 加★前綴即可區分
- 農作物頂級：同 emoji，displayName 加✦前綴即可區分

---

## 修改檔案

### `StaticData/MaterialType.swift`

新增 16 個 case 及對應的 `displayName`、`icon` 屬性 switch 分支。

### `Models/MaterialInventoryModel.swift`

新增 16 個 SwiftData 欄位（SwiftData 輕量遷移，預設值為 `0`）：

```swift
// 種子
var wheatSeed: Int = 0
var vegetableSeed: Int = 0
var fruitSeed: Int = 0
var spiritGrainSeed: Int = 0

// 農作物
var wheat: Int = 0;      var wheatHigh: Int = 0;      var wheatTop: Int = 0
var vegetable: Int = 0;  var vegetableHigh: Int = 0;  var vegetableTop: Int = 0
var fruit: Int = 0;      var fruitHigh: Int = 0;      var fruitTop: Int = 0
var spiritGrain: Int = 0; var spiritGrainHigh: Int = 0; var spiritGrainTop: Int = 0
```

更新 `amount(of:)` / `add(_:of:)` / `deduct(_:of:)` 三個 switch，補齊所有新 case。

### `Models/TaskModel.swift`

新增 12 個農作物結果欄位（種子只是輸入消耗，不作為 result 欄位）：

```swift
var resultWheat: Int = 0;       var resultWheatHigh: Int = 0;       var resultWheatTop: Int = 0
var resultVegetable: Int = 0;   var resultVegetableHigh: Int = 0;   var resultVegetableTop: Int = 0
var resultFruit: Int = 0;       var resultFruitHigh: Int = 0;       var resultFruitTop: Int = 0
var resultSpiritGrain: Int = 0; var resultSpiritGrainHigh: Int = 0; var resultSpiritGrainTop: Int = 0
```

更新 `resultAmount(of:)` / `setResult(_:of:)` switch 補齊新 case。

### `StaticData/MerchantTradeDef.swift`

新增商人種子購買選項（依現有 goldTrades 格式）：

```swift
// 補給：購買種子
("buy_wheat_seed",     .gold,     80,  .wheatSeed,     3),
("buy_vegetable_seed", .gold,    120,  .vegetableSeed, 3),
```

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 所有新 MaterialType 的 displayName / icon 正確顯示
- [ ] MaterialInventoryModel 新欄位可正常讀寫（不需 migration）
- [ ] TaskModel 新結果欄位可正常讀寫
- [ ] 商人出現「小麥種子 ×3 / 80金」與「蔬菜種子 ×3 / 120金」購買選項
