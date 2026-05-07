# V8-2 Ticket 01：農夫技能效果實作（fa_yield + fa_quality）

**狀態：** 🔲 待實作

**依賴：** 無（農夫技能 UI 已在 V8 完成）

---

## 目標

1. **修正現有 bug**：`fillFarmResults` 迴圈寫死 `baseYield = 4`，不管種幾輪都只產 4 份。  
   正確行為是每輪一份，應從任務時長推算輪數。
2. **接入 fa_yield（豐收之手）**：每點 30% 機率多產一份農作物（每輪獨立判定）。
3. **接入 fa_quality（精心栽培）**：每點提升 10% 品質機率門檻。

---

## 現有 Bug 說明

```swift
// 現況（SettlementService.swift line 126–154）
let baseYield = 4          // ← 寫死，不管種 2 輪還是 10 輪都只產 4 份

for _ in 0..<baseYield {  // ← 應改為 0..<rounds
    ...
}
```

正確輪數計算：
```swift
let rounds = max(1, Int(task.endsAt.timeIntervalSince(task.startedAt)) / 300)
```

---

## 修改細節

### `Services/SettlementService.swift` — `fillFarmResults` 完整替換

```swift
private func fillFarmResults(_ task: TaskModel) {
    guard let seedType = MaterialType(rawValue: task.definitionKey) else {
        assertionFailure("[SettlementService] 無法識別種子類型: \(task.definitionKey)")
        return
    }

    // 一次 fetch，同時取 tier 與技能等級
    let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
    assert(player != nil, "[SettlementService] fillFarmResults: player not found")

    let tier = min(player?.gatherer5Tier ?? 0, 3)

    // fa_quality：每點 +10% 品質門檻
    let qualityLv    = player?.skillLevel(nodeKey: "fa_quality", actorKey: "farmer") ?? 0
    let qualityBonus = Double(qualityLv) * 0.10

    // 品質門檻（topThreshold 保證 < highThreshold - 0.05，維持三段分布意義）
    let baseTop:  [Double] = [0.02, 0.06, 0.12, 0.18]
    let baseHigh: [Double] = [0.20, 0.30, 0.40, 0.50]
    let highThreshold = min(baseHigh[tier] + qualityBonus, 0.90)
    let topThreshold  = min(baseTop[tier]  + qualityBonus, highThreshold - 0.05)

    // fa_yield：每點 +30% 多產機率（每輪獨立判定）
    let yieldLv     = player?.skillLevel(nodeKey: "fa_yield", actorKey: "farmer") ?? 0
    let extraChance = Double(yieldLv) * 0.30

    // 從任務時長推算輪數（修正 baseYield = 4 的 bug）
    let rounds = max(1, Int(task.endsAt.timeIntervalSince(task.startedAt)) / 300)

    var rng = DeterministicRNG(task: task)

    for _ in 0..<rounds {
        // 基礎產出（每輪一份）
        let roll = rng.nextDouble()
        addCrop(seedType: seedType, roll: roll,
                topThreshold: topThreshold, highThreshold: highThreshold, to: task)

        // fa_yield 多產判定（有技能才消耗額外亂數，Lv0 時序列與舊版完全相同）
        guard extraChance > 0 else { continue }
        if rng.nextDouble() < extraChance {
            let roll2 = rng.nextDouble()
            addCrop(seedType: seedType, roll: roll2,
                    topThreshold: topThreshold, highThreshold: highThreshold, to: task)
        }
    }
}

private func addCrop(
    seedType: MaterialType,
    roll: Double,
    topThreshold: Double,
    highThreshold: Double,
    to task: TaskModel
) {
    let isTop  = roll < topThreshold
    let isHigh = !isTop && roll < highThreshold

    switch seedType {
    case .wheatSeed:
        if isTop        { task.resultWheatTop  += 1 }
        else if isHigh  { task.resultWheatHigh += 1 }
        else            { task.resultWheat     += 1 }
    case .vegetableSeed:
        if isTop        { task.resultVegetableTop  += 1 }
        else if isHigh  { task.resultVegetableHigh += 1 }
        else            { task.resultVegetable     += 1 }
    case .fruitSeed:
        if isTop        { task.resultFruitTop  += 1 }
        else if isHigh  { task.resultFruitHigh += 1 }
        else            { task.resultFruit     += 1 }
    case .spiritGrainSeed:
        if isTop        { task.resultSpiritGrainTop  += 1 }
        else if isHigh  { task.resultSpiritGrainHigh += 1 }
        else            { task.resultSpiritGrain     += 1 }
    default:
        break
    }
}
```

---

## 設計決策記錄

| 議題 | 決策 | 理由 |
|------|------|------|
| fa_yield Lv0 的 RNG 序列 | 完全不進 extraChance 區塊（`guard extraChance > 0`），確保 Lv0 行為與原版一致 | 舊存檔升版後 in-flight 任務結算結果不變 |
| fa_yield 的額外亂數消耗 | 觸發判定（`rng.nextDouble() < extraChance`）**固定消耗**一個亂數，不管有沒有真的多產 | 確保有技能 vs 無技能的 RNG 序列設計一致、可預期 |
| topThreshold 上限 | `min(baseTop + bonus, highThreshold - 0.05)` | 確保頂級 / 高級 / 普通三段機率皆有意義，不會出現頂級 ≥ 高級門檻的邏輯錯誤 |
| FetchDescriptor 次數 | 合併為一次 | 原版已有一次 fetch，加技能後本可多一次，合併更乾淨 |
| rounds 計算 | `Int(task.endsAt.timeIntervalSince(task.startedAt)) / 300` | TaskModel 沒有 durationSeconds 欄位，從已有的 startedAt / endsAt 推算 |

---

## 修改檔案

- `Services/SettlementService.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] **Bug 修正**：種植 2 輪 → 收 2 份；種植 10 輪 → 收 10 份（含多產機率）
- [ ] fa_yield Lv0：每輪固定 1 份，RNG 序列與原版完全相同
- [ ] fa_yield Lv1：每輪 30% 機率多 1 份（期望 1.30 份 / 輪）
- [ ] fa_yield Lv2：每輪 60% 機率多 1 份（期望 1.60 份 / 輪）
- [ ] fa_quality Lv0：品質分布與原版完全相同
- [ ] fa_quality Lv1：高品質門檻各 +10%（T1: highThreshold 0.30 → 0.40）
- [ ] fa_quality Lv2：各 +20%
- [ ] topThreshold 永遠 < highThreshold（不會出現邏輯矛盾）
- [ ] RNG 確定性：相同 task seed 下，同樣技能等級永遠產出相同結果
