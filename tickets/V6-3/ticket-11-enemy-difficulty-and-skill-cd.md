# V6-3 Ticket 11：怪物難度調整 + 技能從冷卻開始

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T10（skillNextFireTime = 0.0 是本 ticket 要反轉的行為）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogGenerator.swift`
- `IdleBattleRPG/Services/DungeonSettlementEngine.swift`

---

## 問題

1. **怪物太脆**：敵方 HP = `recommendedPower * 2`，對 power 79 玩家面對推薦 40 的樓層只有 80 HP，5 回合即死。技能幾乎無法在戰鬥中體現。

2. **技能立即就緒**（T10 遺留）：`skillNextFireTime = 0.0` 讓技能在第 1 回合就觸發，不符合「戰鬥開始時技能才開始冷卻」的設計意圖。

---

## 修改方案

### 一、增加敵方 HP 與 ATK

```swift
// BattleLogGenerator.generate()

// 修改前
let enemyMaxHp = max(30, floor.recommendedPower * 2)
let enemyAtk   = max(8,  floor.recommendedPower / 4)

// 修改後
let enemyMaxHp = max(80, floor.recommendedPower * 6)   // 血量 3× 提升
let enemyAtk   = max(10, floor.recommendedPower / 3)   // 攻擊略微提升
```

**DungeonSettlementEngine.swift 需同步更新**（兩個 `settle()` 方法中各有一份相同計算）：
- `settle(task:area:)` 的 enemy 計算（約第 65–76 行）
- `settle(task:floor:)` 的 enemy 計算（約第 165–176 行）

### 二、技能從冷卻開始（反轉 T10）

```swift
// BattleLogGenerator.runCombatCore()

// 修改前（T10）
var skillNextFireTime: [String: Double] = Dictionary(
    uniqueKeysWithValues: activeSkills.map { ($0.key, 0.0) }
)

// 修改後
var skillNextFireTime: [String: Double] = Dictionary(
    uniqueKeysWithValues: activeSkills.map { ($0.key, Double($0.cooldownSeconds)) }
)
```

---

## 效果驗算

**場景：power 79 英雄 vs 殘木前哨（recommendedPower ≈ 40）**

| 數值 | 修改前 | 修改後 |
|---|---|---|
| 敵方 HP | 80 | 240 |
| 敵方 ATK | 10 | 13 |
| 英雄攻擊傷害（含防禦）| 15/回合 | 15/回合（不變）|
| 擊殺回合數 | ≈ 5 | ≈ 16 |
| 火球術（18s CD）觸發回合 | 第 1 回合（T10 bug）| 第 12 回合 ✓ |
| 英雄被擊傷害 | 3/回合 | 6/回合 |
| 英雄在戰鬥中受到總傷害 | ≈ 12（無威脅）| ≈ 72（有緊張感）|
| 英雄存活 | ✅ 158/158 | ✅ 86/158 |

**場景：power 40 英雄 vs 殘木前哨（1:1 parity）**

- 英雄 HP 80，敵方 HP 240
- 英雄攻擊 = 6/回合，需 40 回合殺敵
- 敵方攻擊 9/回合，40 回合造成 ~225 傷害 > 80 → 英雄落敗
- **符合設計**：玩家應超過推薦戰力才去該樓層

---

## 驗收標準

- [x] 敵方 HP 約為修改前的 3×（目視戰鬥更長）
- [x] 技能在戰鬥第 12 回合前不觸發（熱身後才施放）
- [x] 火球術觸發後 CD 條降至 0，逐漸回升
- [x] 技能觸發事件和燃燒 / 中毒等狀態效果正常出現在 log
- [x] DungeonSettlementEngine 的 enemy 公式同步更新
- [x] `xcodebuild` 通過，無新警告
