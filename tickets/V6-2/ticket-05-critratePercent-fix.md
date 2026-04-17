# V6-2 Ticket 05：critRatePercent Bug Fix

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T01–T04
**修改檔案：** `IdleBattleRPG/Models/HeroStats.swift`

---

## 問題說明

`HeroStats.applying(talentNodes:)` 中，`critRatePercent` 天賦效果被錯誤地疊加到 `AGI`（敏捷），
但戰鬥暴擊率公式用的是 `DEX`（靈巧）：

```swift
// BattleLogGenerator.swift
let critRate = min(0.35, Double(snapshotDex) * 0.035)
```

AGI 影響的是 ATB 填充速度（`heroChargeTime = 1.8 - snapshotAgi * 0.06`），與暴擊無關。
結果：弓手精準路線（`ar_precision_1/2/4/5`）的 Crit +3%～+5% 天賦完全沒有提升暴擊率。

---

## 修正內容

`IdleBattleRPG/Models/HeroStats.swift`，`applying(talentNodes:)` 方法：

```swift
func applying(talentNodes: [TalentNodeDef]) -> HeroStats {
    var atk = Double(totalATK)
    var def = Double(totalDEF)
    var hp  = Double(totalHP)
    var agi = Double(totalAGI)
    var dex = Double(totalDEX)          // ← 新增

    for node in talentNodes {
        for effect in node.effects {
            switch effect {
            case .critRatePercent(let p): dex += p / 0.035   // ← AGI 改為 DEX
            // ... 其餘不變
            }
        }
    }

    return HeroStats(
        totalATK: Int(atk.rounded()),
        totalDEF: Int(def.rounded()),
        totalHP:  Int(hp.rounded()),
        totalAGI: Int(agi.rounded()),
        totalDEX: Int(dex.rounded())    // ← 改為回傳 dex 變數
    )
}
```

---

## 驗收標準

- [x] 弓手投入 `ar_precision_1`（Crit +3%）後，角色頁 DEX 數值上升
- [x] AGI 不受 critRatePercent 天賦影響
- [x] `xcodebuild` 通過
