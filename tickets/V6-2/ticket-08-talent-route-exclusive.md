# V6-2 Ticket 08：天賦路線互斥 + 節點多次投入（maxLevel）

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T05
**修改檔案：**
- `IdleBattleRPG/StaticData/TalentDef.swift`
- `IdleBattleRPG/Services/TalentService.swift`
- `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

兩大機制同步實作：

1. **路線互斥**：同一職業的 2 條天賦路線互斥，投入任一路線後另一路線全部鎖定。重置天賦（T06）後解除。
2. **節點多次投入**：每個節點依深度設有 `maxLevel`，可重複投入至上限，效果等比疊加。

---

## maxLevel 設計

每職業 2 路線 × (3+3+2+2+1) = 22 點才能全滿，Lv.20 只有 19 天賦點，玩家必須取捨。

| nodeIndex | maxLevel | 說明 |
|---|---|---|
| 0（N1） | 3 | 入門節點，可深度強化 |
| 1（N2） | 3 | 同上 |
| 2（N3） | 2 | 中階節點 |
| 3（N4） | 2 | 中階節點 |
| 4（N5） | 1 | Capstone，唯一一次 |

---

## TalentDef.swift 修改

### TalentNodeDef 新增欄位

```swift
struct TalentNodeDef {
    let key:         String
    let name:        String
    let description: String
    let routeKey:    String
    let nodeIndex:   Int
    let effects:     [TalentEffect]
    let maxLevel:    Int              // ← 新增
}
```

### 靜態資料更新（所有 40 個節點依 nodeIndex 設定 maxLevel）

```swift
// 規則：nodeIndex 0/1 → maxLevel 3；nodeIndex 2/3 → maxLevel 2；nodeIndex 4 → maxLevel 1
// 範例（其餘同理）：
TalentNodeDef(key: "sw_berserker_1", ..., nodeIndex: 0, effects: [...], maxLevel: 3)
TalentNodeDef(key: "sw_berserker_2", ..., nodeIndex: 1, effects: [...], maxLevel: 3)
TalentNodeDef(key: "sw_berserker_3", ..., nodeIndex: 2, effects: [...], maxLevel: 2)
TalentNodeDef(key: "sw_berserker_4", ..., nodeIndex: 3, effects: [...], maxLevel: 2)
TalentNodeDef(key: "sw_berserker_5", ..., nodeIndex: 4, effects: [...], maxLevel: 1)
```

### TalentNodeDef extension 新增便利查詢

```swift
extension TalentNodeDef {
    /// 玩家對此節點目前的投入次數
    func currentLevel(in player: PlayerStateModel) -> Int {
        player.investedTalentKeys.filter { $0 == key }.count
    }

