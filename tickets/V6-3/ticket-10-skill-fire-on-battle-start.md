# V6-3 Ticket 10：修正技能永不觸發（skillNextFireTime 初始值錯誤）

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T06（技能快照已正確填入）、T07（skillKey 已可追蹤）、T08（CD 追蹤邏輯正確）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogGenerator.swift`

---

## 症狀

- 戰鬥記錄只顯示「發動斬擊」基本攻擊，完全沒有技能事件
- 技能 CD 條（如火球術）顯示「就緒」但從不倒數

---

## 根本原因

`runCombatCore` 中，技能的首次觸發時間初始化為 `cooldownSeconds`：

```swift
// 現有（錯誤）
var skillNextFireTime: [String: Double] = Dictionary(
    uniqueKeysWithValues: activeSkills.map { ($0.key, Double($0.cooldownSeconds)) }
)
```

以法師火球術（`cooldownSeconds = 18`）為例：
- `elapsedCombatTime` 每回合只增加 `heroChargeTime`（≈1.5s）
- 技能需等 12 回合（18 ÷ 1.5）才觸發
- 一場普通戰鬥只有 5–8 回合 → 技能**永遠不觸發**

---

## 修改方案

**單行修改**，將初始值從 `cooldownSeconds` 改為 `0.0`：

```swift
// 修改後（正確）
var skillNextFireTime: [String: Double] = Dictionary(
    uniqueKeysWithValues: activeSkills.map { ($0.key, 0.0) }
)
```

### 修改後行為

| 時間點 | 現有（錯誤）| 修改後（正確）|
|---|---|---|
| 第 1 回合（elapsedCombatTime ≈ 1.5s）| 未到 18s，不觸發 | 1.5 ≥ 0.0，**立即觸發** |
| 觸發後 nextFire 更新為 | 18 + 18 = 36s（無法再到）| 0 + 18 = 18s（第 12 回合可二次觸發）|
| 短戰鬥（5–8 回合）| 技能從不出現 | 第 1 回合觸發一次 |

### CD 條的連動（T08 已正確，無需改動）

1. `.encounter` → fraction 重置為 1.0（就緒）
2. 第 1 回合 `.skill` 事件 → `skillLastFireGameTime[key] = 0`，fraction 降至 0
3. 後續每個 `.attack` 事件 → `accumulatedCombatTime += heroTime`，fraction 逐步回升
4. fraction 回升到 1.0 後再次顯示「就緒」

### 不影響範圍

- `DungeonSettlementEngine` 使用相同的 `runCombatCore`（透過 `runCombat()`），deterministic 結果不變
- T05 狀態效果（燃燒 / 中毒 / 暈眩 / 弱化）完全不受影響
- `EliteBattleSheet` 不傳 `activeSkills`，不顯示 CD 條，不受影響

---

## 驗收標準

- [x] 法師火球術在每場戰鬥第 1 回合觸發，log 出現「【火球術】對 XXX 造成 N 傷害」
- [x] 劍士烈火斬在第 1 回合觸發，後續出現 `statusApplied` 燃燒事件
- [x] 技能觸發後 CD 條降至接近 0，隨後隨攻擊逐步回升
- [x] 同一場較長的戰鬥中，技能可在 `cooldownSeconds` 後二次觸發
- [x] `EliteBattleSheet` 戰鬥行為不受影響
- [x] `xcodebuild` 通過，無新警告
