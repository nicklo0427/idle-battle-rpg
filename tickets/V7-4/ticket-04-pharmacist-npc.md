# V7-4 Ticket 04：製藥師 NPC + PotionDef + PharmacySheet

**狀態：** ✅ 完成

**依賴：** Ticket 01（農作物素材）、Ticket 03（ConsumableInventoryModel）

---

## 目標

新增製藥師 NPC，可選藥水配方 AFK 釀製，完成後藥水進消耗品背包。藥水可在出征前攜帶，於戰鬥 HP < 50% 時自動觸發一次回復。

---

## PotionDef 靜態資料

**新建 `StaticData/PotionDef.swift`**：

```swift
import Foundation

struct PotionDef {
    let key: String
    let name: String
    let icon: String
    let ingredients: [(material: MaterialType, amount: Int)]
    let goldCost: Int
    let brewMinutes: Int
    let healPercent: Double          // 回復比例，對 heroMaxHp

    var consumableType: ConsumableType {
        switch key {
        case "small_potion":  return .smallPotion
        case "medium_potion": return .mediumPotion
        default: fatalError("Unknown potion key: \(key)")
        }
    }

    var brewDurationDisplay: String {
        let h = brewMinutes / 60
        let m = brewMinutes % 60
        if h > 0 && m > 0 { return "\(h) 小時 \(m) 分" }
        if h > 0           { return "\(h) 小時" }
        return "\(m) 分鐘"
    }

    static let all: [PotionDef] = [
        PotionDef(
            key: "small_potion",
            name: "小型藥水",
            icon: "🧪",
            ingredients: [(.wheat, 5), (.vegetable, 3)],
            goldCost: 50,
            brewMinutes: 20,
            healPercent: 0.30
        ),
        PotionDef(
            key: "medium_potion",
            name: "中型藥水",
            icon: "⚗️",
            ingredients: [(.fruit, 3), (.spiritGrain, 2)],
            goldCost: 100,
            brewMinutes: 40,
            healPercent: 0.60
        ),
    ]

    static func find(_ key: String) -> PotionDef? {
        all.first { $0.key == key }
    }
}
```

---

## 資料模型與靜態資料修改

### `Models/TaskModel.swift`

`TaskKind` 新增：

```swift
case alchemy = "alchemy"
```

### `StaticData/NpcUpgradeDef.swift`

`NpcKind` 新增 `.pharmacist` case。

新增升級費用定義：

```swift
static let pharmacistCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost: 120, materialCosts: [(.herb, 20)],                        goldCost: 500),
    .init(fromTier: 1, expCost: 350, materialCosts: [(.spiritHerb, 10)],                  goldCost: 1000),
    .init(fromTier: 2, expCost: 900, materialCosts: [(.spiritHerb, 20), (.wheat, 10)],    goldCost: 2000),
]
```

在 `upgradeCost(npcKind:fromTier:)` 加入 `.pharmacist` case。

### `Models/PlayerStateModel.swift`

新增欄位：

```swift
var pharmacistTier: Int = 0
```

更新 `tier(for:)`：

```swift
case "pharmacist": return pharmacistTier
```

更新 `npcKind(for:)`：

```swift
case "pharmacist": return .pharmacist
```

### `AppConstants.swift`

```swift
enum Actor {
    // 現有欄位...
    static let pharmacist = "pharmacist"   // V7-4
}
```

---

## 服務層

### `Services/TaskCreationService.swift` — 新增 `createAlchemyTask`

仿 `createCuisineTask` 邏輯：

