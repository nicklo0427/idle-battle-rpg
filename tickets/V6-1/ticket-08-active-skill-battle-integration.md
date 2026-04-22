# V6-1 Ticket 08：主動技能戰鬥整合

**狀態：** ✅ 已完成
**版本：** V6-1（修訂）
**依賴：** T07 完成
**修改檔案：**
- `IdleBattleRPG/Models/HeroStats.swift`
- `IdleBattleRPG/Services/TaskCreationService.swift`
- `IdleBattleRPG/Services/BattleLogGenerator.swift`

---

## 背景

T07 將技能改為主動 `ActiveEffect`，本 ticket 負責：
1. 從 `HeroStats` 移除已廢棄的被動技能疊加方法
2. 更新 `TaskCreationService`，技能不再 bake 進 snapshotPower
3. 在 `BattleLogGenerator` 實作方案 A 冷卻計時器，讓技能在戰鬥中真正觸發

---

## 1. HeroStats.swift — 移除 `applying(skills:)`

刪除以下 extension method（不再需要，技能效果改為戰鬥中動態觸發）：

```swift
// 刪除：
extension HeroStats {
    func applying(skills: [SkillDef]) -> HeroStats { ... }
}
```

保留（不動）：
```swift
extension HeroStats {
    func applying(classDef: ClassDef) -> HeroStats { ... }  // 職業基礎加成仍為被動
}
```

---

## 2. TaskCreationService.swift — 移除技能快照疊加

在 `createDungeonFloorTask()` 和 `createDungeonTask()` 中：

**移除：**
```swift
let equippedSkills  = equippedSkillKeys.compactMap { SkillDef.find(key: $0) }
let effectiveStats  = heroStats.applying(skills: equippedSkills)
// snapshotPower / snapshotAgi / snapshotDex 使用 effectiveStats
```

**改為：**
```swift
// snapshotPower / snapshotAgi / snapshotDex 直接使用 heroStats（只含職業加成）
task.snapshotPower = heroStats.power
task.snapshotAgi   = heroStats.totalAGI
task.snapshotDex   = heroStats.totalDEX
```

**保留（不動）：**
```swift
task.snapshotSkillKeysRaw = equippedSkillKeys.joined(separator: ",")
// 戰鬥生成器仍需要 skill keys 來觸發主動技能
```

> ⚠️ 影響：snapshotPower 不再包含技能加成，顯示的出征戰力只反映職業 + 裝備 + 屬性點。
> 技能效果改為戰鬥中動態觸發，體現在戰鬥記錄的實際傷害數字上。

---

## 3. BattleLogGenerator.swift — 主動技能觸發邏輯

### 3.1 移除舊的出征前 `.skill` 事件

移除 `generate()` 開頭插入 "發動技能 — 出征加成已生效" 的程式碼塊，
改為更簡短的裝備確認文字（或直接移除，技能效果在戰鬥中自然顯現）。

> 可選保留：「帶著【技能名】出征」作為出征前提示。

### 3.2 讀取 active skills

在 `generate()` 中：
```swift
let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }
```

傳入 `makeBattleEvents(...)` 參數。

### 3.3 `makeBattleEvents(...)` — 核心修改

#### 初始化（進入每場戰鬥時）

```swift
var elapsedCombatTime = 0.0
// 每個技能的下次觸發時間 = 1 個冷卻週期（不在第 0 秒立即觸發）
var skillNextFireTime: [String: Double] = Dictionary(
    uniqueKeysWithValues: activeSkills.map { ($0.key, Double($0.cooldownSeconds)) }
)

// 單次效果狀態（用完後重置）
var heroAtkMultiplier  = 1.0   // 受 .heroAtkUp 影響
var enemyAtkMultiplier = 1.0   // 受 .enemyAtkDown 影響
```

#### 戰鬥回合主迴圈

