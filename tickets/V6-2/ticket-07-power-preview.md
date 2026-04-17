# V6-2 Ticket 07：效果預覽差值

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T10（UI 重構，可收合 DisclosureGroup 已完成）
**修改檔案：** `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

在技能升階按鈕旁顯示升階後的效果差值，讓玩家能明確感知每次投入的回報：
- **被動技能（天賦）**：顯示投入後「戰力 +N」差值
- **主動技能**：顯示升一階後的效果描述（傷害倍率 / 冷卻時間對比）

---

## 被動技能（天賦）戰力預覽

在 `talentNodeRow` 或 `DisclosureGroup` 的投入按鈕左側：

```swift
// 可投入節點旁顯示戰力差值
if canInvest, let current = heroStats {
    // 在目前屬性上疊加此節點一次的效果
    let hypothetical = current.applying(talentNodes: [node])
    let delta = hypothetical.power - current.power
    if delta > 0 {
        Text("+\(delta)")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
            .monospacedDigit()
    }
}
```

`heroStats` 已在 CharacterView 頂層計算（`var heroStats: HeroStats?`），直接複用。
`applying(talentNodes:)` 是純函式，在 View 內呼叫安全。

---

## 主動技能效果預覽

在技能 DisclosureGroup 內，升階按鈕上方顯示「升階後效果」對比行：

```swift
// 目前等級效果
let curLevel  = player.level(of: skill.key)
let nextLevel = curLevel + 1

if nextLevel <= skill.maxLevel {
    HStack {
        Text("升階後")
            .font(.caption2)
            .foregroundStyle(.secondary)
        Spacer()
        Text(skill.effectDescription(at: nextLevel - 1))
            .font(.caption2)
            .foregroundStyle(.blue)
    }
    .padding(.top, 2)
}
```

`skill.effectDescription(at:)` 回傳各等級的效果文字，例如：
- Lv.0（基礎）：「傷害 × 1.5」
- Lv.1（+1 升階）：「傷害 × 1.75」
- Lv.2（+2 升階）：「傷害 × 2.0」

---

## SkillDef 新增 effectDescription(at:)

```swift
// SkillDef.swift extension（配合 T09 實作）
extension SkillDef {
    /// 指定升階次數下的效果描述文字（level: 0 = 未升階基礎值）
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
            return String(format: "攻擊提升 +%.0f%%", (bonus + bonus * Double(level) * 0.25) * 100)
        case .enemyAtkDown(let r):
            return String(format: "敵方攻擊 -%.0f%%", (r + r * Double(level) * 0.25) * 100)
        case .damageAndEnemyAtkDown(let dmg, let r):
            return String(format: "傷害 × %.2f · 敵攻 -%.0f%%", dmg * m, (r + r * Double(level) * 0.25) * 100)
        }
    }
}
```

---

## 驗收標準

- [ ] 天賦可投入節點旁顯示藍色「+N 戰力」差值（N > 0 時才顯示）
- [ ] 已投入 / 鎖定節點不顯示差值
- [ ] 技能升階按鈕上方顯示「升階後效果」對比文字（藍色）
- [ ] 已達 maxLevel 的技能不顯示升階預覽
- [ ] `xcodebuild` 通過，無新警告
