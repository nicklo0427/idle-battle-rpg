# V7-4 Ticket 02：農夫 NPC（多塊田 + 種植系統）

**狀態：** ✅ 已完成

**依賴：** Ticket 01（新素材類型）

---

## 目標

新增農夫 NPC，支援多塊獨立農田並行種植。起始 1 塊田，每升 Tier 解鎖 1 塊（最多 4 塊）。種子作為消耗輸入，收穫時依 Tier 機率 RNG 決定作物品質。

---

## 設計規格

| 項目 | 規格 |
|---|---|
| 農田數量 | `availablePlots = gatherer5Tier + 1`（1～4 塊）|
| actorKey | `"farmer_plot_1"` ～ `"farmer_plot_4"`，各自獨立計時 |
| TaskKind | `.farming = "farming"` |
| 種子輸入 | 建立任務時扣除 1 顆種子（立即扣，同鑄造邏輯）|
| 種植時長 | 30 分鐘 / 2 小時 / 8 小時 |
| 收穫 RNG | SettlementService 掃描時執行，基礎產量 4 顆/次 |

### 品質機率（依 gatherer5Tier）

| Tier | 頂級 | 高級 | 普通 |
|---|---|---|---|
| 0 | 2% | 18% | 80% |
| 1 | 6% | 24% | 70% |
| 2 | 12% | 28% | 60% |
| 3 | 18% | 32% | 50% |

品質門檻（roll 值，愈小愈稀有）：
```swift
let topThreshold:  [Double] = [0.02, 0.06, 0.12, 0.18]
let highThreshold: [Double] = [0.20, 0.30, 0.40, 0.50]  // top + high 累計
```

---

## 靜態資料

### `StaticData/NpcUpgradeDef.swift`

新增 `NpcKind.farmer` case。

新增升級費用定義：

```swift
static let farmerCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost: 100, materialCosts: [(.wheatSeed, 5)],                             goldCost: 300),
    .init(fromTier: 1, expCost: 300, materialCosts: [(.vegetableSeed, 5), (.fruitSeed, 1)],        goldCost: 700),
    .init(fromTier: 2, expCost: 800, materialCosts: [(.fruitSeed, 3), (.spiritGrainSeed, 2)],      goldCost: 1500),
]
```

在 `upgradeCost(npcKind:fromTier:)` 加入 `.farmer` case。

---

## 資料模型

### `Models/PlayerStateModel.swift`

新增欄位：

```swift
var gatherer5Tier: Int = 0   // 農夫 Tier；可用農田數 = gatherer5Tier + 1
```

更新 `tier(for:)`：

```swift
case "farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4":
    return gatherer5Tier
```

更新 `npcKind(for:)`：

```swift
case "farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4":
    return .farmer
```

### `AppConstants.swift`

```swift
enum FarmerPlot {
    static let keys = ["farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4"]
    static func key(for index: Int) -> String { keys[index] }  // 0-based
    static let maxPlots = 4
}
```

### `Models/TaskModel.swift`

`TaskKind` 新增：

```swift
case farming = "farming"
```

---

## 服務層

### `Services/TaskCreationService.swift` — 新增 `createFarmTask`

```swift
func createFarmTask(plotKey: String, seedType: MaterialType, durationSeconds: Int) throws {
    // 1. 驗證農田閒置
    guard !existingTasks.contains(where: { $0.actorKey == plotKey && $0.kind == .farming && $0.status == .inProgress }) else {
        throw TaskCreationError.actorBusy(plotKey)
    }
    // 2. 驗證種子庫存 >= 1
    let inventory = fetchInventory()
    guard (inventory?.amount(of: seedType) ?? 0) >= 1 else {
        throw TaskCreationError.insufficientMaterial(seedType)
    }
    // 3. 立即扣種子
    inventory?.deduct(1, of: seedType)
    // 4. 建立任務
    let now = Date()
    let task = TaskModel(
        kind: .farming,
        actorKey: plotKey,
        definitionKey: seedType.rawValue,
        startedAt: now,
        endsAt: now.addingTimeInterval(TimeInterval(durationSeconds))
    )
    context.insert(task)
    try context.save()
}
```

### `Services/SettlementService.swift` — 新增 `fillFarmResults`

在 `markCompleted` switch 加入 `.farming` case：

```swift
case .farming:
    fillFarmResults(task)
```