```swift
while heroHp > 0 && enemyHp > 0 && round < maxRounds {
    // 1. 累計英雄行動時間
    elapsedCombatTime += heroChargeTime

    // 2. 按裝備槽順序觸發到期技能（在英雄攻擊前）
    for skill in activeSkills {
        guard elapsedCombatTime >= (skillNextFireTime[skill.key] ?? .infinity) else { continue }

        skillNextFireTime[skill.key]! += Double(skill.cooldownSeconds)

        switch skill.effect {
        case .damage(let m):
            let dmg = max(1, Int(Double(heroAtk) * m))
            enemyHp = max(0, enemyHp - dmg)
            allEvents.append(BattleEvent(
                type: .skill,
                description: "【\(skill.name)】對敵造成 \(dmg) 傷害",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))
            if enemyHp <= 0 { break }  // 技能擊殺，結束回合

        case .heal(let m):
            let restored = Int(Double(heroMaxHp) * m)
            heroHp = min(heroMaxHp, heroHp + restored)
            allEvents.append(BattleEvent(
                type: .skill,
                description: "【\(skill.name)】恢復 \(restored) HP",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))

        case .damageAndHeal(let dm, let hm):
            let dmg      = max(1, Int(Double(heroAtk) * dm))
            let restored = Int(Double(heroMaxHp) * hm)
            enemyHp = max(0, enemyHp - dmg)
            heroHp  = min(heroMaxHp, heroHp + restored)
            allEvents.append(BattleEvent(
                type: .skill,
                description: "【\(skill.name)】造成 \(dmg) 傷害，恢復 \(restored) HP",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))
            if enemyHp <= 0 { break }

        case .heroAtkUp(let b):
            heroAtkMultiplier = 1.0 + b
            let pct = Int(b * 100)
            allEvents.append(BattleEvent(
                type: .skill,
                description: "【\(skill.name)】下次攻擊傷害提升 \(pct)%",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))

        case .enemyAtkDown(let r):
            enemyAtkMultiplier = 1.0 - r
            let pct = Int(r * 100)
            allEvents.append(BattleEvent(
                type: .skill,
                description: "【\(skill.name)】敵方下次攻擊削弱 \(pct)%",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))
        }

        // 技能擊殺時跳出技能迴圈
        if enemyHp <= 0 { break }
    }

    // 技能可能已擊殺敵人，跳出主迴圈
    if enemyHp <= 0 { break }

    // 3. 英雄攻擊（套用 heroAtkMultiplier）
    var heroDmg = max(1, heroAtk - enemyDef + rng.nextInt(in: -2...2))
    if rng.nextDouble() < critRate { heroDmg = Int(Double(heroDmg) * 1.5); isCrit = true }
    heroDmg = Int(Double(heroDmg) * heroAtkMultiplier)
    heroAtkMultiplier = 1.0   // 重置

    enemyHp = max(0, enemyHp - heroDmg)
    allEvents.append(/* .attack event */)

    if enemyHp <= 0 { break }

    // 4. 敵方反擊（套用 enemyAtkMultiplier）
    var enemyDmgActual = max(1, enemyAtk - heroDef + rng.nextInt(in: -2...2))
    enemyDmgActual = Int(Double(enemyDmgActual) * enemyAtkMultiplier)
    enemyAtkMultiplier = 1.0   // 重置

    heroHp = max(0, heroHp - enemyDmgActual)
    allEvents.append(/* .damage event */)

    round += 1
}
```

### 3.4 mg_frost_nova 實作決策

`mg_frost_nova`（冰霜新星）的設計為「傷害 + 敵方減益」組合，目前 `ActiveEffect` 無此類型。

**選擇方案（T07/T08 一起決定）：**

**Option A（推薦）：** 在 `ActiveEffect` 新增第 6 個 case：
```swift
case damageAndEnemyAtkDown(dmgMultiplier: Double, reduction: Double)
```
battle loop 中：先造成傷害，再設 `enemyAtkMultiplier`。

**Option B：** 將 mg_frost_nova 簡化為純傷害（`.damage(1.2)`），
description 說明「冰霜減速效果暫緩 V6-2」。

---

## heroAtk 計算（不變）

```swift
let heroAtk = max(10, snapshotPower / 4)
```

技能傷害與普通攻擊使用相同的 `heroAtk` 基礎值，保持一致性。

---

## 驗收標準

- [ ] `HeroStats.applying(skills:)` 方法已移除，`applying(classDef:)` 保留
- [ ] `TaskCreationService` 不再呼叫 `applying(skills:)`，snapshotPower 只含職業加成
- [ ] `snapshotSkillKeysRaw` 仍正確存入 task
- [ ] `BattleLogGenerator` 讀取 `snapshotSkillKeys` 並觸發主動技能
- [ ] 技能在正確時間觸發（`elapsedCombatTime >= skillNextFireTime`）
- [ ] 同一場戰鬥可觸發多次（nextFireTime 正確遞增）
- [ ] 多技能裝備時各自獨立計時（不互相干擾）
- [ ] `.heroAtkUp` 效果在下次普通攻擊後重置
- [ ] `.enemyAtkDown` 效果在下次敵方攻擊後重置
- [ ] 技能擊殺敵人時正確結束回合（不繼續執行後續攻擊）
- [ ] `xcodebuild` 通過，無 error
