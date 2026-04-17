# V6-2 Ticket 09：技能點系統 + 主動技能升階

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T05
**修改檔案：**
- `IdleBattleRPG/Models/PlayerStateModel.swift`
- `IdleBattleRPG/StaticData/SkillDef.swift`
- `IdleBattleRPG/Models/TaskModel.swift`
- `IdleBattleRPG/Services/CharacterProgressionService.swift`
- `IdleBattleRPG/Models/DatabaseSeeder.swift`
- `IdleBattleRPG/Services/TaskCreationService.swift`
- `IdleBattleRPG/Services/BattleLogGenerator.swift`
- `IdleBattleRPG/AppState.swift`
- 新建：`IdleBattleRPG/Services/SkillUpgradeService.swift`

---

## 說明

新增獨立的技能點池（`availableSkillPoints`），升等時同步獲得 +1 技能點。
玩家可將技能點投入已解鎖的主動技能，使技能升階（最多 Lv.3），提升戰鬥效果。
出征時快照技能等級，確保進行中任務不受後續升階影響。

---

## PlayerStateModel 新增欄位

```swift
// 技能點（V6-2 T09），SwiftData 輕量遷移，有預設值
var availableSkillPoints: Int = 0
var skillLevelsRaw: String = ""   // e.g. "sw_heavy_slash:2,sw_iron_will:1"
```

### 便利存取

```swift
extension PlayerStateModel {

    /// 技能等級字典（key: skillKey, value: 已升階次數）
    var skillLevels: [String: Int] {
        Dictionary(uniqueKeysWithValues:
            skillLevelsRaw
                .split(separator: ",")
                .compactMap { pair -> (String, Int)? in
                    let parts = pair.split(separator: ":")
                    guard parts.count == 2, let lv = Int(parts[1]) else { return nil }
                    return (String(parts[0]), lv)
                }
        )
    }

    /// 取得指定技能的升階次數（未升階回傳 0）
    func level(of skillKey: String) -> Int {
        skillLevels[skillKey] ?? 0
    }

    /// 更新指定技能的升階次數（寫回 skillLevelsRaw）
    func setLevel(_ level: Int, of skillKey: String) {
        var levels = skillLevels
        if level <= 0 {
            levels.removeValue(forKey: skillKey)
        } else {
            levels[skillKey] = level
        }
        skillLevelsRaw = levels.map { "\($0.key):\($0.value)" }.joined(separator: ",")
    }
}
```

---

## SkillDef.swift 修改

### 新增 maxLevel 欄位

```swift
struct SkillDef {
    // ... 現有欄位（key, name, classKey, requiredLevel, cooldownSeconds, effect, iconName）...
    let maxLevel: Int   // 全部技能預設 3
}
```

所有現有 20 個技能在靜態資料中補上 `maxLevel: 3`。

### 新增效果計算 extension

```swift
extension SkillDef {

    /// 升階乘數：Lv.N（N 次升階後）= 1.0 + 0.25 × N
    /// Lv.0（未升階）= 1.0，Lv.1 = 1.25，Lv.2 = 1.5，Lv.3 = 1.75
    func effectMultiplier(at level: Int) -> Double {
        1.0 + 0.25 * Double(level)
    }

    /// 指定升階次數下的效果描述文字（供 T07 UI 使用）
    func effectDescription(at level: Int) -> String {
        let m = effectMultiplier(at: level)
        switch effect {
        case .damage(let base):
            return String(format: "傷害 × %.2f", base * m)
        case .heal(let base):
            return String(format: "治癒 %.0f%%", base * m * 100)
        case .damageAndHeal(let dmg, let heal):
            return String(format: "傷害 × %.2f · 治癒 %.0f%%", dmg * m, heal * m * 100)
        case .heroAtkUp(let bonus):
            let scaled = min(0.99, bonus * m)
            return String(format: "攻擊提升 +%.0f%%", scaled * 100)
        case .enemyAtkDown(let r):
            let scaled = min(0.99, r * m)
            return String(format: "敵方攻擊 -%.0f%%", scaled * 100)
        case .damageAndEnemyAtkDown(let dmg, let r):
            let scaledR = min(0.99, r * m)
            return String(format: "傷害 × %.2f · 敵攻 -%.0f%%", dmg * m, scaledR * 100)
        }
    }
}
```

---

## TaskModel 新增欄位

```swift
// 出征時的技能等級快照（V6-2 T09）
var snapshotSkillLevelsRaw: String = ""   // e.g. "sw_heavy_slash:2"
```

### 便利存取

```swift
extension TaskModel {
    var snapshotSkillLevels: [String: Int] {
        Dictionary(uniqueKeysWithValues:
            snapshotSkillLevelsRaw
                .split(separator: ",")
                .compactMap { pair -> (String, Int)? in
                    let parts = pair.split(separator: ":")
                    guard parts.count == 2, let lv = Int(parts[1]) else { return nil }
                    return (String(parts[0]), lv)
                }
        )
    }
}
```

