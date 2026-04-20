# V6-3 Ticket 05：狀態效果系統（燃燒 / 中毒 / 暈眩 / 弱化）

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T01（`runCombatCore` 已在 battlePending 路徑下被使用）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogGenerator.swift`
- `IdleBattleRPG/StaticData/SkillDef.swift`
- `IdleBattleRPG/Views/BattleLogSheet.swift`

---

## 說明

新增四種狀態效果，讓技能觸發後可施加持續性效果，增加戰鬥的策略深度與視覺可讀性。
狀態效果整合在現有的 `runCombatCore` 模擬迴圈中，每個 ATB 週期處理一次。

---

## StatusEffect 型別

新增在 `BattleLogGenerator.swift` 頂層（與 `BattleEvent` 同層）：

```swift
enum StatusEffect: Equatable {
    /// 燃燒：每回合造成固定傷害，持續 N 回合
    case burn(remainingTurns: Int, dpt: Int)
    /// 中毒：每回合傷害 = dptPerStack × stacks，同一場可疊加
    case poison(stacks: Int, dptPerStack: Int)
    /// 暈眩：下次行動時跳過，持續 N 回合
    case stun(remainingTurns: Int)
    /// 弱化：ATK 乘數下降，持續 N 回合
    case weakened(atkReduction: Double, remainingTurns: Int)
}
```

---

## BattleEvent.EventType 新增 case

```swift
enum EventType {
    // ... 現有 8 個 case（skill / explore / encounter / attack / damage / victory / defeat / heal）...
    case statusApplied   // 技能施加狀態效果
    case statusTick      // 狀態效果本回合觸發（如燃燒傷害）
    case statusExpired   // 狀態效果結束
}
```

---

## ActiveEffect 新增 case

在 `SkillDef.swift` 的 `ActiveEffect` enum 末尾新增：

```swift
enum ActiveEffect {
    // ... 現有 6 個 case ...
    case damageAndBurn(damage: Double, dpt: Int, duration: Int)
        // 傷害 + 對敵施加燃燒（每回合 dpt 傷害，持續 duration 回合）
    case damageAndPoison(damage: Double, dptPerStack: Int)
        // 傷害 + 對敵施加中毒（可疊加）
    case stunAndDamage(damage: Double, stunDuration: Int)
        // 暈眩敵方（跳過 N 次行動）+ 傷害
    case damageAndWeaken(damage: Double, reduction: Double, duration: Int)
        // 傷害 + 使敵方 ATK 降低 reduction（0.0–1.0）持續 duration 回合
}
```

---

## 技能靜態資料更新

各職業選 1 個技能改用含狀態效果的 `ActiveEffect`（其餘 16 個技能不動）：

| 職業 | 技能 key | 原 effect | 新 effect |
|---|---|---|---|
| 劍士（swordsman） | `sw_flame_slash` | `.damage(1.5)` | `.damageAndBurn(damage: 1.2, dpt: 8, duration: 2)` |
| 弓手（archer） | `ar_poison_arrow` | `.damage(1.3)` | `.damageAndPoison(damage: 1.0, dptPerStack: 5)` |
| 法師（mage） | `mg_frost_nova` | `.enemyAtkDown(0.3)` | `.stunAndDamage(damage: 0.8, stunDuration: 1)` |
| 聖騎士（paladin） | 不變 | — | 保留治癒風格，不改 |

> 若上述 key 與現有靜態資料不符，請以 `SkillDef.all` 中的實際 key 為準，
> 選擇語意最接近「燃燒 / 毒 / 冰凍」的技能替換。

---

## effectDescription(at:) 新增 case

`SkillDef.effectDescription(at:)` 中補上新 case 的描述文字：

```swift
case .damageAndBurn(let dmg, let dpt, let dur):
    return String(format: "傷害 × %.2f · 燃燒 %d 傷 × %d 回合", dmg * m, dpt, dur)
case .damageAndPoison(let dmg, let dpt):
    return String(format: "傷害 × %.2f · 中毒 %d 傷（可疊加）", dmg * m, dpt)
case .stunAndDamage(let dmg, let dur):
    return String(format: "傷害 × %.2f · 暈眩 %d 回合", dmg * m, dur)
case .damageAndWeaken(let dmg, let r, let dur):
    return String(format: "傷害 × %.2f · 敵攻 -%.0f%% × %d 回合", dmg * m, r * 100, dur)
