# V8-2 Ticket 02：廚師 + 製藥師多產技能（ch_portion + ph_yield）

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

廚師與製藥師的「多產」技能目前未接入結算。在 `TaskClaimService.claimAllCompleted` 的 cuisine / alchemy 任務收下流程加入機率判定：

| 技能 | key | 效果 |
|------|-----|------|
| 豐盛料理 | `ch_portion` | 每點 10% 機率多產一份料理 |
| 加量製造 | `ph_yield` | 每點 10% 機率多產一瓶藥水 |

---

## 修改細節

### `Services/TaskClaimService.swift` — `claimAllCompleted`

#### Step 1：在迴圈外計算技能等級（重用已有的 `player`）

在 line 69（`let player = ...`）之後、`for task in completed` 之前，插入：

```swift
// 生產者多產技能（迴圈外計算一次，player 已在上方取得）
let chPortionLv   = player?.skillLevel(nodeKey: "ch_portion", actorKey: "chef")        ?? 0
let portionChance = Double(chPortionLv) * 0.10
let phYieldLv     = player?.skillLevel(nodeKey: "ph_yield",   actorKey: "pharmacist")  ?? 0
let yieldChance   = Double(phYieldLv) * 0.10
```

> `player` 在 `claimAllCompleted` line 69 已 fetch，無需新增 `fetchPlayer()` 方法。

#### Step 2：alchemy 段加入 ph_yield 判定

**現況：**
```swift
if task.kind == .alchemy,
   let def = PotionDef.find(task.definitionKey),
   let consumable = fetchConsumableInventory() {
    consumable.add(of: def.consumableType)
}
```

**修改後：**
```swift
if task.kind == .alchemy,
   let def = PotionDef.find(task.definitionKey),
   let consumable = fetchConsumableInventory() {
    consumable.add(of: def.consumableType)

    // ph_yield 多產判定（Lv0 完全不進此區塊，RNG 序列與舊版相同）
    if yieldChance > 0 {
        var rng = DeterministicRNG(task: task)
        if rng.nextDouble() < yieldChance {
            consumable.add(of: def.consumableType)
        }
    }
}
```

#### Step 3：cuisine 段加入 ch_portion 判定

**現況：**
```swift
if task.kind == .cuisine, !task.resultCuisineKey.isEmpty,
   let cuisine = CuisineDef.find(task.resultCuisineKey),
   let baseType = cuisine.consumableType,
   let consumable = fetchConsumableInventory() {
    var rng = DeterministicRNG(task: task)
    let isHighQuality = rng.nextDouble() < 0.25
    let finalType = isHighQuality ? (baseType.highQualityVariant ?? baseType) : baseType
    consumable.add(of: finalType)
}
```

**修改後（在 `consumable.add(of: finalType)` 後追加）：**
```swift
    // ch_portion 多產判定（Lv0 完全不進此區塊，繼續使用同一 rng 保持序列）
    if portionChance > 0, rng.nextDouble() < portionChance {
        let isHighQuality2 = rng.nextDouble() < 0.25
        let bonusType = isHighQuality2 ? (baseType.highQualityVariant ?? baseType) : baseType
        consumable.add(of: bonusType)
    }
```

---

## 設計決策記錄

| 議題 | 決策 | 理由 |
|------|------|------|
| player fetch 次數 | 重用 `claimAllCompleted` line 69 的既有 `player`，不新增 `fetchPlayer()` | 避免迴圈內 N 次重複 fetch，保持程式碼一致性 |
| 技能等級計算位置 | 迴圈外一次計算 | 技能等級在 claim 期間不會改變，無需每個 task 重算 |
| Lv0 的 RNG | alchemy: `if yieldChance > 0` 守門，Lv0 不建立 rng；cuisine: `if portionChance > 0, rng.nextDouble()` 短路，Lv0 不消耗額外亂數 | 與 T01 設計模式一致，舊存檔行為完全不變 |
| alchemy rng 建立時機 | 在 `if yieldChance > 0` 內部才建立 rng | Lv0 不浪費 DeterministicRNG 初始化 |
| cuisine rng | 沿用既有 `var rng`，多產繼續呼叫 `rng.nextDouble()` | 品質判定與多產判定共用同一序列，結果確定且符合原有設計 |

---

## 修改檔案

- `Services/TaskClaimService.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] ch_portion Lv0：廚師任務固定產 1 份料理（行為與現在完全相同）
- [ ] ch_portion Lv1：10% 機率多 1 份（期望值 1.10 份）
- [ ] ch_portion Lv2：20% 機率多 1 份（期望值 1.20 份）
- [ ] ph_yield Lv0：製藥師任務固定產 1 瓶（行為與現在完全相同）
- [ ] ph_yield Lv1：10% 機率多 1 瓶
- [ ] ph_yield Lv2：20% 機率多 1 瓶
- [ ] 多產品質獨立判定（與原份相同品質機率 25%）
- [ ] RNG 確定性：相同 task seed + 相同技能等級 → 永遠相同結果
- [ ] 迴圈內無額外 FetchDescriptor 呼叫（技能等級迴圈外計算）
