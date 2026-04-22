# V7-1 Ticket 03：正面隨機採集事件

**狀態：** ✅ 已完成

**依賴：** T01（新素材類型）、T02（rareChance 節點整合）

---

## 目標

每次採集任務有機率觸發正面事件，增加驚喜感。事件使用 deterministic RNG（相同任務永遠同結果），只在結算時計算，不預存結果內容。

---

## 事件機率

| 事件 key | 名稱 | 基礎機率 | 效果 |
|---|---|---|---|
| `none` | （無事件）| **90%** | 一般結算 |
| `bumper_harvest` | 豐收 | 6% | 當次任務全部 cycle 產出 ×2 |
| `rare_find` | 稀有發現 | 3% | 額外獲得 1 個進階素材 |
| `gold_vein` | 金脈 / 珍貴發現 | 1% | 額外獲得 30～100 金幣 |

### T02 rareChance 節點整合

`rare_find` + `gold_vein` 的閾值可被採集者技能節點調整：

```swift
let baseRareThreshold = 90  // 90% 以上才觸發稀有系
let rareBonus = gathererSkillService.rareChanceBonus(actorKey: task.actorKey, player: player)
// rareBonus = level * 5（每點 +5%，最多 15%）
let adjustedThreshold = max(75, baseRareThreshold - rareBonus)
// 最多降至 75%（rare 系機率最高 25%）
```

事件 roll 規則（0...99）：

```
0 ..< adjustedThreshold              → none
adjustedThreshold ..< (adjustedThreshold + 6) → bumper_harvest
adjustedThreshold + 6 ..< (adjustedThreshold + 9) → rare_find
adjustedThreshold + 9 ..< 100        → gold_vein
```

---

## 稀有發現素材對應

| 採集者 | 稀有發現素材 |
|---|---|
| 伐木工（gatherer_1）| 古木材 |
| 採礦工（gatherer_2）| 精煉礦石 |
| 採藥師（gatherer_3）| 靈草 |
| 漁夫（gatherer_4）| 深淵魚 |

---

## 資料模型

### TaskModel（SwiftData，輕量遷移）

```swift
var gatherEventKey: String? = nil   // nil / "bumper_harvest" / "rare_find" / "gold_vein"
```

---

## SettlementService 計算邏輯

```swift
private func fillGatherResults(_ task: TaskModel, player: PlayerStateModel?) {
    // 1. 基礎計算（現有邏輯）
    var rng = DeterministicRNG(task: task)
    let cycles = max(1, Int(actualDuration) / def.shortestDuration)
    var amount = 0
    for _ in 0..<cycles { amount += rng.nextInt(in: def.outputRange) }

    // 2. 事件判斷（同一個 rng 繼續 roll，保持確定性）
    let rareBonus = gathererSkillService?.rareChanceBonus(actorKey: task.actorKey, player: player) ?? 0
    let threshold = max(75, 90 - rareBonus)
    let roll = rng.nextInt(in: 0...99)

    let eventKey: String?
    switch roll {
    case 0 ..< threshold:
        eventKey = nil
    case threshold ..< (threshold + 6):
        eventKey = "bumper_harvest"
        amount *= 2
    case (threshold + 6) ..< (threshold + 9):
        eventKey = "rare_find"
    default:
        eventKey = "gold_vein"
        task.resultGold += rng.nextInt(in: 30...100)
    }
    task.gatherEventKey = eventKey

    // 3. 寫入素材（現有邏輯）
    ...
}
```

---

## TaskClaimService

`rare_find` 的額外素材在 `commitClaim` 時入庫：

```swift
if task.gatherEventKey == "rare_find" {
    let rareMat: MaterialType = {
        switch task.actorKey {
        case "gatherer_1": return .ancientWood
        case "gatherer_2": return .refinedOre
        case "gatherer_3": return .spiritHerb
        case "gatherer_4": return .abyssFish
        default:           return .wood
        }
    }()
    materials[rareMat, default: 0] += 1
}
```

---

## UI：SettlementSheet 事件 badge

採集任務結算列有事件時，在素材數量下方顯示一行 capsule badge：

| 事件 | Badge 文字 | 顏色 |
|---|---|---|
| `bumper_harvest` | ✨ 豐收！產出 ×2 | `.orange` |
| `rare_find` | 🔍 稀有發現 +1 [素材名] | `.yellow` |
| `gold_vein` | 💰 珍貴發現 +[N] 金幣 | `.yellow` |
| `none` | （不顯示）| — |

---

## 修改檔案

| 檔案 | 改動 |
|---|---|
| `Models/TaskModel.swift` | 新增 `gatherEventKey: String?` |
| `Services/SettlementService.swift` | `fillGatherResults` 加入事件 RNG 邏輯 |
| `Services/TaskClaimService.swift` | `commitClaim` 處理 `rare_find` 入庫 |
| `Views/SettlementSheet.swift` | 採集任務 row 顯示事件 badge |

---

## 驗收標準

- [ ] 大量測試任務中，約 90% 無事件（可用不同 seed 的任務驗證分布）
- [ ] 豐收：素材數量翻倍，且為 deterministic（同任務重算相同結果）
- [ ] 稀有發現：對應進階素材 +1 入庫
- [ ] 金脈：結算後金幣增加 30～100
- [ ] T02 rareChance 節點 Lv.3 時，稀有系事件機率升至 ~25%
- [ ] SettlementSheet 有事件時顯示 badge，無事件時無多餘 UI
