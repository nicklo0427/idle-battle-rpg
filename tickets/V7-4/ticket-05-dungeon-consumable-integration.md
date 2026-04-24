# V7-4 Ticket 05：出征消耗品整合

**狀態：** ✅ 完成

**依賴：** Ticket 03（ConsumableInventoryModel）、Ticket 04（PotionDef）

---

## 目標

讓玩家在出征前選擇攜帶的料理（+ATK/DEF/HP）與藥水（HP 回復），選定後庫存立即扣除，戰鬥結算時依 snapshot 套用效果。

---

## 設計規格

| 項目 | 規格 |
|---|---|
| 攜帶上限 | 料理 1 種（選填）+ 藥水 1 種（選填）|
| 消耗時機 | 出發時立即從消耗品背包扣除 1 個 |
| 料理效果 | 持續整場出征，提升 heroAtk / heroDef / heroMaxHp |
| 藥水效果 | HP 低於 50% 時觸發一次回復（healPercent × heroMaxHp）|
| 持久化 | `task.snapshotCuisineKey` + `task.snapshotPotionKey`（本票新增）|

---

## 資料模型

### `Models/TaskModel.swift`

新增兩個 snapshot 欄位：

```swift
var snapshotCuisineKey: String = ""   // 攜帶的料理 ConsumableType rawValue
var snapshotPotionKey:  String = ""   // 攜帶的藥水 ConsumableType rawValue
```

---

## 服務層

### `Services/TaskCreationService.swift`

`createDungeonFloorTask()` 新增兩個參數（有預設值，向後相容）：

```swift
func createDungeonFloorTask(
    floorKey: String,
    heroStats: HeroStats,
    equippedSkillKeys: [String],
    durationSeconds: Int,
    cuisineKey: String = "",    // V7-4 新增
    potionKey: String = ""      // V7-4 新增
) throws {
    // ... 現有驗證邏輯 ...

    // V7-4：扣除消耗品
    let consumable = fetchConsumableInventory()
    if !cuisineKey.isEmpty,
       let type = ConsumableType(rawValue: cuisineKey) {
        guard consumable?.use(of: type) == true else {
            throw TaskCreationError.insufficientConsumable(cuisineKey)
        }
    }
    if !potionKey.isEmpty,
       let type = ConsumableType(rawValue: potionKey) {
        guard consumable?.use(of: type) == true else {
            throw TaskCreationError.insufficientConsumable(potionKey)
        }
    }

    // 建立 TaskModel
    let task = TaskModel(...)
    task.snapshotCuisineKey = cuisineKey
    task.snapshotPotionKey  = potionKey
    // ... 其餘現有邏輯 ...
}
```

新增 `TaskCreationError` case（若尚不存在）：

```swift
case insufficientConsumable(String)
```

新增輔助查詢：

```swift
private func fetchConsumableInventory() -> ConsumableInventoryModel? {
    let descriptor = FetchDescriptor<ConsumableInventoryModel>()
    return (try? context.fetch(descriptor))?.first
}
```

---

## ViewModel

### `ViewModels/AdventureViewModel.swift`

`startDungeonFloor()` 加入消耗品參數（現有呼叫不受影響，預設為空字串）：

```swift
func startDungeonFloor(
    floor: DungeonFloorDef,
    heroStats: HeroStats,
    equippedSkillKeys: [String],
    duration: Int,
    cuisineKey: String = "",
    potionKey: String = "",
    context: ModelContext
) -> Result<Void, TaskCreationError> {
    // 委派給 TaskCreationService.createDungeonFloorTask(...)
}
```

---

## UI

### `Views/AdventureView.swift`（FloorDetailSheet 部分）

在「出發」按鈕上方新增「攜帶消耗品」Section：

```swift
@Query private var consumablesList: [ConsumableInventoryModel]
@State private var selectedCuisineKey: String = ""
@State private var selectedPotionKey: String = ""

private var consumable: ConsumableInventoryModel? { consumablesList.first }
```

