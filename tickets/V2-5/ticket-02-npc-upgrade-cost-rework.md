# UX Ticket 02：NPC 升級費用改為 EXP + 素材 + 金幣

**狀態：** ✅ 完成

**依賴：** Ticket 01（`heroExp` 欄位 + EXP 入帳流程存在）

---

## 目標

NPC 升級目前只消耗金幣，決策維度單薄。
加入 EXP 與素材需求，使 NPC 升級產生更有意義的取捨：
- **EXP**：與英雄升級競爭同一資源池，逼玩家排優先序
- **素材**：採集者升級消耗採集素材（讓採集回饋明確）；鑄造師消耗鑄造用素材
- **金幣**：維持金幣作為次要門檻，但不再是唯一限制

---

## NpcUpgradeCostDef 擴充

**檔案：** `IdleBattleRPG/StaticData/NpcUpgradeDef.swift`

```swift
struct NpcUpgradeCostDef {
    let fromTier:      Int
    let expCost:       Int                         // ← 新增
    let materialCosts: [(MaterialType, Int)]       // ← 新增（可為空陣列）
    let goldCost:      Int
}
```

---

## 新成本表

### 採集者（×2 人，每人獨立付費）

| Tier | EXP | 素材 | 金幣 | 設計理由 |
|---|---|---|---|---|
| 0→1 | 60 | 木材 ×10 | 300 | 入門門檻低，用現有素材 |
| 1→2 | 180 | 礦石 ×10 | 800 | 礦石需要派遣採集，產生輕微等待 |
| 2→3 | 450 | 獸皮 ×8 | 1,800 | 獸皮來自地下城，需一定進度 |

### 鑄造師

| Tier | EXP | 素材 | 金幣 | 設計理由 |
|---|---|---|---|---|
| 0→1 | 80 | 礦石 ×10 | 400 | 鑄造師靠礦石，語意一致 |
| 1→2 | 250 | 魔晶石 ×5 | 1,200 | 需要地下城進度（廢棄礦坑解鎖後） |
| 2→3 | 700 | 古代碎片 ×3 | 2,500 | 深淵遺跡進度門檻，中後期獎勵 |

**靜態定義更新：**

```swift
static let gathererCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost:  60, materialCosts: [(.wood,  10)], goldCost:  300),
    .init(fromTier: 1, expCost: 180, materialCosts: [(.ore,   10)], goldCost:  800),
    .init(fromTier: 2, expCost: 450, materialCosts: [(.hide,   8)], goldCost: 1800),
]

static let blacksmithCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost:  80, materialCosts: [(.ore,          10)], goldCost:  400),
    .init(fromTier: 1, expCost: 250, materialCosts: [(.crystalShard,  5)], goldCost: 1200),
    .init(fromTier: 2, expCost: 700, materialCosts: [(.ancientFragment, 3)], goldCost: 2500),
]
```

便利查詢保持同名，回傳型別改為 `NpcUpgradeCostDef?`：

```swift
static func upgradeCost(npcKind: NpcKind, fromTier: Int) -> NpcUpgradeCostDef? {
    let costs = npcKind == .gatherer ? gathererCosts : blacksmithCosts
    return costs.first { $0.fromTier == fromTier }
}
// 舊的 goldCost(npcKind:fromTier:) 移除，改用上方方法
```

---

## 修改一：NpcUpgradeService

**檔案：** `IdleBattleRPG/Services/NpcUpgradeService.swift`

新增錯誤類型：

```swift
enum NpcUpgradeError: Error {
    case maxTierReached
    case insufficientExp(required: Int, have: Int)
    case insufficientMaterial(material: MaterialType, required: Int, have: Int)
    case insufficientGold(required: Int, have: Int)
}
```

`upgrade()` 改為三重驗證後原子扣除：

