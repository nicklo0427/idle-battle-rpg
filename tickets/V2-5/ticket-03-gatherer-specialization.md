# V2-5 Ticket 03：採集者職業化

**狀態：** ✅ 完成

**依賴：** 無（Ticket 04 依賴本票）

---

## 目標

目前兩位採集者為無名泛用角色（「採集者 1」/ 「採集者 2」），可前往任何地點，缺乏身份感。
改為各有專職：**伐木工**（森林系地點）和 **採礦工**（礦坑系地點），
各自只能前往對應類型的地點，為日後擴充更多職業預留架構。

---

## 靜態資料設計

### 1. GathererRole 枚舉

**檔案：** `IdleBattleRPG/StaticData/GatherLocationDef.swift`（或新建 `GathererNpcDef.swift`）

```swift
enum GathererRole: String {
    case woodcutter  // 伐木工
    case miner       // 採礦工
}
```

### 2. GathererNpcDef（新增）

**檔案：** `IdleBattleRPG/StaticData/GathererNpcDef.swift`（新檔）

```swift
struct GathererNpcDef {
    let actorKey:     String
    let name:         String
    let icon:         String          // SF Symbol 名稱
    let role:         GathererRole
    let locationKeys: [String]        // 可前往的地點 key 列表
}

extension GathererNpcDef {
    static let all: [GathererNpcDef] = [
        GathererNpcDef(
            actorKey:     "gatherer_1",
            name:         "伐木工",
            icon:         "tree.fill",
            role:         .woodcutter,
            locationKeys: ["forest"]
        ),
        GathererNpcDef(
            actorKey:     "gatherer_2",
            name:         "採礦工",
            icon:         "mountain.2.fill",
            role:         .miner,
            locationKeys: ["mine_pit"]
        ),
    ]

    static func find(actorKey: String) -> GathererNpcDef? {
        all.first { $0.actorKey == actorKey }
    }
}
```

### 3. GatherLocationDef 加 role 標籤

**檔案：** `IdleBattleRPG/StaticData/GatherLocationDef.swift`

```swift
struct GatherLocationDef {
    let key:             String
    let name:            String
    let role:            GathererRole   // ← 新增
    let durationOptions: [Int]
    let outputMaterial:  MaterialType
    let outputRange:     ClosedRange<Int>

    var shortestDuration: Int { durationOptions.first ?? 1800 }
}
```

靜態資料補上 `role`：

```swift
GatherLocationDef(
    key:             "forest",
    name:            "森林",
    role:            .woodcutter,
    durationOptions: [60, 300, 7200],
    outputMaterial:  .wood,
    outputRange:     3...6
),
GatherLocationDef(
    key:             "mine_pit",
    name:            "礦坑",
    role:            .miner,
    durationOptions: [60, 300, 10800],
    outputMaterial:  .ore,
    outputRange:     2...5
),
```

---

## NpcUpgradeDef 調整

**檔案：** `IdleBattleRPG/StaticData/NpcUpgradeDef.swift`

`NpcKind` 改為對應職業：

```swift
enum NpcKind: String, CaseIterable {
    case woodcutter   // 伐木工（原 gatherer）
    case miner        // 採礦工（原 gatherer）
    case blacksmith
}
```

`NpcUpgradeDef` 各 NPC 獨立成本表（職業不同，升級需求不同）：

```swift
static let woodcutterCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost:  60, materialCosts: [(.wood,  10)], goldCost:  300),
    .init(fromTier: 1, expCost: 180, materialCosts: [(.wood,  20)], goldCost:  800),
    .init(fromTier: 2, expCost: 450, materialCosts: [(.wood,  40)], goldCost: 1800),
]

static let minerCosts: [NpcUpgradeCostDef] = [
    .init(fromTier: 0, expCost:  60, materialCosts: [(.ore,   10)], goldCost:  300),
    .init(fromTier: 1, expCost: 180, materialCosts: [(.ore,   20)], goldCost:  800),
    .init(fromTier: 2, expCost: 450, materialCosts: [(.ore,   40)], goldCost: 1800),
]
```

升級加成語意改為職業導向：
- 伐木工 Tier 加成：每次採集 +N 木材
- 採礦工 Tier 加成：每次採集 +N 礦石

（`gatherBonus(tier:)` 邏輯不變，加成仍套用在 `resultAmount` 上）

`upgradeCost(npcKind:fromTier:)` 對應新 NpcKind：

```swift
static func upgradeCost(npcKind: NpcKind, fromTier: Int) -> NpcUpgradeCostDef? {
    switch npcKind {
    case .woodcutter:  return woodcutterCosts.first  { $0.fromTier == fromTier }
    case .miner:       return minerCosts.first       { $0.fromTier == fromTier }
    case .blacksmith:  return blacksmithCosts.first  { $0.fromTier == fromTier }
    }
}
```

---

## PlayerStateModel 調整

**檔案：** `IdleBattleRPG/Models/PlayerStateModel.swift`

`tier(for:)` 對應不變（仍以 `actorKey` 區分），但新增一個 `npcKind(for:)` 便利方法：

```swift
func npcKind(for actorKey: String) -> NpcKind? {
    switch actorKey {
    case "gatherer_1": return .woodcutter
    case "gatherer_2": return .miner
    case "blacksmith":  return .blacksmith
    default:            return nil
    }
}
```

---

## BaseView 顯示調整

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

NPC 列表改為讀 `GathererNpcDef.all` 動態生成，而不是 hardcode 兩個：

```swift
ForEach(GathererNpcDef.all, id: \.actorKey) { npc in
    npcGathererRow(def: npc, player: players.first, ...)
}
```

`npcGathererRow` 的 icon 改用 `npc.icon`，名稱改用 `npc.name`：

```swift
Image(systemName: npc.icon)
    .foregroundStyle(Color.green.opacity(isBusy ? 0.4 : 1.0))
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `StaticData/GathererNpcDef.swift` | ✅ 新增（GathererRole + GathererNpcDef） |
| `StaticData/GatherLocationDef.swift` | ✏️ 修改（加 `role` 欄位） |
| `StaticData/NpcUpgradeDef.swift` | ✏️ 修改（NpcKind 改名、各職業獨立成本表） |
| `Models/PlayerStateModel.swift` | ✏️ 修改（新增 `npcKind(for:)` 便利方法） |
| `Views/BaseView.swift` | ✏️ 修改（動態讀 GathererNpcDef，更新 icon/name） |

---

## 驗收標準

- [ ] BaseView NPC 列表顯示「伐木工」/ 「採礦工」及對應 icon
- [ ] 伐木工只能前往森林（地點列表只顯示 forest）
- [ ] 採礦工只能前往礦坑（地點列表只顯示 mine_pit）
- [ ] 兩位升級成本表各自獨立，素材需求對應職業
- [ ] Build 無錯誤
