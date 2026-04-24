# V7-4 Ticket 03：消耗品系統（ConsumableInventoryModel + 料理改版）

**狀態：** ✅ 完成

**依賴：** 無（可與 T01 / T02 平行，但 T04 依賴此 ticket）

---

## 目標

1. 建立統一的消耗品系統（`ConsumableType` + `ConsumableInventoryModel`）
2. 將廚師料理的結算方式從「即時 timed buff」改為「進消耗品背包」
3. 移除 `HeroStatsService` 中的時間型料理 buff 邏輯

---

## ConsumableType 枚舉

**新建 `StaticData/ConsumableType.swift`**：

```swift
enum ConsumableType: String, CaseIterable, Codable {
    // 廚師料理（普通品質）
    case fishStew          // 魚肉燉鍋
    case herbFishSoup      // 藥草魚湯
    case abyssSoup         // 深淵燉菜
    case smokedAbyssFish   // 煙燻深淵魚

    // 廚師料理（高級品質，由高品質食材 RNG 產生）
    case fishStewHigh
    case herbFishSoupHigh
    case abyssSoupHigh
    case smokedAbyssFishHigh

    // 藥水（T04 新增後使用）
    case smallPotion       // 小型藥水（HP 回復 30%）
    case mediumPotion      // 中型藥水（HP 回復 60%）

    var displayName: String {
        switch self {
        case .fishStew:          return "魚肉燉鍋"
        case .fishStewHigh:      return "★魚肉燉鍋"
        case .herbFishSoup:      return "藥草魚湯"
        case .herbFishSoupHigh:  return "★藥草魚湯"
        case .abyssSoup:         return "深淵燉菜"
        case .abyssSoupHigh:     return "★深淵燉菜"
        case .smokedAbyssFish:   return "煙燻深淵魚"
        case .smokedAbyssFishHigh: return "★煙燻深淵魚"
        case .smallPotion:       return "小型藥水"
        case .mediumPotion:      return "中型藥水"
        }
    }

    var icon: String {
        switch self {
        case .fishStew, .fishStewHigh:                   return "🍲"
        case .herbFishSoup, .herbFishSoupHigh:            return "🍵"
        case .abyssSoup, .abyssSoupHigh:                  return "🫕"
        case .smokedAbyssFish, .smokedAbyssFishHigh:      return "🐟"
        case .smallPotion:                                return "🧪"
        case .mediumPotion:                               return "⚗️"
        }
    }

    var isCuisine: Bool {
        switch self {
        case .fishStew, .fishStewHigh, .herbFishSoup, .herbFishSoupHigh,
             .abyssSoup, .abyssSoupHigh, .smokedAbyssFish, .smokedAbyssFishHigh:
            return true
        default: return false
        }
    }

    var isPotion: Bool { !isCuisine }

    var isHighQuality: Bool { rawValue.hasSuffix("High") }

    /// 對應的 CuisineDef key（僅料理類型有效）
    var cuisineDefKey: String? {
        guard isCuisine else { return nil }
        return isHighQuality ? String(rawValue.dropLast(4)) : rawValue
    }
}
```

---

## ConsumableInventoryModel

**新建 `Models/ConsumableInventoryModel.swift`**：

```swift
import Foundation
import SwiftData

@Model
final class ConsumableInventoryModel {

    // 廚師料理
    var fishStew: Int = 0;          var fishStewHigh: Int = 0
    var herbFishSoup: Int = 0;      var herbFishSoupHigh: Int = 0
    var abyssSoup: Int = 0;         var abyssSoupHigh: Int = 0
    var smokedAbyssFish: Int = 0;   var smokedAbyssFishHigh: Int = 0

    // 藥水
    var smallPotion: Int = 0
    var mediumPotion: Int = 0

    init() {}

    func amount(of type: ConsumableType) -> Int {
        switch type {
        case .fishStew:           return fishStew
        case .fishStewHigh:       return fishStewHigh
        case .herbFishSoup:       return herbFishSoup
        case .herbFishSoupHigh:   return herbFishSoupHigh
        case .abyssSoup:          return abyssSoup
        case .abyssSoupHigh:      return abyssSoupHigh
        case .smokedAbyssFish:    return smokedAbyssFish
        case .smokedAbyssFishHigh: return smokedAbyssFishHigh
        case .smallPotion:        return smallPotion
        case .mediumPotion:       return mediumPotion
        }
    }

    func add(_ n: Int = 1, of type: ConsumableType) {
        switch type {
        case .fishStew:           fishStew          += n
        case .fishStewHigh:       fishStewHigh       += n
        case .herbFishSoup:       herbFishSoup       += n
        case .herbFishSoupHigh:   herbFishSoupHigh   += n
        case .abyssSoup:          abyssSoup          += n
        case .abyssSoupHigh:      abyssSoupHigh      += n
        case .smokedAbyssFish:    smokedAbyssFish    += n
        case .smokedAbyssFishHigh: smokedAbyssFishHigh += n
        case .smallPotion:        smallPotion        += n
        case .mediumPotion:       mediumPotion       += n
        }
    }

    /// 使用一個消耗品；若庫存不足回傳 false
    @discardableResult
    func use(of type: ConsumableType) -> Bool {
        guard amount(of: type) > 0 else { return false }
        add(-1, of: type)
        return true
    }
}
```

