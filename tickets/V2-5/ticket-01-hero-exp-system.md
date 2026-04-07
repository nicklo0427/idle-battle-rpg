# UX Ticket 01：英雄升級改為經驗值系統

**狀態：** ✅ 完成

**依賴：** 無（第一張）

---

## 目標

英雄升級目前消耗金幣，導致金幣同時服務於：升級、強化、NPC 升級、商人，
競爭過多、決策不清晰。
改為消耗「英雄經驗值（EXP）」，EXP 從地下城戰鬥中取得，
讓升級與戰鬥進度直接掛鉤，金幣則專注服務於裝備系統與 NPC。

---

## EXP 設計規格

### EXP 來源

| 情境 | EXP |
|---|---|
| 地下城勝場 | `max(1, floor.recommendedPower / 10)` |
| 地下城敗場 | 1（固定，鼓勵嘗試） |

範例（荒野 Boss，推薦戰力 160）：
- 勝場：16 EXP
- 15 分鐘局（~8 場，88% 勝率）≈ **113 EXP**

### 升級所需 EXP（累計）

> EXP 為消耗型（花掉升等，不累計顯示）；門檻為「升至下一等級所需」。

| 目標等級 | 所需 EXP |
|---|---|
| Lv.2 | 100 |
| Lv.3 | 200 |
| Lv.4 | 300 |
| Lv.5 | 450 |
| Lv.6 | 600 |
| Lv.7 | 800 |
| Lv.8 | 1,000 |
| Lv.9 | 1,300 |
| Lv.10 | 1,600 |

荒野 Boss 15 分鐘局約 113 EXP：Lv.1→10 合計 6,350 EXP ≈ **56 局 ≈ 14 小時**（合理長線進程）

---

## 修改一：PlayerStateModel

**檔案：** `IdleBattleRPG/Models/PlayerStateModel.swift`

```swift
var heroExp: Int = 0   // 當前持有 EXP（消耗型，升級後扣除）
```

---

## 修改二：TaskModel

**檔案：** `IdleBattleRPG/Models/TaskModel.swift`

```swift
var resultExp: Int = 0   // 地下城任務結算後獲得的 EXP（.gather / .craft 恆為 0）
```

---

## 修改三：DungeonSettlementEngine

**檔案：** `IdleBattleRPG/Services/DungeonSettlementEngine.swift`

`FloorDungeonResult` 加入 `exp: Int`：

```swift
struct FloorDungeonResult {
    let gold:        Int
    let materials:   [MaterialType: Int]
    let battlesWon:  Int
    let battlesLost: Int
    let exp:         Int          // ← 新增
    let rolledBossWeapon: (equipKey: String, atk: Int)?
}
```

`settle(task:floor:)` 計算 EXP：

```swift
let expPerWin  = max(1, floor.recommendedPower / 10)
let totalExp   = won * expPerWin + lost * 1
// 在 return FloorDungeonResult(...) 中加入 exp: totalExp
```

---

## 修改四：SettlementService

**檔案：** `IdleBattleRPG/Services/SettlementService.swift`

在 `commitResults()` 將 engine 產出的 `exp` 寫入 `task.resultExp`：

```swift
task.resultExp = result.exp
```

---

## 修改五：TaskClaimService

**檔案：** `IdleBattleRPG/Services/TaskClaimService.swift`

在 `claimAllCompleted()` 入帳時累加 EXP：

```swift
// 加在 creditGold() 呼叫旁
let totalExp = completed.reduce(0) { $0 + $1.resultExp }
if totalExp > 0 { creditExp(totalExp) }
```

新增 `creditExp()` private helper：

```swift
private func creditExp(_ amount: Int) {
    guard amount > 0 else { return }
    let descriptor = FetchDescriptor<PlayerStateModel>()
    guard let player = (try? context.fetch(descriptor))?.first else { return }
    player.heroExp += amount
}
```

---

## 修改六：AppConstants

**檔案：** `IdleBattleRPG/AppConstants.swift`

移除 `UpgradeCost.gold(toLevel:)`，改為：