---

## SkillUpgradeService（新建）

```swift
// IdleBattleRPG/Services/SkillUpgradeService.swift

import Foundation
import SwiftData

struct SkillUpgradeService {
    let context: ModelContext

    // MARK: - 查詢

    func canUpgrade(skillKey: String, for player: PlayerStateModel) -> Bool {
        guard player.availableSkillPoints > 0 else { return false }
        guard let skill = SkillDef.find(key: skillKey) else { return false }
        return player.level(of: skillKey) < skill.maxLevel
    }

    // MARK: - 寫入

    func upgradeSkill(skillKey: String, for player: PlayerStateModel) throws {
        guard player.availableSkillPoints > 0 else {
            throw SkillUpgradeError.noPointsAvailable
        }
        guard let skill = SkillDef.find(key: skillKey) else {
            throw SkillUpgradeError.skillNotFound
        }
        let current = player.level(of: skillKey)
        guard current < skill.maxLevel else {
            throw SkillUpgradeError.maxLevelReached
        }

        player.availableSkillPoints -= 1
        player.setLevel(current + 1, of: skillKey)

        try context.save()
    }
}

// MARK: - 錯誤型別

enum SkillUpgradeError: LocalizedError {
    case noPointsAvailable
    case skillNotFound
    case maxLevelReached

    var errorDescription: String? {
        switch self {
        case .noPointsAvailable: return "沒有可用的技能點"
        case .skillNotFound:     return "找不到技能"
        case .maxLevelReached:   return "此技能已達最高等級"
        }
    }
}
```

---

## CharacterProgressionService 修改

```swift
// levelUp(player:) 方法，在現有的 +availableStatPoints 和 +availableTalentPoints 後加入：
player.availableSkillPoints += 1
```

---

## DatabaseSeeder 修改

在 `backfillTalentPoints` 後新增 `backfillSkillPoints`：

```swift
@MainActor
private static func backfillSkillPoints(context: ModelContext) {
    let descriptor = FetchDescriptor<PlayerStateModel>()
    guard let player = (try? context.fetch(descriptor))?.first else { return }
    guard player.skillLevelsRaw.isEmpty,
          player.availableSkillPoints == 0,
          player.heroLevel > 1 else { return }
    player.availableSkillPoints = player.heroLevel - 1
}
```

並在 `seedIfNeeded` 中呼叫（在 `backfillTalentPoints` 之後）：

```swift
backfillSkillPoints(context: context)
```

---

## TaskCreationService 修改

出征任務建立時，快照技能等級：

```swift
// createDungeonFloorTask / createDungeonTask 內，snapshotSkillKeysRaw 設定之後
task.snapshotSkillLevelsRaw = player.skillLevelsRaw
```

---

## BattleLogGenerator 修改

技能觸發時，從 `task.snapshotSkillLevels` 讀取等級，套用升階乘數：

```swift
// runCombatCore 或對應技能計算段
let snapshotLevels = task.snapshotSkillLevels
let skillLevel = snapshotLevels[skill.key] ?? 0
let upgradeMultiplier = skill.effectMultiplier(at: skillLevel)

// 傷害型技能（以 .damage 為例）
case .damage(let base):
    let dmg = max(1, Int(Double(heroAtk) * base * upgradeMultiplier))
    enemyHp = max(0, enemyHp - dmg)

// 治癒型技能
case .heal(let base):
    let restored = max(1, Int(Double(heroMaxHp) * base * upgradeMultiplier))
    heroHp = min(heroMaxHp, heroHp + restored)

// 其餘複合型技能同理，對 dmg/heal/bonus/reduction 乘上 upgradeMultiplier
```

---

## AppState 修改

```swift
// Services 區塊新增
let skillUpgradeService: SkillUpgradeService

// init(context:) 新增
self.skillUpgradeService = SkillUpgradeService(context: context)
```

---

## 驗收標準

- [ ] 升等時同步 `availableSkillPoints += 1`
- [ ] 舊存檔（heroLevel > 1）補發技能點（幂等）
- [ ] 技能可升階至 maxLevel（3），超過後 `canUpgrade` 回傳 false
- [ ] 升階消耗 1 技能點，`skillLevelsRaw` 正確更新
- [ ] 出征快照 `snapshotSkillLevelsRaw` 正確記錄出發時的技能等級
- [ ] 出征後再升技能，不影響進行中任務的快照
- [ ] 戰鬥傷害 / 治癒量隨技能等級提升（Lv.0→1→2→3 乘數 1.0→1.25→1.5→1.75）
- [ ] `xcodebuild` 通過，無新警告