```swift
func createAlchemyTask(recipeKey: String) throws {
    guard let def = PotionDef.find(recipeKey) else {
        throw TaskCreationError.recipeNotFound(recipeKey)
    }
    // 1. 驗證製藥師閒置
    guard !existingTasks.contains(where: {
        $0.actorKey == AppConstants.Actor.pharmacist && $0.status == .inProgress
    }) else {
        throw TaskCreationError.actorBusy(AppConstants.Actor.pharmacist)
    }
    // 2. 驗證素材 + 金幣
    let player = fetchPlayer()
    let inventory = fetchInventory()
    guard let player, (player.gold) >= def.goldCost else {
        throw TaskCreationError.insufficientGold
    }
    for (mat, amount) in def.ingredients {
        guard (inventory?.amount(of: mat) ?? 0) >= amount else {
            throw TaskCreationError.insufficientMaterial(mat)
        }
    }
    // 3. 扣除資源
    player.gold -= def.goldCost
    for (mat, amount) in def.ingredients {
        inventory?.deduct(amount, of: mat)
    }
    // 4. 建立任務
    let durationMultiplier = NpcUpgradeDef.craftDurationMultiplier(tier: player.pharmacistTier)
    let duration = Int(Double(def.brewMinutes * 60) * durationMultiplier)
    let now = Date()
    let task = TaskModel(
        kind: .alchemy,
        actorKey: AppConstants.Actor.pharmacist,
        definitionKey: def.key,
        startedAt: now,
        endsAt: now.addingTimeInterval(TimeInterval(duration))
    )
    context.insert(task)
    try context.save()
}
```

### `Services/SettlementService.swift`

`.alchemy` case 只需標記完成，無額外 fillResults：

```swift
case .alchemy:
    break   // 結果在 TaskClaimService 處理
```

### `Services/TaskClaimService.swift` — 新增 `.alchemy` claim

```swift
case .alchemy:
    guard let recipeKey = task.definitionKey.isEmpty ? nil : task.definitionKey,
          let def = PotionDef.find(recipeKey),
          let consumable = fetchConsumableInventory() else { break }
    consumable.add(of: def.consumableType)
```

### `Services/NpcUpgradeService.swift`

tier 遞增 switch 加入：

```swift
case "pharmacist": player.pharmacistTier += 1
```

---

## ViewModel

### `ViewModels/BaseViewModel.swift`

新增三個方法：

```swift
/// 製藥師的進行中任務（nil = 閒置）
func pharmacistTask(from tasks: [TaskModel]) -> TaskModel? {
    tasks.first { $0.actorKey == AppConstants.Actor.pharmacist && $0.status == .inProgress }
}

/// 玩家目前是否可以負擔指定藥水
func canAffordPotion(
    _ potion: PotionDef,
    player: PlayerStateModel?,
    inventory: MaterialInventoryModel?
) -> Bool {
    guard let player, let inventory else { return false }
    guard player.gold >= potion.goldCost else { return false }
    return potion.ingredients.allSatisfy { (mat, amount) in
        inventory.amount(of: mat) >= amount
    }
}

/// 建立煉藥任務
@discardableResult
func startAlchemyTask(recipeKey: String, context: ModelContext) -> Result<Void, TaskCreationError> {
    do {
        try TaskCreationService(context: context).createAlchemyTask(recipeKey: recipeKey)
        return .success(())
    } catch let e as TaskCreationError {
        return .failure(e)
    } catch {
        return .failure(.recipeNotFound("unknown"))
    }
}
```

---

## UI

### 新建 `Views/PharmacySheet.swift`

仿 `CuisineSheet` 設計：

```
NavigationStack {
    List {
        Section("消耗品背包") {
            // 顯示所有 ConsumableType 的持有量（料理 + 藥水）
        }

        Section("目前資源") {
            // 顯示金幣 + 相關素材（wheat, vegetable, fruit, spiritGrain）
        }

        Section(header: ..., footer: "同一時間只能有一個製藥任務") {
            ForEach(PotionDef.all, id: \.key) { potion in
                let canAfford = viewModel.canAffordPotion(potion, ...)
                Button { startBrewing(potion) } label: {
                    potionRow(potion, canAfford: canAfford)
                }
                .disabled(!canAfford)
            }
        }
    }
    .navigationTitle("製藥師")
    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { ... } } }
}
```

每個 `potionRow` 顯示：
- icon + 名稱 + 釀製時長
- 效果說明（HP 回復 X%）
- 素材需求（數量不足時紅色）
- 金幣需求

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 製藥師在 BaseView 生產 tab 顯示（見 T06）
- [ ] 點擊閒置製藥師開啟 PharmacySheet
- [ ] 選擇藥水配方後立即扣除素材 + 金幣，製藥師進入忙碌狀態
- [ ] AFK 完成後藥水進入消耗品背包
- [ ] 製藥師升 Tier 縮短釀製時長（使用 `craftDurationMultiplier`）
- [ ] 製藥師忙碌中再次點擊顯示進行中任務資訊（不可再次派遣）
