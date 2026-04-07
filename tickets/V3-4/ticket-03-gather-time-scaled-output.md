# V3-4 Ticket 03：採集產出依時長比例縮放

**狀態：** ✅ 完成

**依賴：** V3-4 Ticket 01（duration 保留正確）

---

## 問題

`SettlementService.fillGatherResults()` 目前的邏輯：

```swift
let amount = rng.nextInt(in: def.outputRange)  // 固定一個亂數，與時長無關
```

無論採集任務設 1 分鐘還是 2 小時，產出量完全相同（3–6 木材）。
導致：
- 長時間採集毫無意義（2 小時 ≠ 1 分鐘的任何優勢）
- Dev 快速完成時，即使「度過了 2 小時」，產出仍只有 3–6

---

## 修改

### 邏輯說明

採集以「最短時長為一個循環」計算回合數，每回合獨立 RNG：

```
cycles = floor(actualDuration / def.shortestDuration)
       = max(1, floor((endsAt - startedAt) / shortestDuration))
每回合：rng.nextInt(in: def.outputRange)
總產出 = 各回合加總
```

範例（森林，最短 60 秒，outputRange 3...6）：
| 時長 | 回合數 | 總產出 |
|---|---|---|
| 1 分鐘 | 1 | 3–6 |
| 5 分鐘 | 5 | 15–30 |
| 2 小時 | 120 | 360–720 |

### 修改檔案

**`IdleBattleRPG/Services/SettlementService.swift`**

```swift
// 改前
private func fillGatherResults(_ task: TaskModel) {
    guard let def = GatherLocationDef.find(key: task.definitionKey) else { return }
    var rng    = DeterministicRNG(task: task)
    let amount = rng.nextInt(in: def.outputRange)
    ...
}

// 改後
private func fillGatherResults(_ task: TaskModel) {
    guard let def = GatherLocationDef.find(key: task.definitionKey) else { return }

    let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
    let cycles = max(1, Int(actualDuration) / def.shortestDuration)

    var rng    = DeterministicRNG(task: task)
    var amount = 0
    for _ in 0..<cycles {
        amount += rng.nextInt(in: def.outputRange)
    }

    switch def.outputMaterial {
    case .wood:            task.resultWood = amount
    case .ore:             task.resultOre  = amount
    // ... 其餘 case 不變
    }
}
```

### 靜態資料不需調整

`outputRange` 本來就是「每回合」的基準量（1 分鐘 → 3–6）。
長時間採集自然倍增，與直覺一致。

> ⚠️ 如果未來覺得 2 小時 360–720 木材太多，調整 `outputRange` 即可，
> 結算機制本身不需再改。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Services/SettlementService.swift` | ✏️ 修改（fillGatherResults 加回合計算） |

---

## 驗收標準

- [ ] 1 分鐘採集 → 產出 3–6（1 回合）
- [ ] 5 分鐘採集 → 產出約 15–30（5 回合）
- [ ] 2 小時採集 → 產出約 360–720（120 回合）
- [ ] Dev 快速完成 2 小時採集任務 → 產出量與手動等 2 小時結果一致（確定性 RNG 相同）
- [ ] 鑄造任務不受影響（fillGatherResults 只處理 .gather）
- [ ] Build 無錯誤
