# V4-1 Ticket 01：BattleLogGenerator（純計算層）

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

建立純計算層 `BattleLogGenerator`，重播確定性 RNG 生成每場戰鬥的事件文字陣列，供 V4-1 T03 BattleLogSheet 使用。

---

## 新建檔案

`Services/BattleLogGenerator.swift`

---

## 輸入

```swift
static func generate(
    task: TaskModel,
    floor: DungeonFloorDef,
    fromBattleIndex: Int
) -> [BattleEvent]
```

- `task`：進行中的地下城任務（含 `startedAt`、`id`、`snapshotPower`）
- `floor`：樓層靜態資料（含敵人 HP、ATK、DEF）
- `fromBattleIndex`：從第幾場開始生成（跳過已過去的場次）

---

## 輸出

`[BattleEvent]`，每個 event 包含：

```swift
struct BattleEvent {
    enum EventType {
        case enter        // 進入樓層描述
        case attack       // 英雄攻擊
        case damage       // 英雄受傷
        case victory      // 英雄勝利
        case defeat       // 英雄落敗
    }
    let type: EventType
    let description: String
    let heroHpAfter: Int
    let enemyHpAfter: Int
    let heroMaxHp: Int    // 每場首個 event 帶初始值，其餘場沿用
    let enemyMaxHp: Int
}
```

---

## 輔助方法

```swift
static func currentBattleIndex(for task: TaskModel) -> Int
```

計算方式：
```swift
let elapsed = Date.now.timeIntervalSince(task.startedAt)
let totalDuration = task.endsAt.timeIntervalSince(task.startedAt)
let secondsPerBattle: Double = 60  // 每場 1 分鐘模擬
let totalBattles = Int(totalDuration / secondsPerBattle)
return min(Int(elapsed / secondsPerBattle), max(0, totalBattles - 1))
```

---

## 事件描述模板（中文）

| 類型 | 模板 |
|---|---|
| enter | `"英雄踏入 \(floorName)…"` |
| attack | `"發動斬擊 → 造成 \(dmg) 傷害"` |
| damage | `"\(enemyName) 反擊 → 受到 \(dmg) 傷害"` |
| victory | `"⚔️ 戰勝 \(enemyName)！"` |
| defeat | `"💀 落敗於 \(enemyName)…"` |

---

## 實作細節

- 用 `DungeonSettlementEngine` 的相同 RNG seed 公式重播：
  `seed = UInt64(task.startedAt.timeIntervalSinceReferenceDate) ^ UInt64(bitPattern: task.id.hashValue)`
- 每場戰鬥用獨立 RNG offset（seed XOR battleIndex）確保每場結果一致
- **不修改任何 SwiftData，純計算，無副作用**
- 僅生成從 `fromBattleIndex` 開始的事件（不生成過去場次）

---

## 驗收標準

- [ ] `BattleLogGenerator.generate()` 回傳 `[BattleEvent]`，包含 HP 數值
- [ ] 相同輸入永遠回傳相同結果（確定性）
- [ ] `currentBattleIndex()` 回傳正確當前場次
- [ ] 不引入任何 `import SwiftData` 或 ModelContext