    /// 是否已達投入上限
    func isMaxed(in player: PlayerStateModel) -> Bool {
        currentLevel(in: player) >= maxLevel
    }
}
```

---

## 儲存格式（沿用現有，允許重複 key）

`investedTalentKeysRaw` 允許同一 key 出現多次，表示多次投入：

```
"sw_berserker_1,sw_berserker_1,sw_berserker_2"
→ N1 投入 2 次、N2 投入 1 次
```

`investedTalentKeys` 計算屬性（`split → map → filter`）無需修改，重複 key 自然保留。
`HeroStats.applying(talentNodes:)` 對每次出現的 key 各套用一次效果，天然疊加。

---

## TalentService 修改

### TalentError 更新

```swift
enum TalentError: LocalizedError {
    case noPointsAvailable
    case nodeNotFound
    case maxLevelReached             // ← 取代 alreadyInvested
    case previousNodeNotInvested
    case routeLocked                 // ← 新增：路線互斥鎖定

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable:       return "沒有可用的天賦點"
        case .nodeNotFound:            return "找不到天賦節點"
        case .maxLevelReached:         return "此天賦節點已達投入上限"
        case .previousNodeNotInvested: return "需先解鎖前一個節點"
        case .routeLocked:             return "此路線已被互斥鎖定，請先重置天賦"
        }
    }
}
```

### canInvest 更新

```swift
func canInvest(nodeKey: String, for player: PlayerStateModel) -> Bool {
    guard player.availableTalentPoints > 0 else { return false }
    guard let node = TalentNodeDef.find(key: nodeKey) else { return false }

    // 節點等級上限
    guard !node.isMaxed(in: player) else { return false }

    // 路線互斥：若玩家已在此職業的另一條路線投入，則鎖定
    let routes = TalentRouteDef.all(for: player.classKey)
    for other in routes where other.key != node.routeKey {
        let hasInvestedInOther = other.nodes.contains {
            player.investedTalentKeys.contains($0.key)
        }
        if hasInvestedInOther { return false }
    }

    // 前置節點（需 ≥ 1 次投入）
    if node.nodeIndex == 0 { return true }
    guard let route = TalentRouteDef.find(key: node.routeKey) else { return false }
    let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
    guard let prev = prevNode else { return false }
    return player.investedTalentKeys.contains(prev.key)
}
```

### investPoint 更新

```swift
func investPoint(nodeKey: String, for player: PlayerStateModel) throws {
    guard player.availableTalentPoints > 0 else { throw TalentError.noPointsAvailable }
    guard let node = TalentNodeDef.find(key: nodeKey) else { throw TalentError.nodeNotFound }
    guard !node.isMaxed(in: player) else { throw TalentError.maxLevelReached }

    // 路線互斥檢查
    let routes = TalentRouteDef.all(for: player.classKey)
    for other in routes where other.key != node.routeKey {
        let hasInvestedInOther = other.nodes.contains {
            player.investedTalentKeys.contains($0.key)
        }
        if hasInvestedInOther { throw TalentError.routeLocked }
    }

    // 前置節點檢查（需 ≥ 1 次投入）
    if node.nodeIndex > 0 {
        guard let route = TalentRouteDef.find(key: node.routeKey) else {
            throw TalentError.nodeNotFound
        }
        let prevNode = route.nodes.first { $0.nodeIndex == node.nodeIndex - 1 }
        guard let prev = prevNode,
              player.investedTalentKeys.contains(prev.key) else {
            throw TalentError.previousNodeNotInvested
        }
    }

    player.availableTalentPoints -= 1
    player.investedTalentKeysRaw = (player.investedTalentKeys + [nodeKey]).joined(separator: ",")

    try context.save()
}
```

---

## CharacterView UI 更新

### 節點投入次數顯示

```swift
// talentNodeRow 中：已投入次數 "N/maxLevel"
let invested = node.currentLevel(in: player)

// 狀態判斷
let isMaxed   = node.isMaxed(in: player)
let canInvest = appState.talentService.canInvest(nodeKey: node.key, for: player)
let isLocked  = !canInvest && !isMaxed && player.availableTalentPoints > 0
                && !player.investedTalentKeys.isEmpty // 路線互斥
```

| 狀態 | 圓點 | 右側顯示 |
|---|---|---|
| 已達上限（isMaxed） | 🟢 綠 | `"已滿 \(invested)/\(node.maxLevel)"` |
| 可投入（canInvest） | 🔵 藍 | `"\(invested)/\(node.maxLevel)"` + 投入按鈕 |
| 前置未解鎖 | ⬜ 灰 | 🔒 |
| 路線互斥鎖定 | ⬜ 灰 | `"路線互斥"` 小字 |

### 路線互斥提示

若整條路線被互斥鎖定，在 Section header 顯示：

```swift
Section {
    // ... 節點列表（全灰化）
} header: {
    HStack {
        Text(route.name)
        Spacer()
        if isRouteLocked {
            Label("互斥鎖定", systemImage: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

## 驗收標準

- [ ] `TalentNodeDef.maxLevel` 依 nodeIndex 正確設定（0/1→3, 2/3→2, 4→1）
- [ ] 同節點可連續投入至 maxLevel，每次 -1 天賦點
- [ ] 投入路線 A 任一節點後，路線 B 全部節點鎖定（`canInvest` 回傳 false）
- [ ] 路線 B 的 Section 顯示「互斥鎖定」提示
- [ ] 已達 maxLevel 的節點：顯示「已滿 N/N」，無投入按鈕
- [ ] 前置節點只需投入 ≥ 1 次即可解鎖下一節點
- [ ] `HeroStats` 效果正確疊加（N1 投入 3 次 = 效果 × 3）
- [ ] `xcodebuild` 通過，無新警告
