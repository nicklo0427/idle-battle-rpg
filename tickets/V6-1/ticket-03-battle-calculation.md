# V6-1 Ticket 03：戰鬥計算層整合技能與天賦

**狀態：** 🔲 待實作
**版本：** V6-1
**依賴：** T01（靜態資料）、T02（PlayerStateModel 欄位）

---

## 目標

讓技能與天賦效果實際影響戰鬥計算，同時保持確定性 RNG 設計不變。

---

## 修改概覽

| 檔案 | 改動 |
|---|---|
| `Services/HeroStatsService.swift` | 天賦加成疊加到 HeroStats |
| `Services/DungeonSettlementEngine.swift` | 接收技能，首場套用倍率 |
| `Services/BattleLogGenerator.swift` | 接收技能，顯示技能觸發文字 |
| `Services/TaskCreationService.swift` | 建立出征任務時記錄 equippedSkillKey |
| `Models/TaskModel.swift` | 新增 `snapshotSkillKey: String?` |

---

## 詳細修改

### 1. `HeroStats.swift` — 天賦加成

```swift
// 新增靜態方法
extension HeroStats {
    /// 套用天賦加成後的屬性
    func applying(talents: [TalentDef]) -> HeroStats {
        var atk = totalATK, def = totalDEF, hp = totalHP
        var agi = totalAGI, dex = totalDEX

        for talent in talents {
            switch talent.effect {
            case .atkBonus(let v):  atk += v
            case .defBonus(let v):  def += v
            case .hpBonus(let v):   hp  += v
            case .agiBonus(let v):  agi += v
            case .dexBonus(let v):  dex += v
            case .critDamageBonus:  break  // 未來擴充
            }
        }

        return HeroStats(
            totalATK: atk, totalDEF: def, totalHP: hp,
            totalAGI: agi, totalDEX: dex
        )
    }
}
```

### 2. `HeroStatsService.swift` — 計算時套用天賦

```swift
static func compute(player: PlayerStateModel, equipped: [EquipmentModel]) -> HeroStats {
    let base = // ... 現有計算 ...
    let talents = TalentDef.unlocked(atLevel: player.heroLevel)
    return base.applying(talents: talents)
}
```

### 3. `TaskModel.swift` — 新增快照欄位

```swift
@Model class TaskModel {
    // ... 現有欄位 ...
    var snapshotSkillKey: String?   // 出發時選中的技能 key
}
```

### 4. `TaskCreationService.swift` — 記錄技能快照

```swift
// createDungeonTask 內
task.snapshotSkillKey = player.equippedSkillKey
```

### 5. `DungeonSettlementEngine.swift` — 技能效果套用

```swift
// 結算時取技能
let skill = TaskModel.snapshotSkillKey.flatMap { SkillDef.find(key: $0) }

// 計算每場勝率時，若 skill == .atkMultiplier 且是第 1 場
// → 臨時將 heroATK 乘以倍率後再計算
```

### 6. `BattleLogGenerator.swift` — 技能觸發文字

首場戰鬥前插入事件：

```swift
// 若有技能，在第一場 .attack 事件前插入
BattleEvent(type: .skill, description: "發動「斬擊強化」— ATK 大幅提升")
```

新增 event type：
```swift
case skill   // 技能觸發
```

---

## 確定性 RNG 保證

- `snapshotSkillKey` 在出發時固定，不依賴結算時的玩家狀態
- 技能效果是純數學計算，同樣 seed + 同樣 skill → 同樣結果
- 天賦加成透過 `heroLevel` snapshot 計算（`snapshotPower` 已有，天賦同理）

---

## 驗收標準

- [ ] Lv.3 英雄自動獲得 3 個天賦（各路線第 1 個）
- [ ] 選「斬擊強化」出征：第一場 ATK 為正常值 ×1.5
- [ ] 選「鐵壁防禦」出征：全程 DEF +20
- [ ] 不選技能出征：行為與 V6-1 前完全一致
- [ ] BattleLogSheet 顯示技能觸發文字
- [ ] 相同 seed + 相同技能 → 相同戰鬥結果（確定性驗證）
- [ ] 所有現有測試仍通過
