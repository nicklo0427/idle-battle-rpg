# V6-1 Ticket 03：HeroStats 計算整合職業與技能加成

**狀態：** 🔲 待實作
**版本：** V6-1 Phase 1
**依賴：** T01, T02

---

## 目標

將職業基礎加成整合進 `HeroStats` 永久計算，並讓出征任務在建立時將技能加成套用至 `snapshotStats`。

---

## 修改檔案

### `Models/HeroStats.swift`

新增 extension，提供套用職業與技能加成的 pure function：

```swift
// MARK: - V6-1 職業 & 技能加成

extension HeroStats {
    /// 套用職業基礎加成（永久，影響所有 HeroStats 計算）
    func applying(classDef: ClassDef) -> HeroStats {
        HeroStats(
            totalATK: totalATK + classDef.baseATKBonus,
            totalDEF: totalDEF + classDef.baseDEFBonus,
            totalHP:  totalHP  + classDef.baseHPBonus,
            totalAGI: totalAGI + classDef.baseAGIBonus,
            totalDEX: totalDEX + classDef.baseDEXBonus
        )
    }

    /// 套用技能加成（僅出征時使用，加在 snapshotStats 上）
    func applying(skills: [SkillDef]) -> HeroStats {
        var atk = totalATK, def = totalDEF, hp = totalHP
        var agi = totalAGI, dex = totalDEX
        for skill in skills {
            for effect in skill.effects {
                switch effect {
                case .atkBonus(let v): atk += v
                case .defBonus(let v): def += v
                case .hpBonus(let v):  hp  += v
                case .agiBonus(let v): agi += v
                case .dexBonus(let v): dex += v
                }
            }
        }
        return HeroStats(
            totalATK: atk, totalDEF: def, totalHP: hp,
            totalAGI: agi, totalDEX: dex
        )
    }
}
```

---

### `Services/HeroStatsService.swift`

修改 `compute(player:equipped:)`，在現有計算結果後套用職業基礎加成：

```swift
static func compute(player: PlayerStateModel, equipped: [EquipmentModel]) -> HeroStats {
    // ... 現有計算邏輯不變（基礎點數 + 裝備加成）...
    let base = /* 現有結果 */

    // V6-1 新增：套用職業基礎加成
    guard let classDef = ClassDef.find(key: player.classKey) else { return base }
    return base.applying(classDef: classDef)
}
```

注意：`classKey` 為空字串時（未選職業）`find` 回傳 `nil`，直接回傳 `base` 不 crash。

---

### `Services/TaskCreationService.swift`

`createDungeonFloorTask()` 與 `createDungeonTask()` 函式簽名新增 `equippedSkillKeys` 參數：

```swift
func createDungeonFloorTask(
    floorKey: String,
    durationSeconds: Int,
    heroStats: HeroStats,
    equippedSkillKeys: [String]   // V6-1 新增
) throws {
    // 套用技能加成到 snapshot
    let equippedSkills = equippedSkillKeys.compactMap { SkillDef.find(key: $0) }
    let effectiveStats = heroStats.applying(skills: equippedSkills)

    // snapshotPower / snapshotAgi / snapshotDex 改用 effectiveStats
    task.snapshotPower        = effectiveStats.power
    task.snapshotAgi          = effectiveStats.totalAGI
    task.snapshotDex          = effectiveStats.totalDEX
    task.snapshotSkillKeysRaw = equippedSkillKeys.joined(separator: ",")
    // ... 其餘不變 ...
}
```

`createDungeonTask()` 同樣修改，保持一致。

---

### `Services/BattleLogGenerator.swift`

1. `BattleEvent.EventType` 新增 `case skill`：

```swift
enum EventType {
    // ... 現有 case ...
    case skill   // V6-1：技能啟動事件
}
```

2. `generate()` 在 `fromBattleIndex == 0` 且 `task.snapshotSkillKeys` 不為空時，在第一個 `.explore` 事件前插入技能啟動事件：

```swift
if fromBattleIndex == 0 {
    let skillNames = task.snapshotSkillKeys
        .compactMap { SkillDef.find(key: $0)?.name }
        .joined(separator: "」、「")
    if !skillNames.isEmpty {
        events.insert(
            BattleEvent(type: .skill,
                        description: "發動「\(skillNames)」— 出征加成已生效"),
            at: 0
        )
    }
}
```

---

### 呼叫端：`ViewModels/AdventureViewModel.swift`

`startDungeonFloor()` 呼叫 `TaskCreationService` 時，傳入 `player.equippedSkillKeys`：

```swift
try taskCreationService.createDungeonFloorTask(
    floorKey: floorKey,
    durationSeconds: durationSeconds,
    heroStats: heroStats,
    equippedSkillKeys: player.equippedSkillKeys   // V6-1 新增
)
```

---

## 確定性 RNG 保證

- `snapshotSkillKeysRaw` 在出發時寫入，結算時從 task 讀取，不依賴玩家當下狀態
- 技能效果透過 `effectiveStats` 直接影響 `snapshotPower`，無需修改 `DungeonSettlementEngine`
- 相同 seed + 相同技能快照 → 相同戰鬥結果

---

## 驗收標準

- [ ] 選劍士 + 裝備「斬擊強化」出征：`snapshotPower` 比裸裝高 24（ATK +12 → power +24）
- [ ] 未裝備技能出征：行為與 V6-1 前完全一致
- [ ] BattleLogSheet 顯示技能啟動文字（「發動「斬擊強化」— 出征加成已生效」）
- [ ] 相同 seed + 相同技能裝備 → 相同戰鬥結果（確定性）
- [ ] 所有現有測試仍通過
