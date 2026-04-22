# V7-1 Ticket 01：新採集地點 + 新採集 NPC

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

1. 新採集地點需要**擊敗對應區域的 Boss**才能解鎖
2. 新增兩種採集 NPC：採藥師 / 漁夫，各有自己的地點、素材、tier 系統

---

## 地點解鎖邏輯

解鎖條件使用 `requiredBossFloorKey: String?`，`nil` 表示初始可用。Boss 層 key 對應各區域第 4 層（`isBossFloor == true`）。

```swift
struct GatherLocationDef {
    // ... 現有欄位 ...
    let requiredBossFloorKey: String?  // e.g. "wildland_floor_4"，nil = 初始
}
```

判斷函式（放在 `GathererDetailSheet` 或 ViewModel）：

```swift
func isUnlocked(_ location: GatherLocationDef, player: PlayerStateModel) -> Bool {
    guard let required = location.requiredBossFloorKey else { return true }
    return player.clearedFloors.contains(required)
}
```

`player.clearedFloors` 為 `PlayerStateModel` 現有欄位（V2-1 起），記錄所有已通關樓層 key。

---

## 全地點規劃

### 伐木工（gatherer_1）

| key | 名稱 | 解鎖條件（Boss 通關）| 產出 | 數量 |
|---|---|---|---|---|
| `forest` | 森林 | 初始 | 木材 | 3...6 |
| `misty_jungle` | 霧靄叢林 | `wildland_floor_4` Boss | 木材 | 5...10 |
| `ancient_tree_reserve` | 古樹禁地 | `abandoned_mine_floor_4` Boss | 古木材 | 2...5 |
| `sunken_mangrove` | 沉城紅樹林 | `ancient_ruins_floor_4` Boss | 古木材 | 4...8 |

### 採礦工（gatherer_2）

| key | 名稱 | 解鎖條件（Boss 通關）| 產出 | 數量 |
|---|---|---|---|---|
| `mine_pit` | 礦坑 | 初始 | 礦石 | 2...5 |
| `deep_mine_shaft` | 深層礦道 | `wildland_floor_4` Boss | 礦石 | 4...9 |
| `lava_vein` | 熔岩礦脈 | `abandoned_mine_floor_4` Boss | 精煉礦石 | 1...4 |
| `sunken_ore_deposit` | 沉城礦層 | `ancient_ruins_floor_4` Boss | 精煉礦石 | 3...7 |

### 採藥師（gatherer_3，新 NPC）

| key | 名稱 | 解鎖條件（Boss 通關）| 產出 | 數量 |
|---|---|---|---|---|
| `herb_meadow` | 山野藥圃 | 初始 | 草藥 | 3...6 |
| `ruins_herb_garden` | 廢墟藥園 | `abandoned_mine_floor_4` Boss | 靈草 | 1...4 |
| `sunken_bloom_grove` | 沉城花圃 | `ancient_ruins_floor_4` Boss | 靈草 | 3...6 |

### 漁夫（gatherer_4，新 NPC）

| key | 名稱 | 解鎖條件（Boss 通關）| 產出 | 數量 |
|---|---|---|---|---|
| `border_stream` | 邊境溪流 | 初始 | 鮮魚 | 3...7 |
| `abyss_lake` | 深淵湖 | `abandoned_mine_floor_4` Boss | 深淵魚 | 1...4 |
| `sunken_harbor` | 沉城古港 | `ancient_ruins_floor_4` Boss | 深淵魚 | 3...6 |

---

## 新 NPC 定義

```swift
// 採藥師
GathererNpcDef(
    actorKey: "gatherer_3",
    name: "採藥師",
    icon: "leaf.fill",
    role: .herbalist,
    npcKind: .herbalist,
    locationKeys: ["herb_meadow", "ruins_herb_garden", "sunken_bloom_grove"]
)

// 漁夫
GathererNpcDef(
    actorKey: "gatherer_4",
    name: "漁夫",
    icon: "fish.fill",
    role: .fisherman,
    npcKind: .fisherman,
    locationKeys: ["border_stream", "abyss_lake", "sunken_harbor"]
)
```

新增 `GathererRole` case：`.herbalist` / `.fisherman`
新增 `NpcKind` case：`.herbalist` / `.fisherman`

---

## 新素材類型

| MaterialType case | 名稱 | 來源 |
|---|---|---|
| `.ancientWood` | 古木材 | 伐木工高階地點 |
| `.refinedOre` | 精煉礦石 | 採礦工高階地點 |
| `.herb` | 草藥 | 採藥師初始地點 |
| `.spiritHerb` | 靈草 | 採藥師高階地點 |
| `.freshFish` | 鮮魚 | 漁夫初始地點 |
| `.abyssFish` | 深淵魚 | 漁夫高階地點 |

---

## 資料模型變更

### MaterialInventoryModel（SwiftData，輕量遷移）

```swift
var ancientWood:  Int = 0
var refinedOre:   Int = 0
var herb:         Int = 0
var spiritHerb:   Int = 0
var freshFish:    Int = 0
var abyssFish:    Int = 0
```

### TaskModel（SwiftData，輕量遷移）

```swift
var resultAncientWood:  Int = 0
var resultRefinedOre:   Int = 0
var resultHerb:         Int = 0
var resultSpiritHerb:   Int = 0
var resultFreshFish:    Int = 0
var resultAbyssFish:    Int = 0
```

### PlayerStateModel（SwiftData，輕量遷移）

```swift
var gatherer3Tier: Int = 0   // 採藥師
var gatherer4Tier: Int = 0   // 漁夫
```

---

## 修改檔案

| 檔案 | 改動 |
|---|---|
| `StaticData/GatherLocationDef.swift` | 加 `requiredBossFloorKey`，新增所有地點 |
| `StaticData/GathererNpcDef.swift` | 新增 gatherer_3 / gatherer_4；新增 role / npcKind case |
| `StaticData/MaterialType.swift` | 新增 6 個 case |
| `StaticData/NpcUpgradeDef.swift` | 新增採藥師 / 漁夫的升級費用定義 |
| `Models/MaterialInventoryModel.swift` | 新增 6 欄位 |
| `Models/TaskModel.swift` | 新增 6 結果欄位；`resultAmount(of:)` 補對應 |
| `Models/PlayerStateModel.swift` | 新增 `gatherer3Tier` / `gatherer4Tier` 及 `tier(for:)` 補 case |
| `Services/SettlementService.swift` | `fillGatherResults` 補新 MaterialType case |
| `Services/TaskClaimService.swift` | `accumulateMaterials` 補新 MaterialType case |
| `Views/GathererDetailSheet.swift` | 地點列表依解鎖狀態篩選；未解鎖顯示灰色提示 |
| `Views/BaseView.swift` | NPC 列表新增採藥師 / 漁夫列；素材庫存顯示新素材 |

---

## 驗收標準

- [ ] 初始只顯示 forest / mine_pit / herb_meadow / border_stream
- [ ] 擊敗荒野邊境 Boss（`wildland_floor_4`）後，霧靄叢林、深層礦道解鎖
- [ ] 擊敗廢棄礦坑 Boss（`abandoned_mine_floor_4`）後，古樹禁地、熔岩礦脈、廢墟藥園、深淵湖解鎖
- [ ] 擊敗深淵遺跡 Boss（`ancient_ruins_floor_4`）後，沉城系地點全數解鎖
- [ ] 未解鎖地點顯示「需通關 [Boss 名稱]」灰色說明文字
- [ ] 採藥師 / 漁夫出現在 BaseView NPC 列表，可獨立派出任務
- [ ] 新素材採集後正確入庫並顯示在庫存
