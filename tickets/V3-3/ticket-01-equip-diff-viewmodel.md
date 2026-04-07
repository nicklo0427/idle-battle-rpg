# V3-3 Ticket 01：換裝差值計算（CharacterViewModel）

**狀態：** ✅ 完成

**依賴：** 無（獨立計算層）

---

## 目標

在 CharacterViewModel 加入純計算方法，給 View 呼叫取得「換上某件裝備後的屬性差值」。
無副作用，不寫入 SwiftData。

---

## 修改一：EquipmentModel computed stats

**檔案：** `IdleBattleRPG/Models/EquipmentModel.swift`

目前 EquipmentModel 沒有彙整屬性的 computed property，需新增：

```swift
/// 含強化加成的實際屬性（用於換裝差值計算）
var totalAtk: Int {
    guard let def = EquipmentDef.find(key: defKey) else { return 0 }
    let base    = def.atkBonus
    let enhance = EnhancementDef.atkBonus(for: slot, level: enhancementLevel)
    return base + enhance
}

var totalDef: Int {
    guard let def = EquipmentDef.find(key: defKey) else { return 0 }
    return def.defBonus + EnhancementDef.defBonus(for: slot, level: enhancementLevel)
}

var totalHp: Int {
    guard let def = EquipmentDef.find(key: defKey) else { return 0 }
    return def.hpBonus + EnhancementDef.hpBonus(for: slot, level: enhancementLevel)
}
```

> `EnhancementDef.atkBonus(for:level:)` 等方法已存在（V2-2 實作），直接使用。

---

## 修改二：StatDiff + equipDiff

**檔案：** `IdleBattleRPG/ViewModels/CharacterViewModel.swift`

```swift
// MARK: - 換裝差值

struct StatDiff {
    let atk: Int     // 正 = 提升，負 = 下降
    let def: Int
    let hp: Int
    /// 戰力差（使用標準公式）
    var power: Int { atk * 2 + Int(Double(def) * 1.5) + hp }
    var hasAnyChange: Bool { atk != 0 || def != 0 || hp != 0 }
}

/// 計算換上 candidate 後相對於目前同部位已裝備裝備的屬性差值
func equipDiff(
    candidate: EquipmentModel,
    equipped: [EquipmentModel]
) -> StatDiff {
    let current = equipped.first { $0.slot == candidate.slot && $0.isEquipped }
    return StatDiff(
        atk: candidate.totalAtk - (current?.totalAtk ?? 0),
        def: candidate.totalDef - (current?.totalDef ?? 0),
        hp:  candidate.totalHp  - (current?.totalHp  ?? 0)
    )
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/EquipmentModel.swift` | ✏️ 修改（新增 totalAtk / totalDef / totalHp） |
| `ViewModels/CharacterViewModel.swift` | ✏️ 修改（新增 StatDiff + equipDiff） |

---

## 驗收標準

- [ ] `EquipmentModel.totalAtk/Def/Hp` 含強化加成（+5 武器 ATK 比 +0 高 5×4=20）
- [ ] 換上相同屬性裝備 → `StatDiff.hasAnyChange == false`
- [ ] 換上更強裝備 → `StatDiff.power > 0`
- [ ] 同部位無已裝備時 → current 視為 (0,0,0)，差值即 candidate 本身屬性
- [ ] Build 無錯誤
