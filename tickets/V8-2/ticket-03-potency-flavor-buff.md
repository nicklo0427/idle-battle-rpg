# V8-2 Ticket 03：料理 Buff + 藥水回復強化（ch_flavor + ph_potency）

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

讓廚師的「廚藝精進（ch_flavor）」與製藥師的「精煉藥劑（ph_potency）」在戰鬥中實際生效。

| 技能 | key | 效果 | 實作難度 |
|------|-----|------|----------|
| 廚藝精進 | `ch_flavor` | 每點提升料理 ATK/DEF/HP 加成 10% | 低（只改 `generate` 3 行） |
| 精煉藥劑 | `ph_potency` | 每點提升藥水 HP 回復量 10% | 中（需穿透 3 層函式，但預設值保護現有呼叫端）|

---

## 修改細節

### Step 1：`Models/TaskModel.swift` — 新增兩個快照欄位

```swift
// V8-2 T03：生產者效果技能快照
var snapshotChFlavorLevel:  Int = 0   // ch_flavor 等級（出征時廚師技能）
var snapshotPhPotencyLevel: Int = 0   // ph_potency 等級（出征時製藥師技能）
```

SwiftData 輕量遷移，預設值 `0` 等同無技能，舊存檔完全相容。

### Step 2：`Services/TaskCreationService.swift` — `createDungeonTask`

在設定 `snapshotCuisineKey` / `snapshotPotionKey` 之後，一並寫入技能快照：

```swift
task.snapshotChFlavorLevel  = player.skillLevel(nodeKey: "ch_flavor",  actorKey: "chef")
task.snapshotPhPotencyLevel = player.skillLevel(nodeKey: "ph_potency", actorKey: "pharmacist")
```

### Step 3-A：`Services/BattleLogGenerator.swift` — ch_flavor（`generate` 內直接套用）

料理加成在 `generate` 函式的 line 132–136 套用，直接在這裡讀 `task.snapshotChFlavorLevel`
並乘上乘數，**無需修改 `makeBattleEvents` 或 `runCombatCore` 簽名**：

```swift
// 現況
if let cuisine = cuisineDef {
    heroAtk   += cuisine.atkBonus
    heroDef   += cuisine.defBonus
    heroMaxHp += cuisine.hpBonus
}

// 修改後
if let cuisine = cuisineDef {
    let flavorMultiplier = 1.0 + Double(task.snapshotChFlavorLevel) * 0.10
    heroAtk   += Int(Double(cuisine.atkBonus) * flavorMultiplier)
    heroDef   += Int(Double(cuisine.defBonus) * flavorMultiplier)
    heroMaxHp += Int(Double(cuisine.hpBonus)  * flavorMultiplier)
}
```

> `AdventureView` 的兩個 `BattleLogGenerator.generate` 呼叫也傳入同一個 `task`，
> 會自動讀到 `snapshotChFlavorLevel`，不需要額外修改。

### Step 3-B：`Services/BattleLogGenerator.swift` — ph_potency（穿透三層，預設值保護）

藥水回復在 `runCombatCore` 內觸發（`heroHp < heroMaxHp / 2` 時），需把 potencyLevel
從 `generate` → `makeBattleEvents` → `runCombatCore` 一路傳遞。
全部加 `potencyLevel: Int = 0` 預設值，現有呼叫端（`DungeonSettlementEngine`、`EliteBattleEngine`）零改動。

#### `makeBattleEvents` 簽名加參數

```swift
private static func makeBattleEvents(
    // ... 現有參數 ...
    potionDef:    PotionDef? = nil,
    potencyLevel: Int = 0          // ← 新增
) -> [BattleEvent]
```

在 `generate` 呼叫 `makeBattleEvents` 的地方，加入：

```swift
allEvents += makeBattleEvents(
    // ... 現有參數 ...
    potionDef:    potionDef,
    potencyLevel: task.snapshotPhPotencyLevel   // ← 新增
)
```

#### `runCombatCore` 簽名加參數

```swift
internal static func runCombatCore(
    // ... 現有參數 ...
    potionDef:    PotionDef? = nil,
    potencyLevel: Int = 0          // ← 新增
) -> CombatOutcome
```

在 `makeBattleEvents` 呼叫 `runCombatCore` 的地方，加入：

```swift
let outcome = runCombatCore(
    // ... 現有參數 ...
    potionDef:    potionDef,
    potencyLevel: potencyLevel     // ← 新增
)
```

#### `runCombatCore` 內部套用乘數

找到藥水回復段落（目前 line 293–300）：

```swift
// 現況
if let potion = potionDef, !potionUsed, heroHp < heroMaxHp / 2, heroHp > 0 {
    potionUsed = true
    let healed = Int(Double(heroMaxHp) * potion.healPercent)
    heroHp = min(heroMaxHp, heroHp + healed)
    ...
}

// 修改後（healPercent 是 Double 比例，非固定 HP 數值）
if let potion = potionDef, !potionUsed, heroHp < heroMaxHp / 2, heroHp > 0 {
    potionUsed = true
    let potencyMultiplier = 1.0 + Double(potencyLevel) * 0.10
    let healed = Int(Double(heroMaxHp) * potion.healPercent * potencyMultiplier)
    heroHp = min(heroMaxHp, heroHp + healed)
    ...
}
```

> **注意**：欄位是 `potion.healPercent: Double`（回復比例），不是 `hpRecovery`。
> Lv0 時 `potencyMultiplier = 1.0`，行為與現在完全相同。

---

## 設計決策記錄

| 議題 | 決策 | 理由 |
|------|------|------|
| ch_flavor 套用位置 | `generate` 內直接修改 `heroAtk/heroDef/heroMaxHp` | 料理加成在此計算，無需動下游簽名 |
| ph_potency 傳遞方式 | 預設值 `= 0` 加入 `makeBattleEvents` + `runCombatCore` | 現有呼叫端零改動，Lv0 行為完全一致 |
| DungeonSettlementEngine | 不傳 potencyLevel，維持現狀 | Settlement Engine 同樣不含 cuisineDef/potionDef，是已接受的設計；地城結算由 DungeonBattleSheet 即時執行 |
| AdventureView 的 generate 呼叫 | 不需額外修改 | 已傳入 task，自動讀 snapshotChFlavorLevel |
| `healPercent` vs `hpRecovery` | 使用實際欄位 `potion.healPercent: Double` | PotionDef 沒有 `hpRecovery` 欄位 |

---

## 修改檔案

- `Models/TaskModel.swift`
- `Services/TaskCreationService.swift`
- `Services/BattleLogGenerator.swift`（`generate`、`makeBattleEvents`、`runCombatCore`）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 新欄位 SwiftData 輕量遷移成功（舊存檔預設 0，行為不變）
- [ ] ch_flavor Lv0：料理加成與現在完全相同
- [ ] ch_flavor Lv1：料理 ATK/DEF/HP 加成 ×1.10
- [ ] ch_flavor Lv3：料理加成 ×1.30
- [ ] ph_potency Lv0：藥水回復與現在完全相同
- [ ] ph_potency Lv1：`healPercent × 1.10`（例：30% → 33%）
- [ ] ph_potency Lv3：`healPercent × 1.30`（例：30% → 39%）
- [ ] `DungeonSettlementEngine` / `EliteBattleEngine` / `BattleLogGenerator.runCombat` 的現有呼叫端編譯無錯誤（預設值保護）
- [ ] `AdventureView` 的兩個 `generate` 呼叫自動繼承 ch_flavor 效果
