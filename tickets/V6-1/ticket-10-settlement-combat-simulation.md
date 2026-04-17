# V6-1 Ticket 10：結算引擎改為完整戰鬥模擬（方案 B）

**狀態：** 🔲 待實作
**版本：** V6-1（修訂）
**依賴：** T07、T08 完成
**修改檔案：**
- `IdleBattleRPG/Services/BattleLogGenerator.swift`（提取共用戰鬥函式 + 拆分 seed）
- `IdleBattleRPG/Services/DungeonSettlementEngine.swift`（改用戰鬥模擬取代 winRate 公式）

---

## 背景

T08 在 `BattleLogGenerator`（視覺敘事層）實作了主動技能觸發，
但 `DungeonSettlementEngine`（實際結算層）仍使用 `winRate` 機率公式，
導致技能對真實勝負、金幣、素材毫無影響。

方案 B：讓結算引擎跑與戰鬥記錄相同的逐回合戰鬥模擬，
技能在其中真實觸發，結算 win/loss 由模擬結果決定。

---

## 設計規格

### 核心問題：Seed 對齊

`BattleLogGenerator` 目前用同一個 per-battle RNG 處理探索文字選取與戰鬥，
導致探索 RNG 消耗量影響戰鬥時的 RNG 狀態。
結算引擎若只想跑戰鬥（不需要探索文字），需要對齊 RNG 狀態，否則勝負會不一致。

**解法：拆分 seed — 探索 seed 與戰鬥 seed 獨立**

```
exploreRng = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1))
             ↑ 供 BattleLogGenerator 探索 / 遭遇文字選取使用（不影響戰鬥）

combatRng  = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42)
             ↑ 供戰鬥回合（crit / damage variance / 技能觸發 crit）使用
             ↑ 供 DungeonSettlementEngine 結算 win/loss 使用（相同 seed → 相同結果）
```

**常數 `0x434F4D42`** = "COMB" 的 ASCII hex，用於區分探索與戰鬥兩條 seed 分支。

---

### 新增：`CombatSimulator.swift`（或作為 `BattleLogGenerator` 的 extension）

提取純戰鬥模擬函式，供 **BattleLogGenerator** 和 **DungeonSettlementEngine** 共用：

```swift
struct CombatOutcome {
    let heroSurvived: Bool   // true = 英雄存活（勝利）
}

extension BattleLogGenerator {

    /// 純戰鬥結果計算（無 event，供結算引擎使用）
    static func runCombat(
        rng:            inout DeterministicRNG,
        heroMaxHp:      Int,
        heroAtk:        Int,
        heroDef:        Int,
        heroChargeTime: Double,
        critRate:       Double,
        activeSkills:   [SkillDef],
        enemyMaxHp:     Int,
        enemyAtk:       Int,
        enemyDef:       Int,
        enemyChargeTime: Double
    ) -> CombatOutcome

}
```

`runCombat` 實作與 `makeBattleEvents` 的戰鬥回合邏輯完全相同（冷卻計時、技能觸發、heroAtkMultiplier / enemyAtkMultiplier），但不建立任何 `BattleEvent`，只回傳 `heroSurvived`。

---

### 修改：`BattleLogGenerator.makeBattleEvents()`

- 探索 / 遭遇文字：繼續使用 `rng`（per-battle seed，不變）
- 戰鬥回合：改為使用 `combatRng`（= `rng` 的兄弟 seed）

```swift
// 現在（一條 rng 包辦一切）
var rng = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1))

// 改為（探索 vs 戰鬥分開）
var exploreRng = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1))
var combatRng  = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42)
```

探索文字選取改用 `exploreRng`，戰鬥回合改用 `combatRng`。
勝利後金幣 `gold = exploreRng.nextInt(in: floor.goldPerBattleRange)`（維持視覺一致）。

---

### 修改：`DungeonSettlementEngine.settle(task:floor:)`（V2-1 路徑）

移除 `winRate` 公式，改為：