```swift
func upgrade(npcKind: NpcKind, actorKey: String, player: PlayerStateModel) -> Result<Void, NpcUpgradeError> {
    let currentTier = player.tier(for: actorKey)
    guard currentTier < NpcUpgradeDef.maxTier else { return .failure(.maxTierReached) }

    guard let cost = NpcUpgradeDef.upgradeCost(npcKind: npcKind, fromTier: currentTier) else {
        return .failure(.maxTierReached)
    }

    // 驗證 EXP
    guard player.heroExp >= cost.expCost else {
        return .failure(.insufficientExp(required: cost.expCost, have: player.heroExp))
    }

    // 驗證素材
    let inventory = fetchInventory()
    for (mat, required) in cost.materialCosts {
        let have = inventory?.amount(of: mat) ?? 0
        guard have >= required else {
            return .failure(.insufficientMaterial(material: mat, required: required, have: have))
        }
    }

    // 驗證金幣
    guard player.gold >= cost.goldCost else {
        return .failure(.insufficientGold(required: cost.goldCost, have: player.gold))
    }

    // 原子扣除
    player.heroExp -= cost.expCost
    player.gold    -= cost.goldCost
    for (mat, required) in cost.materialCosts {
        inventory?.add(-required, of: mat)   // 或呼叫 subtract()
    }

    // 更新 Tier
    switch npcKind {
    case .gatherer:   player.setTier(for: actorKey, tier: currentTier + 1)
    case .blacksmith: player.blacksmithTier = currentTier + 1
    }

    try? context.save()
    return .success(())
}
```

`nextUpgradeCost()` 回傳 `NpcUpgradeCostDef?`（替換現有 `Int?` 版本）：

```swift
func nextUpgradeCost(npcKind: NpcKind, actorKey: String, player: PlayerStateModel) -> NpcUpgradeCostDef? {
    let tier = player.tier(for: actorKey)
    guard tier < NpcUpgradeDef.maxTier else { return nil }
    return NpcUpgradeDef.upgradeCost(npcKind: npcKind, fromTier: tier)
}
```

---

## 修改二：BaseView NPC Row contextMenu

**檔案：** `IdleBattleRPG/Views/BaseView.swift`（`npcGathererRow` + `npcBlacksmithRow`）

contextMenu 改為顯示三項成本：

```swift
if let cost = appState.npcUpgradeService.nextUpgradeCost(...) {
    let canAffordExp  = player.heroExp >= cost.expCost
    let canAffordMat  = cost.materialCosts.allSatisfy { (mat, req) in
        (inventory?.amount(of: mat) ?? 0) >= req
    }
    let canAffordGold = player.gold >= cost.goldCost
    let canUpgrade    = canAffordExp && canAffordMat && canAffordGold

    let matDesc = cost.materialCosts.map { "\($0.0.icon)×\($0.1)" }.joined(separator: " ")
    let label   = "升級到 T\(tier + 1)（EXP \(cost.expCost) · \(matDesc) · \(cost.goldCost)金）"

    Button(canUpgrade ? label : label + "（資源不足）") {
        pendingUpgradeInfo = NpcUpgradeRequest(...)
    }
    .disabled(!canUpgrade)
}
```

---

## 修改三：BaseView 確認 Alert

**檔案：** `IdleBattleRPG/Views/BaseView.swift`（`.alert(item: $pendingUpgradeInfo)`）

Alert message 改為顯示三項成本：

```swift
// 修改 NpcUpgradeRequest 加入 cost: NpcUpgradeCostDef
Text("""
升級 \(info.label) 到 T\(info.nextTier)？
EXP：\(info.cost.expCost)（持有：\(player.heroExp)）
\(info.cost.materialCosts.map { "\($0.0.displayName) ×\($0.1)" }.joined(separator: "、"))
金幣：\(info.cost.goldCost)（持有：\(player.gold)）
""")
```

---

## MaterialInventoryModel subtract 支援

若 `add(-n, of:)` 不支援負數，需在 `MaterialInventoryModel` 確認或加入：

```swift
func subtract(_ amount: Int, of material: MaterialType) {
    add(-amount, of: material)   // 若 add() 支援負數則直接呼叫
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `StaticData/NpcUpgradeDef.swift` | ✏️ `NpcUpgradeCostDef` 擴充 + 成本表更新 |
| `Services/NpcUpgradeService.swift` | ✏️ 三重驗證 + 原子扣除 |
| `Views/BaseView.swift` | ✏️ contextMenu + Alert 顯示三項成本 |

---

## 驗收標準

- [ ] contextMenu 顯示「EXP X · 🪵×10 · 300金」格式
- [ ] 任一資源不足 → contextMenu 顯示「資源不足」、按鈕 disabled
- [ ] 升級成功 → EXP / 素材 / 金幣三者同時正確扣除
- [ ] Alert 顯示三項費用與目前持有量
- [ ] 滿 Tier 3 後不顯示升級選項
- [ ] Build 無錯誤