```swift
private func fillFarmResults(_ task: TaskModel) {
    guard let seedType = MaterialType(rawValue: task.definitionKey) else { return }
    let tier = min(fetchPlayer()?.gatherer5Tier ?? 0, 3)
    let topThreshold:  [Double] = [0.02, 0.06, 0.12, 0.18]
    let highThreshold: [Double] = [0.20, 0.30, 0.40, 0.50]

    var rng = DeterministicRNG(seed: makeSeed(task: task))
    let baseYield = 4

    for _ in 0..<baseYield {
        let roll = rng.nextDouble()
        let isTop  = roll < topThreshold[tier]
        let isHigh = !isTop && roll < highThreshold[tier]

        switch seedType {
        case .wheatSeed:
            if isTop        { task.resultWheatTop  += 1 }
            else if isHigh  { task.resultWheatHigh += 1 }
            else            { task.resultWheat     += 1 }
        case .vegetableSeed:
            if isTop        { task.resultVegetableTop  += 1 }
            else if isHigh  { task.resultVegetableHigh += 1 }
            else            { task.resultVegetable     += 1 }
        case .fruitSeed:
            if isTop        { task.resultFruitTop  += 1 }
            else if isHigh  { task.resultFruitHigh += 1 }
            else            { task.resultFruit     += 1 }
        case .spiritGrainSeed:
            if isTop        { task.resultSpiritGrainTop  += 1 }
            else if isHigh  { task.resultSpiritGrainHigh += 1 }
            else            { task.resultSpiritGrain     += 1 }
        default: break
        }
    }
}
```

### `Services/TaskClaimService.swift` — 新增 `.farming` claim

仿 `.gather` 邏輯，讀取 12 個農作物 result 欄位，寫入 `MaterialInventoryModel`：

```swift
case .farming:
    let cropMaterials: [MaterialType] = [
        .wheat, .wheatHigh, .wheatTop,
        .vegetable, .vegetableHigh, .vegetableTop,
        .fruit, .fruitHigh, .fruitTop,
        .spiritGrain, .spiritGrainHigh, .spiritGrainTop
    ]
    for mat in cropMaterials {
        let amount = task.resultAmount(of: mat)
        if amount > 0 { inventory?.add(amount, of: mat) }
    }
```

### `Services/NpcUpgradeService.swift`

tier 遞增 switch 加入：

```swift
case "farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4":
    player.gatherer5Tier += 1
```

---

## UI

### 新建 `Views/FarmerPlotSheet.swift`

觸發條件：點擊閒置農田格子。

```
NavigationStack {
    List {
        Section("種子庫存") {
            ForEach([.wheatSeed, .vegetableSeed, .fruitSeed, .spiritGrainSeed]) { seed in
                HStack {
                    Text("\(seed.icon) \(seed.displayName)")
                    Spacer()
                    Text("\(inventory?.amount(of: seed) ?? 0)")
                }
            }
        }
        Section("選擇種子") {
            ForEach([...]) { seed in
                Button { selectedSeed = seed } label: { ... }
                    .disabled((inventory?.amount(of: seed) ?? 0) < 1)
            }
        }
        Section("種植時長") {
            Picker("時長", selection: $selectedDuration) {
                Text("30 分鐘").tag(1800)
                Text("2 小時").tag(7200)
                Text("8 小時").tag(28800)
            }
            .pickerStyle(.segmented)
        }
        Button("種下 \(selectedSeed?.displayName ?? "")") {
            plantSeed()
        }
        .disabled(selectedSeed == nil)
    }
    .navigationTitle("農田 \(plotIndex + 1)")
}
```

### `Views/BaseView.swift` — 採集 tab 新增農夫段落

```swift
private func npcFarmerSection() -> some View {
    Section("農夫") {
        let availablePlots = (player?.gatherer5Tier ?? 0) + 1
        ForEach(0..<availablePlots, id: \.self) { index in
            farmerPlotRow(plotIndex: index)
        }
        if (player?.gatherer5Tier ?? 0) < NpcUpgradeDef.maxTier {
            // 顯示升級提示
        }
    }
}
```

每個 `farmerPlotRow` 三態：
- **空閒**：顯示「農田 N — 點擊種植」→ 開啟 FarmerPlotSheet
- **生長中**：顯示進度條 + 倒數 + 種植種類 icon
- **可收穫**：高亮綠色 + 「點擊收下」→ claimAllCompleted

---

## 驗收標準

- [ ] 農夫在 BaseView 採集 tab 顯示
- [ ] 初始顯示 1 塊農田；升 Tier 後解鎖更多農田
- [ ] 點擊空閒農田開啟 FarmerPlotSheet，可選種子與時長
- [ ] 種下後庫存立即扣 1 顆種子，農田顯示生長中
- [ ] 各農田獨立計時，互不影響
- [ ] 時間到後農田高亮「可收穫」
- [ ] 收下後農作物（含品質）正確入庫
- [ ] Tier 0 時頂級作物出現率≈2%，Tier 3 時≈18%
- [ ] 農夫升 Tier 消耗正確種子+金幣，解鎖新農田
