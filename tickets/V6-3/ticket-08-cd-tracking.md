# V6-3 Ticket 08：BattleLogPlaybackModel 技能 CD 追蹤

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T07（需要 `BattleEvent.skillKey`）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogPlaybackModel.swift`

---

## 目的

在播放期間追蹤每個技能的冷卻進度（以遊戲內時間計算），
供 T09 的 UI 面板即時綁定，讓玩家清楚看到技能何時就緒。

---

## CD 時間邏輯

「遊戲時間」以英雄每次出手的 `chargeTime` 為單位累加：
- `.attack` 事件 → `accumulatedCombatTime += event.chargeTime`
- 技能 CD 進度 = `(accumulatedCombatTime - lastFireTime) / skill.cooldownSeconds`
- 未使用過的技能 fraction = 1.0（視為就緒，出征初始即可施放）

每場戰鬥（`.encounter` 事件）重置計時，因為技能 CD 是場內概念。

---

## 實作

### 新增 public 屬性（UI 綁定）

```swift
/// T08：技能 CD 進度，供 BattleLogSheet CD 面板綁定
/// fraction：0.0 = 冷卻中，1.0 = 就緒
var skillCooldownFractions: [(key: String, name: String, fraction: Double)] = []
```

### 新增 private 追蹤屬性

```swift
private var equippedSkillDefs:     [SkillDef] = []
private var skillLastFireGameTime: [String: Double] = [:]
private var accumulatedCombatTime: Double = 0
```

### start() 新增參數

```swift
func start(
    events:            [BattleEvent],
    fromBattleIndex:   Int,
    taskTotalBattles:  Int,
    taskId:            UUID,
    activeSkills:      [SkillDef] = [],        // ← 新增（預設 []，舊 caller 不需修改）
    nextBatchProvider: ...,
    onBattleEnded:     ...
)
```

`start()` 內初始化：
```swift
self.equippedSkillDefs      = activeSkills
self.skillLastFireGameTime  = [:]
self.accumulatedCombatTime  = 0
self.skillCooldownFractions = activeSkills.map { (key: $0.key, name: $0.name, fraction: 1.0) }
```

### stop() 清除 CD 狀態

```swift
skillCooldownFractions = []
equippedSkillDefs      = []
skillLastFireGameTime  = [:]
accumulatedCombatTime  = 0
```

### runPlayback 事件鉤子

| 事件 | 動作 |
|---|---|
| `.encounter` | `accumulatedCombatTime = 0` + `skillLastFireGameTime = [:]` + `updateSkillCooldowns()` |
| `.attack`（兩個路徑結束後）| `accumulatedCombatTime += heroTime` + `updateSkillCooldowns()` |
| `.skill`（`skillKey != nil`）| `skillLastFireGameTime[key] = accumulatedCombatTime` + `updateSkillCooldowns()` |

### updateSkillCooldowns() helper

```swift
@MainActor
private func updateSkillCooldowns() {
    guard !equippedSkillDefs.isEmpty else { return }
    skillCooldownFractions = equippedSkillDefs.map { skill in
        let fraction: Double
        if let lastFire = skillLastFireGameTime[skill.key] {
            fraction = min(1.0, (accumulatedCombatTime - lastFire) / Double(skill.cooldownSeconds))
        } else {
            fraction = 1.0   // 尚未使用 → 視為就緒
        }
        return (key: skill.key, name: skill.name, fraction: fraction)
    }
}
```

---

## 驗收標準

- [x] `activeSkills` 空時 `skillCooldownFractions` 恆為空，不影響現有 AFK / Elite 路徑
- [x] `.encounter` 時所有技能 fraction 重置為 1.0
- [x] 技能觸發後（`.skill` + `skillKey != nil`）fraction 降至接近 0，隨後續 `.attack` 事件回升
- [x] `stop()` 後所有 CD 屬性歸零清空
- [x] `xcodebuild` 通過，無新警告