```swift
// 1. 英雄戰鬥數值（與 BattleLogGenerator 相同公式）
let snapshotPower = task.snapshotPower ?? 50
let snapshotAgi   = task.snapshotAgi   ?? 0
let snapshotDex   = task.snapshotDex   ?? 0

let heroMaxHp      = max(50, snapshotPower * 2)
let heroAtk        = max(10, snapshotPower / 4)
let heroDef        = max(5,  snapshotPower / 10)
let heroChargeTime = max(0.6, 1.8 - Double(snapshotAgi) * 0.06)
let critRate       = min(0.35, Double(snapshotDex) * 0.035)

let enemyMaxHp      = max(30, floor.recommendedPower * 2)
let enemyAtk        = max(8,  floor.recommendedPower / 4)
let enemyDef        = max(3,  floor.recommendedPower / 10)
let enemyChargeTime = max(0.8, 2.0 - Double(floor.recommendedPower) * 0.001)

let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

// 2. task seed（同 BattleLogGenerator）
let tBits    = task.startedAt.timeIntervalSinceReferenceDate.bitPattern
let hBits    = UInt64(bitPattern: Int64(truncatingIfNeeded: task.id.hashValue))
let taskSeed = tBits ^ hBits

// 3. 逐場結算（用 combatRng 跑模擬，用 settlementRng 算金幣 / 素材）
var settlementRng = DeterministicRNG(task: task)   // 金幣 / 素材專用 RNG（維持原有隨機性）
var won = 0, lost = 0
var gold: Int = 0
var materials: [MaterialType: Int] = [:]

for battleIndex in 0..<totalBattles {
    var combatRng = DeterministicRNG(
        seed: taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42
    )

    let outcome = BattleLogGenerator.runCombat(
        rng:             &combatRng,
        heroMaxHp:       heroMaxHp,
        heroAtk:         heroAtk,
        heroDef:         heroDef,
        heroChargeTime:  heroChargeTime,
        critRate:        critRate,
        activeSkills:    activeSkills,
        enemyMaxHp:      enemyMaxHp,
        enemyAtk:        enemyAtk,
        enemyDef:        enemyDef,
        enemyChargeTime: enemyChargeTime
    )

    if outcome.heroSurvived {
        won  += 1
        gold += settlementRng.nextInt(in: floor.goldPerBattleRange)

        for entry in floor.dropTable {
            if settlementRng.nextDouble() < entry.dropRate {
                materials[entry.material, default: 0] += settlementRng.nextInt(in: entry.quantityRange)
            }
        }
    } else {
        lost += 1
        gold += Int(Double(floor.goldPerBattleRange.lowerBound) * 0.2)
    }
}
```

### 修改：`DungeonSettlementEngine.settle(task:area:)`（V1 路徑）

同上邏輯，但使用 `DungeonAreaDef` 的 `recommendedPower` 和 `dropTable`。

---

## 影響評估

### 勝負一致性
戰鬥記錄與結算使用相同 `combatRng` seed → 相同技能 → 相同 RNG 序列 → **勝負一致**。

### 金幣數字不一致（可接受）
- 戰鬥記錄顯示的金幣：`exploreRng.nextInt(in: goldPerBattleRange)`（視覺用）
- 結算實際入帳金幣：`settlementRng.nextInt(in: goldPerBattleRange)`（獨立 RNG）
- 兩者原本就是不同 RNG，這個差異**已存在於重設計前**，玩家沒有注意到，**可接受**。

### 效能
| 情境 | 現在 | 方案 B |
|---|---|---|
| 12 小時 × 720 場 | 720 × ~3 RNG calls = 2K calls | 720 × ~100 RNG calls = 72K calls |
| 預估時間 | < 1ms | < 20ms（仍在 main thread 可接受範圍） |

---

## 不需要修改的檔案

- `SettlementService.swift` — 呼叫 `DungeonSettlementEngine.settle()` 介面不變
- `TaskModel.swift` — 不需要新欄位
- `HeroStats.swift` — `winRate` 靜態方法可保留（V1 路徑仍用）或廢棄
- `BattleLogSheet.swift` / `BattleLogPlaybackModel.swift` — 不變

---

## 實作順序

1. **`BattleLogGenerator.swift`**
   - 新增 `CombatOutcome` struct
   - 新增 `runCombat(rng:...)` static func（從 `makeBattleEvents` 戰鬥回合提取）
   - `makeBattleEvents` 拆分 seed：探索用 `rng`（不變），戰鬥改用 `combatRng`

2. **`DungeonSettlementEngine.swift`**
   - V2-1 `settle(task:floor:)` 改用 `runCombat`
   - V1 `settle(task:area:)` 改用 `runCombat`

3. **Build + 驗收**

---

## 驗收標準

- [ ] `xcodebuild` 通過
- [ ] 戰鬥記錄顯示技能觸發事件（如「【重斬擊】對礦穴巨魔造成 75 傷害」）
- [ ] 戰鬥記錄中英雄 HP 歸零 → 結算為敗場（一致）
- [ ] 戰鬥記錄中英雄存活 → 結算為勝場（一致）
- [ ] 技能強（如多個傷害技能）→ 實際勝場數比沒有技能時更多（可用 Dev 工具驗證）
- [ ] 結算不崩潰（720 場長時間出征正常結算）