```swift
enum ExpThreshold {
    private static let table: [Int: Int] = [
        2: 100, 3: 200, 4: 300, 5: 450,
        6: 600, 7: 800, 8: 1000, 9: 1300, 10: 1600
    ]
    /// 升至目標等級所需 EXP；超出範圍回傳 nil
    static func required(toLevel level: Int) -> Int? {
        table[level]
    }
}
```

---

## 修改七：CharacterProgressionService

**檔案：** `IdleBattleRPG/Services/CharacterProgressionService.swift`

`LevelUpError` 新增 EXP 不足：

```swift
case insufficientExp(required: Int, have: Int)
```

`levelUp()` 改為驗證並消耗 EXP（移除金幣邏輯）：

```swift
func levelUp(player: PlayerStateModel) -> Result<Void, LevelUpError> {
    let nextLevel = player.heroLevel + 1
    guard nextLevel <= AppConstants.Game.heroMaxLevel else {
        return .failure(.maxLevelReached)
    }
    guard let required = AppConstants.ExpThreshold.required(toLevel: nextLevel) else {
        return .failure(.maxLevelReached)
    }
    guard player.heroExp >= required else {
        return .failure(.insufficientExp(required: required, have: player.heroExp))
    }

    player.heroExp             -= required
    player.heroLevel            = nextLevel
    player.availableStatPoints += AppConstants.Game.statPointsPerLevel
    save()
    return .success(())
}
```

---

## 修改八：CharacterView 升級區塊

**檔案：** `IdleBattleRPG/Views/CharacterView.swift`（`gearSegment` 升級 Section）

**改前：** 顯示「費用：X 金幣」、按鈕 disabled（金幣不足）

**改後：**

```swift
// 進度
if let required = AppConstants.ExpThreshold.required(toLevel: player.heroLevel + 1) {
    let progress = min(1.0, Double(player.heroExp) / Double(required))
    ProgressView(value: progress)
        .tint(.purple)
    Text("EXP \(player.heroExp) / \(required)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
}
// 升級按鈕（EXP 足夠才啟用）
Button("升級") { ... }
    .disabled(player.heroExp < (AppConstants.ExpThreshold.required(toLevel: player.heroLevel + 1) ?? Int.max))
```

結算 Sheet 獎勵行加入 EXP（`SettlementViewModel.makeRows()`）：

```swift
let totalExp = tasks.reduce(0) { $0 + $1.resultExp }
if totalExp > 0 { rows.append(.init(kind: .exp(totalExp))) }
```

`SettlementRow.RowKind` 加入 `.exp(Int)`，`SettlementSheet.rewardRowView` 渲染：

```swift
case .exp(let amt):
    HStack {
        Text("✨ EXP +\(amt)").font(.body)
        Spacer()
    }
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/PlayerStateModel.swift` | ✏️ 新增 `heroExp` |
| `Models/TaskModel.swift` | ✏️ 新增 `resultExp` |
| `Services/DungeonSettlementEngine.swift` | ✏️ `FloorDungeonResult` + EXP 計算 |
| `Services/SettlementService.swift` | ✏️ 寫入 `task.resultExp` |
| `Services/TaskClaimService.swift` | ✏️ `creditExp()` + 入帳邏輯 |
| `Services/CharacterProgressionService.swift` | ✏️ 升級改消耗 EXP |
| `AppConstants.swift` | ✏️ 移除 `UpgradeCost`，加入 `ExpThreshold` |
| `Views/CharacterView.swift` | ✏️ 升級 Section 改 EXP 進度條顯示 |
| `ViewModels/SettlementViewModel.swift` | ✏️ 加入 `.exp` row |
| `Views/SettlementSheet.swift` | ✏️ 渲染 `.exp` row |

---

## 驗收標準

- [ ] 出征一場 → 收下 → `heroExp` 正確增加（勝場 × expPerWin + 敗場 × 1）
- [ ] 結算 Sheet 顯示「✨ EXP +X」行
- [ ] CharacterView 升級區顯示 EXP 進度條與 `X / required`
- [ ] EXP 足夠時升級按鈕啟用，升級後 EXP 扣除
- [ ] 採集 / 鑄造任務不產生 EXP（`resultExp == 0`）
- [ ] Build 無錯誤