```

---

## runCombatCore 修改

在 `BattleLogGenerator.runCombatCore(...)` 的簽名和實作中：

### 新增局部狀態追蹤

```swift
var heroStatuses:  [StatusEffect] = []
var enemyStatuses: [StatusEffect] = []
```

### 每個 ATB tick 開始時處理狀態效果

```swift
// 新增 processStatuses helper（BattleLogGenerator private 方法）
private static func processStatuses(
    statuses:    inout [StatusEffect],
    hp:          inout Int,
    maxHp:       Int,
    isHero:      Bool,
    events:      inout [BattleEvent],
    heroHpAfter: Int, enemyHpAfter: Int,
    heroMaxHp: Int,  enemyMaxHp: Int
) {
    var next: [StatusEffect] = []
    for status in statuses {
        switch status {

        case .burn(let turns, let dpt):
            hp = max(0, hp - dpt)
            let who = isHero ? "英雄" : "敵方"
            events.append(BattleEvent(
                type: .statusTick,
                description: "\(who)燃燒傷害 -\(dpt)",
                heroHpAfter: isHero ? hp : heroHpAfter,
                enemyHpAfter: isHero ? enemyHpAfter : hp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))
            if turns > 1 { next.append(.burn(remainingTurns: turns - 1, dpt: dpt)) }
            else { events.append(/* .statusExpired 燃燒結束 */) }

        case .poison(let stacks, let dpt):
            let dmg = dpt * stacks
            hp = max(0, hp - dmg)
            events.append(/* .statusTick 中毒 × stacks */)
            next.append(status)   // 中毒不自動消退（整場持續，透過疊加增加）

        case .stun(let turns):
            // 暈眩在行動前（技能 / 普攻觸發時）判斷，此處只做倒數
            if turns > 1 { next.append(.stun(remainingTurns: turns - 1)) }
            else { events.append(/* .statusExpired 暈眩解除 */) }

        case .weakened(let r, let turns):
            // 弱化在計算 ATK 時使用 (1 - atkReduction)，此處只做倒數
            if turns > 1 { next.append(.weakened(atkReduction: r, remainingTurns: turns - 1)) }
            else { events.append(/* .statusExpired 弱化解除 */) }
        }
    }
    statuses = next
}
```

### 暈眩跳過行動

在英雄或敵方準備行動前加入判斷：

```swift
// 英雄攻擊前
if heroStatuses.contains(where: { if case .stun = $0 { return true }; return false }) {
    events.append(/* 英雄被暈眩，跳過行動 */)
    heroStatuses = heroStatuses.compactMap { /* stun turns - 1 */ }
    continue
}
```

### 技能施加狀態效果

在 `runCombatCore` 的技能觸發 switch 中，新增 ActiveEffect case 的處理：

```swift
case .damageAndBurn(let dmgMul, let dpt, let dur):
    let dmg = max(1, Int(Double(heroAtk) * dmgMul * upgradeM))
    enemyHp = max(0, enemyHp - dmg)
    enemyStatuses.append(.burn(remainingTurns: dur, dpt: dpt))
    events.append(/* .statusApplied 燃燒施加 */)
    events.append(/* .attack 傷害 */)

case .damageAndPoison(let dmgMul, let dptPerStack):
    let dmg = max(1, Int(Double(heroAtk) * dmgMul * upgradeM))
    enemyHp = max(0, enemyHp - dmg)
    // 疊加 poison（找現有 case 修改 stacks，或新增一層）
    if let idx = enemyStatuses.firstIndex(where: { if case .poison = $0 { return true }; return false }) {
        if case .poison(let s, let d) = enemyStatuses[idx] {
            enemyStatuses[idx] = .poison(stacks: s + 1, dptPerStack: d)
        }
    } else {
        enemyStatuses.append(.poison(stacks: 1, dptPerStack: dptPerStack))
    }
    events.append(/* .statusApplied 中毒施加 */)

case .stunAndDamage(let dmgMul, let dur):
    let dmg = max(1, Int(Double(heroAtk) * dmgMul * upgradeM))
    enemyHp = max(0, enemyHp - dmg)
    enemyStatuses.append(.stun(remainingTurns: dur))
    events.append(/* .statusApplied 暈眩施加 */)

case .damageAndWeaken(let dmgMul, let reduction, let dur):
    let dmg = max(1, Int(Double(heroAtk) * dmgMul * upgradeM))
    enemyHp = max(0, enemyHp - dmg)
    enemyStatuses.append(.weakened(atkReduction: reduction, remainingTurns: dur))
    events.append(/* .statusApplied 弱化施加 */)
```

---

## BattleLogSheet 新增 icon / color

```swift
// eventIconView(_ type:) 新增
case .statusApplied: Image(systemName: "flame.fill").foregroundStyle(.orange)
case .statusTick:    Image(systemName: "drop.fill").foregroundStyle(.purple)
case .statusExpired: Image(systemName: "wind").foregroundStyle(.secondary)

// eventColor(_ type:) 新增
case .statusApplied: return .orange
case .statusTick:    return .purple
case .statusExpired: return .secondary
```

---

## 驗收標準

- [x] 劍士「烈火斬」觸發後，後續 `.statusTick` 燃燒傷害事件在 log 可見
- [x] 弓手毒箭同一場命中兩次 → 中毒堆疊，每回合傷害 × 2
- [x] 法師冰霜技能觸發 → 敵方跳過下一次行動，log 顯示「敵方被暈眩，無法行動！」
- [x] 弱化期間敵方 ATK 計算正確降低（乘以 `1 - atkReduction`）
- [x] 未受影響的 16 個技能行為完全不變
- [x] 舊 `effectDescription(at:)` 舊 case 描述不受影響
- [x] BattleLogSheet 狀態效果 icon 顯示正確顏色
- [x] `xcodebuild` 通過，無新警告
