# V6-2 Ticket 02：PlayerStateModel + HeroStats + Seeder

**狀態：** 📋 延後（天賦樹設計待確認）
**版本：** V6-2
**依賴：** T01

---

## 說明

新增天賦點相關 SwiftData 欄位、`HeroStats` 天賦加成計算，以及舊存檔補發天賦點的邏輯。

---

## PlayerStateModel 修改

### 新增欄位（皆有預設值，SwiftData 輕量遷移，無需 VersionedSchema）

```swift
var availableTalentPoints: Int = 0
var investedTalentKeysRaw: String = ""   // 逗號分隔，e.g. "sw_berserker_1,sw_berserker_2"
```

### 新增 computed property

```swift
var investedTalentKeys: [String] {
    investedTalentKeysRaw
        .split(separator: ",")
        .map(String.init)
        .filter { !$0.isEmpty }
}
```

- 路徑：`IdleBattleRPG/Models/PlayerStateModel.swift`

---

## HeroStats 修改

### 新增 applying(talentNodes:) 方法

```swift
func applying(talentNodes: [TalentNodeDef]) -> HeroStats {
    var newAtk = Double(atk)
    var newDef = Double(def)
    var newHp  = Double(hp)
    var newAgi = Double(agi)

    for node in talentNodes {
        for effect in node.effects {
            switch effect {
            case .atkPercent(let p):      newAtk *= (1.0 + p)
            case .defPercent(let p):      newDef *= (1.0 + p)
            case .hpPercent(let p):       newHp  *= (1.0 + p)
            case .critRatePercent(let p): newAgi += p / 0.035   // critRate = agi * 0.035，逆推 AGI 等效
            case .skillDmgPercent(let p): newAtk *= (1.0 + p)   // 技能傷害 = atk * multiplier，折算 ATK
            case .healPercent(let p):     newHp  *= (1.0 + p)   // 治癒量 = maxHp * rate，折算 HP
            }
        }
    }

    return HeroStats(
        atk: Int(newAtk.rounded()),
        def: Int(newDef.rounded()),
        hp:  Int(newHp.rounded()),
        agi: Int(newAgi.rounded()),
        dex: dex
    )
}
```

**注意：** `applying(talentNodes:)` 在 `applying(classDef:)` 之後呼叫，天賦加成疊加於職業加成之上。

- 路徑：`IdleBattleRPG/Models/HeroStats.swift`

---

## HeroStatsService 修改

在 `compute(player:equipped:)` 中，`applying(classDef:)` 後加入天賦計算：

```swift
// 現有：let classStats = baseStats.applying(classDef: classDef)
// 修改後：
let classStats  = baseStats.applying(classDef: classDef)
let talentNodes = player.investedTalentKeys.compactMap { TalentNodeDef.find(key: $0) }
let finalStats  = classStats.applying(talentNodes: talentNodes)
// 後續用 finalStats 取代 classStats
```

- 路徑：`IdleBattleRPG/Services/HeroStatsService.swift`

---

## DatabaseSeeder 修改

在現有的 Player 初始化 / 讀取後，新增補發天賦點邏輯（**幂等**）：

```swift
// 舊存檔補發天賦點：若尚未投入任何天賦且 level > 1，按等級補發
if player.investedTalentKeysRaw.isEmpty && player.availableTalentPoints == 0 && player.heroLevel > 1 {
    player.availableTalentPoints = player.heroLevel - 1
}
```

- 路徑：`IdleBattleRPG/Models/DatabaseSeeder.swift`

---

## 補充：升等時發放天賦點

現有升等邏輯在 `PlayerStateService.levelUp()` 或對應位置，需在升等時同步增加：

```swift
player.availableTalentPoints += 1
```

確認現有升等實作的位置後加入。

---

## 驗收標準

- [ ] `xcodebuild` 通過，無警告（輕量遷移不需要 VersionedSchema）
- [ ] `investedTalentKeys` 正確解析逗號分隔字串（含空字串 edge case）
- [ ] `HeroStats.applying(talentNodes:)` 單次節點計算數值正確
- [ ] `HeroStatsService.compute()` 計算後角色頁戰力數值含天賦加成
- [ ] 新存檔（heroLevel=1）`availableTalentPoints` = 0（正確初始狀態）
- [ ] 舊存檔（heroLevel=5, investedTalentKeysRaw=""）啟動後 `availableTalentPoints` = 4
- [ ] 升等後 `availableTalentPoints += 1`