```swift
Section("攜帶消耗品（選填）") {
    // 料理選擇
    Picker("料理", selection: $selectedCuisineKey) {
        Text("不攜帶").tag("")
        ForEach(ConsumableType.allCases.filter(\.isCuisine), id: \.rawValue) { type in
            let count = consumable?.amount(of: type) ?? 0
            if count > 0 {
                Label {
                    Text("\(type.displayName)（×\(count)）")
                } icon: {
                    Text(type.icon)
                }
                .tag(type.rawValue)
            }
        }
    }

    // 藥水選擇
    Picker("藥水", selection: $selectedPotionKey) {
        Text("不攜帶").tag("")
        ForEach(ConsumableType.allCases.filter(\.isPotion), id: \.rawValue) { type in
            let count = consumable?.amount(of: type) ?? 0
            if count > 0 {
                Label {
                    Text("\(type.displayName)（×\(count)）")
                } icon: {
                    Text(type.icon)
                }
                .tag(type.rawValue)
            }
        }
    }
}
```

「出發」按鈕呼叫：

```swift
viewModel.startDungeonFloor(
    floor: floor,
    heroStats: heroStats,
    equippedSkillKeys: equippedSkillKeys,
    duration: selectedDuration,
    cuisineKey: selectedCuisineKey,
    potionKey: selectedPotionKey,
    context: context
)
```

---

## BattleLogGenerator 整合

### `Services/BattleLogGenerator.swift`

`generate()` 函式簽名新增（有預設值，現有呼叫不需修改）：

```swift
static func generate(
    task: TaskModel,
    floor: DungeonFloorDef,
    fromBattleIndex: Int,
    maxBattles: Int = Int.max,
    cuisineDef: CuisineDef? = nil,    // V7-4 新增
    potionDef: PotionDef? = nil       // V7-4 新增
) -> [BattleEvent] {
```

**料理 buff 套用**（在 heroAtk / heroDef / heroMaxHp 初始化後）：

```swift
var snapshotPower = task.snapshotPower ?? 50
var heroMaxHp = max(50, snapshotPower * 2)
var heroAtk   = max(10, snapshotPower / 4)
var heroDef   = max(5,  snapshotPower / 10)

// V7-4：套用料理加成
if let cuisine = cuisineDef {
    heroAtk   += cuisine.atkBonus
    heroDef   += cuisine.defBonus
    heroMaxHp += cuisine.hpBonus
}
var heroHp = heroMaxHp
```

**藥水觸發**（在 combat loop 的 status tick 後、skill 觸發前）：

```swift
var potionUsed = false

// 在每回合處理中加入：
if let potion = potionDef, !potionUsed, heroHp < heroMaxHp / 2 {
    let healAmount = Int(Double(heroMaxHp) * potion.healPercent)
    heroHp = min(heroMaxHp, heroHp + healAmount)
    potionUsed = true
    events.append(BattleEvent(
        kind: .potionUsed,
        description: "使用 \(potion.name)，回復 \(healAmount) HP"
    ))
}
```

> `BattleEvent.kind` 需新增 `.potionUsed` case（或複用現有合適的 case）。

### `Views/DungeonBattleSheet.swift`

讀取 task 中的 snapshot key，解析並傳入 `BattleLogGenerator.generate()`：

```swift
let cuisineDef: CuisineDef? = {
    guard !task.snapshotCuisineKey.isEmpty,
          let type = ConsumableType(rawValue: task.snapshotCuisineKey),
          let key = type.cuisineDefKey else { return nil }
    return CuisineDef.find(key)
}()

let potionDef: PotionDef? = {
    guard !task.snapshotPotionKey.isEmpty,
          let type = ConsumableType(rawValue: task.snapshotPotionKey) else { return nil }
    // ConsumableType.rawValue 對應 PotionDef.key（需手動映射）
    switch type {
    case .smallPotion:  return PotionDef.find("small_potion")
    case .mediumPotion: return PotionDef.find("medium_potion")
    default: return nil
    }
}()

let events = BattleLogGenerator.generate(
    task: task,
    floor: floor,
    fromBattleIndex: fromBattleIndex,
    cuisineDef: cuisineDef,
    potionDef: potionDef
)
```

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 出征前 FloorDetailSheet 顯示「攜帶消耗品」選擇區塊
- [ ] 選擇後出發，消耗品背包立即扣 1 個
- [ ] 庫存為 0 的消耗品不出現在選項中
- [ ] 戰鬥記錄中，料理加成正確反映在 heroAtk / heroDef / heroMaxHp
- [ ] HP < 50% 時藥水觸發一次，戰鬥記錄出現「使用 XX 藥水，回復 XX HP」
- [ ] 藥水最多觸發一次（potionUsed 防重複）
- [ ] 未攜帶消耗品時，戰鬥邏輯與 V7-3 完全一致（預設值為空字串，無副作用）