---

## App 層更新

### `IdleBattleRPGApp.swift`

在 `ModelContainer` 的 for: 參數列加入 `ConsumableInventoryModel.self`。

### `Models/DatabaseSeeder.swift`

新增方法並在 `seedIfNeeded()` 中呼叫：

```swift
private func seedConsumableInventory(context: ModelContext) {
    let descriptor = FetchDescriptor<ConsumableInventoryModel>()
    guard (try? context.fetch(descriptor))?.isEmpty != false else { return }
    context.insert(ConsumableInventoryModel())
    try? context.save()
}
```

---

## 料理結算改版

### `Services/TaskClaimService.swift`

原 `.cuisine` claim 邏輯（寫入 `player.activeCuisineKey`）改為寫入消耗品背包：

```swift
case .cuisine:
    guard let cuisineKey = task.resultCuisineKey.isEmpty ? nil : task.resultCuisineKey,
          let _ = CuisineDef.find(cuisineKey),
          let consumable = fetchConsumableInventory() else { break }

    // 依食材品質 RNG 決定是否為高級料理
    var rng = DeterministicRNG(seed: makeSeed(task: task))
    let roll = rng.nextDouble()
    let isHighQuality = roll < 0.25  // 25% 機率產出高級料理

    // cuisineKey 對應 ConsumableType rawValue（需一致）
    if isHighQuality,
       let highType = ConsumableType(rawValue: cuisineKey + "High") {
        consumable.add(of: highType)
    } else if let baseType = ConsumableType(rawValue: cuisineKey) {
        consumable.add(of: baseType)
    }
```

新增輔助查詢方法：

```swift
private func fetchConsumableInventory() -> ConsumableInventoryModel? {
    let descriptor = FetchDescriptor<ConsumableInventoryModel>()
    return (try? context.fetch(descriptor))?.first
}
```

### `Services/HeroStatsService.swift`

**移除** V7-3 加入的時間型 buff 區塊：

```swift
// 刪除以下段落：
// V7-3：套用料理 buff（限時；到期後自動失效）
let now = Date().timeIntervalSinceReferenceDate
if !player.activeCuisineKey.isEmpty,
   player.cuisineBuffExpiresAt > now,
   let cuisine = CuisineDef.find(player.activeCuisineKey) {
    atk += cuisine.atkBonus
    def += cuisine.defBonus
    hp  += cuisine.hpBonus
}
```

（料理 buff 將改在 BattleLogGenerator 中透過 snapshotCuisineKey 套用，見 T05）

---

## CuisineSheet 更新

### `Views/CuisineSheet.swift`

移除「目前生效的料理 Buff」Section（因為 buff 不再即時生效）。

改為新增「消耗品背包」Section，顯示各料理的持有量：

```swift
Section("消耗品背包") {
    ForEach(ConsumableType.allCases.filter(\.isCuisine), id: \.self) { type in
        let count = consumable?.amount(of: type) ?? 0
        HStack {
            Text("\(type.icon) \(type.displayName)")
                .foregroundStyle(count > 0 ? .primary : .secondary)
            Spacer()
            Text("\(count)")
                .monospacedDigit()
                .foregroundStyle(count > 0 ? .primary : .secondary)
        }
    }
}
```

CuisineSheet 需加入 `@Query private var consumables: [ConsumableInventoryModel]`，傳入 `inventory` 與 `consumable` 兩個參數（或直接 @Query）。

---

## CuisineDef key ↔ ConsumableType rawValue 對照

**必須保持一致：**

| CuisineDef.key    | ConsumableType case  |
|-------------------|----------------------|
| `fish_stew`       | `fishStew`           |
| `herb_fish_soup`  | `herbFishSoup`       |
| `abyss_soup`      | `abyssSoup`          |
| `smoked_abyss_fish` | `smokedAbyssFish`  |

> ⚠️ CuisineDef 使用 snake_case key，ConsumableType 使用 camelCase rawValue。
> `TaskClaimService` 需要手動映射，不能直接用 `rawValue` 轉換。

建議在 `CuisineDef` 中新增 `var consumableType: ConsumableType` 屬性，統一處理映射。

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] ConsumableInventoryModel 隨 App 啟動自動 seed（不重複）
- [ ] 廚師完成料理後，消耗品進背包（不再寫 `activeCuisineKey`）
- [ ] 25% 機率產出高級料理（★前綴）
- [ ] CuisineSheet 不再顯示「目前 Buff」，改顯示背包持有量
- [ ] HeroStatsService 不再讀 `activeCuisineKey`（build 後確認無 dead code warning）
