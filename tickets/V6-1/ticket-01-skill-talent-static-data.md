# V6-1 Ticket 01：技能／天賦靜態資料設計

**狀態：** 🔲 待實作
**版本：** V6-1（技能 / 天賦系統第一批）
**依賴：** 無

---

## 目標

定義全部技能與天賦的靜態資料結構，作為後續計算層、UI 的資料來源。
純 Swift struct，不進 SwiftData。

---

## 新建檔案

### `IdleBattleRPG/StaticData/SkillDef.swift`

```swift
/// 技能效果種類
enum SkillEffect {
    case atkMultiplier(Double)   // 攻擊倍率（僅首場生效）
    case defBonus(Int)           // DEF 加成（全程）
    case agiBonus(Int)           // AGI 加成（全程，影響 ATB 充能）
}

/// 主動技能定義（每次出征選一個，3 選 1）
struct SkillDef {
    let key:         String
    let name:        String
    let description: String
    let effect:      SkillEffect
}

extension SkillDef {
    static let all: [SkillDef] = [
        SkillDef(
            key:         "slash_boost",
            name:        "斬擊強化",
            description: "首場戰鬥 ATK ×1.5",
            effect:      .atkMultiplier(1.5)
        ),
        SkillDef(
            key:         "iron_guard",
            name:        "鐵壁防禦",
            description: "出征全程 DEF +20",
            effect:      .defBonus(20)
        ),
        SkillDef(
            key:         "swift_step",
            name:        "疾風步法",
            description: "出征全程 AGI +4，加快 ATB 充能",
            effect:      .agiBonus(4)
        ),
    ]

    static func find(key: String) -> SkillDef? {
        all.first { $0.key == key }
    }
}
```

---

### `IdleBattleRPG/StaticData/TalentDef.swift`

```swift
/// 天賦路線
enum TalentPath {
    case attack    // 攻擊路線：ATK / 爆傷相關
    case defense   // 防禦路線：DEF / HP 相關
    case speed     // 速攻路線：AGI / DEX 相關
}

/// 天賦效果種類
enum TalentEffect {
    case atkBonus(Int)         // ATK 永久加成
    case defBonus(Int)         // DEF 永久加成
    case hpBonus(Int)          // HP 永久加成
    case agiBonus(Int)         // AGI 永久加成
    case dexBonus(Int)         // DEX 永久加成
    case critDamageBonus(Double) // 暴擊傷害倍率加成（未來擴充）
}

/// 被動天賦定義（達到對應等級自動解鎖）
struct TalentDef {
    let key:           String
    let path:          TalentPath
    let requiredLevel: Int       // 達到此等級自動解鎖
    let name:          String
    let description:   String
    let effect:        TalentEffect
}

extension TalentDef {
    static let all: [TalentDef] = [

        // ── 攻擊路線 ────────────────────────
        TalentDef(key: "atk_1",  path: .attack,  requiredLevel: 3,
                  name: "鋒芒初露",   description: "ATK +3",  effect: .atkBonus(3)),
        TalentDef(key: "atk_2",  path: .attack,  requiredLevel: 6,
                  name: "利刃磨礪",   description: "ATK +5",  effect: .atkBonus(5)),
        TalentDef(key: "atk_3",  path: .attack,  requiredLevel: 10,
                  name: "斬鐵如泥",   description: "ATK +8",  effect: .atkBonus(8)),
        TalentDef(key: "atk_4",  path: .attack,  requiredLevel: 15,
                  name: "破甲重擊",   description: "ATK +12", effect: .atkBonus(12)),
        TalentDef(key: "atk_5",  path: .attack,  requiredLevel: 20,
                  name: "無雙劍意",   description: "ATK +18", effect: .atkBonus(18)),

        // ── 防禦路線 ────────────────────────
        TalentDef(key: "def_1",  path: .defense, requiredLevel: 3,
                  name: "堅盾初形",   description: "DEF +3",  effect: .defBonus(3)),
        TalentDef(key: "def_2",  path: .defense, requiredLevel: 6,
                  name: "厚甲鍛造",   description: "HP +15",  effect: .hpBonus(15)),
        TalentDef(key: "def_3",  path: .defense, requiredLevel: 10,
                  name: "鋼鐵意志",   description: "DEF +6",  effect: .defBonus(6)),
        TalentDef(key: "def_4",  path: .defense, requiredLevel: 15,
                  name: "不屈之軀",   description: "HP +30",  effect: .hpBonus(30)),
        TalentDef(key: "def_5",  path: .defense, requiredLevel: 20,
                  name: "盾牆壁壘",   description: "DEF +10", effect: .defBonus(10)),

        // ── 速攻路線 ────────────────────────
        TalentDef(key: "spd_1",  path: .speed,   requiredLevel: 3,
                  name: "輕步初學",   description: "AGI +2",  effect: .agiBonus(2)),
        TalentDef(key: "spd_2",  path: .speed,   requiredLevel: 6,
                  name: "銳眼訓練",   description: "DEX +2",  effect: .dexBonus(2)),
        TalentDef(key: "spd_3",  path: .speed,   requiredLevel: 10,
                  name: "迅影身法",   description: "AGI +3",  effect: .agiBonus(3)),
        TalentDef(key: "spd_4",  path: .speed,   requiredLevel: 15,
                  name: "精準瞄擊",   description: "DEX +4",  effect: .dexBonus(4)),
        TalentDef(key: "spd_5",  path: .speed,   requiredLevel: 20,
                  name: "無影之速",   description: "AGI +5",  effect: .agiBonus(5)),
    ]

    static func find(key: String) -> TalentDef? {
        all.first { $0.key == key }
    }

    /// 取得玩家在某等級下已解鎖的天賦
    static func unlocked(atLevel level: Int) -> [TalentDef] {
        all.filter { $0.requiredLevel <= level }
    }
}
```

---

## 設計決策

| 決策 | 說明 |
|---|---|
| 技能 3 選 1 | 出征前選擇，增加策略感而不複雜 |
| 天賦自動解鎖 | 達等級自動生效，不需額外操作，符合放置 AFK 風格 |
| 每路線 5 個節點 | Lv.3/6/10/15/20 對應 5 個里程碑 |
| 天賦效果純加值 | MVP 實作，未來可擴充倍率型天賦 |
| 靜態資料 | 不進 SwiftData，保持架構簡潔 |

---

## 驗收標準

- [ ] `SkillDef.all` 包含 3 個技能，key 唯一
- [ ] `TalentDef.all` 包含 15 個天賦（3 路線 × 5 節點），key 唯一
- [ ] `TalentDef.unlocked(atLevel: 10)` 回傳 9 個天賦（每路線前 3 個）
- [ ] Build 通過，無 warning
