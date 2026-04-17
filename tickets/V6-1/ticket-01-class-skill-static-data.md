# V6-1 Ticket 01：職業與技能靜態資料

**狀態：** 🔲 待實作
**版本：** V6-1 Phase 1
**依賴：** 無

---

## 目標

定義職業（Class）與技能（Skill）的靜態資料結構，作為後續計算層、UI 的資料來源。
純 Swift struct，不進 SwiftData。

---

## 新建檔案

### `IdleBattleRPG/StaticData/ClassDef.swift`

```swift
import SwiftUI

struct ClassDef {
    let key: String
    let name: String
    let description: String
    let skillKeys: [String]      // 此職業專屬的 5 個技能 key（依解鎖等級排序）
    let baseATKBonus: Int
    let baseDEFBonus: Int
    let baseHPBonus:  Int
    let baseAGIBonus: Int
    let baseDEXBonus: Int
}

extension ClassDef {
    static let all: [ClassDef] = [swordsman, archer, mage, paladin]

    static func find(key: String) -> ClassDef? {
        all.first { $0.key == key }
    }

    var iconName: String {
        switch key {
        case "swordsman": return "sword"
        case "archer":    return "arrow.up.right"
        case "mage":      return "flame.fill"
        case "paladin":   return "shield.fill"
        default:          return "person.fill"
        }
    }

    var themeColor: Color {
        switch key {
        case "swordsman": return .red
        case "archer":    return .green
        case "mage":      return .purple
        case "paladin":   return .blue
        default:          return .gray
        }
    }
}

// MARK: - 四職業資料

extension ClassDef {
    static let swordsman = ClassDef(
        key:          "swordsman",
        name:         "劍士",
        description:  "以力破法，一刀定勝負的前線鬥士。",
        skillKeys:    ["sw_slash_boost", "sw_iron_will", "sw_war_cry", "sw_fierce_blow", "sw_peerless"],
        baseATKBonus: 5,
        baseDEFBonus: 0,
        baseHPBonus:  0,
        baseAGIBonus: 0,
        baseDEXBonus: 0
    )

    static let archer = ClassDef(
        key:          "archer",
        name:         "弓手",
        description:  "疾如風影，先手制人的速攻遊俠。",
        skillKeys:    ["ar_swift_step", "ar_eagle_eye", "ar_wind_walk", "ar_sniper", "ar_phantom_step"],
        baseATKBonus: 0,
        baseDEFBonus: 0,
        baseHPBonus:  0,
        baseAGIBonus: 3,
        baseDEXBonus: 2
    )

    static let mage = ClassDef(
        key:          "mage",
        name:         "法師",
        description:  "詭謀多算，以術輔攻的奧術操縱者。",
        skillKeys:    ["mg_magic_bolt", "mg_arcane_shield", "mg_mana_surge", "mg_time_warp", "mg_arcane_mastery"],
        baseATKBonus: 3,
        baseDEFBonus: 0,
        baseHPBonus:  0,
        baseAGIBonus: 2,
        baseDEXBonus: 0
    )

    static let paladin = ClassDef(
        key:          "paladin",
        name:         "聖騎士",
        description:  "堅不可摧，以盾護身的不滅衛士。",
        skillKeys:    ["pl_iron_guard", "pl_healing_aura", "pl_shield_wall", "pl_blessed_armor", "pl_aegis"],
        baseATKBonus: 0,
        baseDEFBonus: 4,
        baseHPBonus:  15,
        baseAGIBonus: 0,
        baseDEXBonus: 0
    )
}
```

---

### `IdleBattleRPG/StaticData/SkillDef.swift`（取代原版本）

```swift
/// 技能效果種類（出征時套用，影響 snapshotStats）
enum SkillEffect {
    case atkBonus(Int)
    case defBonus(Int)
    case hpBonus(Int)
    case agiBonus(Int)
    case dexBonus(Int)
}

/// 永久技能定義（每職業 5 個，依英雄等級自動解鎖，最多裝備 4 個）
struct SkillDef {
    let key:           String
    let classKey:      String
    let requiredLevel: Int
    let name:          String
    let description:   String
    let effects:       [SkillEffect]
}

extension SkillDef {
    static let all: [SkillDef] = [
        // ── 劍士 ────────────────────────────────
        SkillDef(key: "sw_slash_boost",  classKey: "swordsman", requiredLevel: 3,
                 name: "斬擊強化",  description: "攻擊力大幅提升",
                 effects: [.atkBonus(12)]),
        SkillDef(key: "sw_iron_will",    classKey: "swordsman", requiredLevel: 6,
                 name: "防禦姿態",  description: "出征全程防禦力提升",
                 effects: [.defBonus(10)]),
        SkillDef(key: "sw_war_cry",      classKey: "swordsman", requiredLevel: 10,
                 name: "戰吼",      description: "宣戰之吼，攻擊力再提升",
                 effects: [.atkBonus(20)]),
        SkillDef(key: "sw_fierce_blow",  classKey: "swordsman", requiredLevel: 15,
                 name: "猛擊",      description: "重擊技法，攻擊力大幅強化",
                 effects: [.atkBonus(30)]),
        SkillDef(key: "sw_peerless",     classKey: "swordsman", requiredLevel: 20,
                 name: "無雙斬",    description: "無人可擋的究極斬技",
                 effects: [.atkBonus(45)]),

        // ── 弓手 ────────────────────────────────
        SkillDef(key: "ar_swift_step",   classKey: "archer", requiredLevel: 3,
                 name: "疾風步法",  description: "移動速度提升，ATB 加快",
                 effects: [.agiBonus(4)]),
        SkillDef(key: "ar_eagle_eye",    classKey: "archer", requiredLevel: 6,
                 name: "銳眼訓練",  description: "精準度提升，暴擊率提升",
                 effects: [.dexBonus(4)]),
        SkillDef(key: "ar_wind_walk",    classKey: "archer", requiredLevel: 10,
                 name: "迅風",      description: "風中漫步，速度大幅提升",
                 effects: [.agiBonus(8)]),
        SkillDef(key: "ar_sniper",       classKey: "archer", requiredLevel: 15,
                 name: "神射",      description: "神乎其技的精準射擊",
                 effects: [.dexBonus(8)]),
        SkillDef(key: "ar_phantom_step", classKey: "archer", requiredLevel: 20,
                 name: "幻影步",    description: "殘影交錯，極速移動",
                 effects: [.agiBonus(14)]),

        // ── 法師 ────────────────────────────────
        SkillDef(key: "mg_magic_bolt",     classKey: "mage", requiredLevel: 3,
                 name: "魔力箭",    description: "魔力凝聚成矢，增強攻擊",
                 effects: [.atkBonus(8)]),
        SkillDef(key: "mg_arcane_shield",  classKey: "mage", requiredLevel: 6,
                 name: "魔法護盾",  description: "奧術護盾，防禦力提升",
                 effects: [.defBonus(8)]),
        SkillDef(key: "mg_mana_surge",     classKey: "mage", requiredLevel: 10,
                 name: "魔力衝湧",  description: "魔力爆發，攻擊力大增",
                 effects: [.atkBonus(16)]),
        SkillDef(key: "mg_time_warp",      classKey: "mage", requiredLevel: 15,
                 name: "時流扭曲",  description: "扭曲時間軸，速度與精準同時提升",
                 effects: [.agiBonus(6), .dexBonus(4)]),
        SkillDef(key: "mg_arcane_mastery", classKey: "mage", requiredLevel: 20,
                 name: "奧術精通",  description: "掌握奧術奧義，攻擊達到極致",
                 effects: [.atkBonus(25)]),

        // ── 聖騎士 ──────────────────────────────
        SkillDef(key: "pl_iron_guard",    classKey: "paladin", requiredLevel: 3,
                 name: "鐵壁防禦",  description: "以盾為牆，防禦力提升",
                 effects: [.defBonus(10)]),
        SkillDef(key: "pl_healing_aura",  classKey: "paladin", requiredLevel: 6,
                 name: "治癒光環",  description: "神聖光環環繞，生命值提升",
                 effects: [.hpBonus(30)]),
        SkillDef(key: "pl_shield_wall",   classKey: "paladin", requiredLevel: 10,
                 name: "護盾之牆",  description: "多重護盾疊加，防禦大幅提升",
                 effects: [.defBonus(18)]),
        SkillDef(key: "pl_blessed_armor", classKey: "paladin", requiredLevel: 15,
                 name: "神佑鎧甲",  description: "神之庇護，防禦與生命同時提升",
                 effects: [.defBonus(25), .hpBonus(20)]),
        SkillDef(key: "pl_aegis",         classKey: "paladin", requiredLevel: 20,
                 name: "神盾庇護",  description: "傳說中的神盾，防禦達到極致",
                 effects: [.defBonus(35)]),
    ]

    static func find(key: String) -> SkillDef? {
        all.first { $0.key == key }
    }

    /// 取得某職業在指定等級下已解鎖的技能（含本等級，依解鎖等級排序）
    static func unlocked(classKey: String, atLevel level: Int) -> [SkillDef] {
        all.filter { $0.classKey == classKey && $0.requiredLevel <= level }
            .sorted { $0.requiredLevel < $1.requiredLevel }
    }
}
```

---

## 設計決策

| 決策 | 說明 |
|---|---|
| 4 職業 | 遊戲開始一次選擇，不可更換，強化身份認同感 |
| 每職業 5 個技能 | Lv.3/6/10/15/20 對應 5 個里程碑，最多裝備 4 個 |
| 技能效果純加值 | 套用在 snapshotStats，不影響基礎屬性 |
| ClassDef 基礎加成 | 永久加成，影響所有 HeroStats 計算 |
| 靜態資料 | 不進 SwiftData，保持架構簡潔 |

---

## 驗收標準

- [ ] `ClassDef.all` 包含 4 個職業，key 唯一
- [ ] `SkillDef.all` 包含 20 個技能，key 唯一
- [ ] `SkillDef.unlocked(classKey: "swordsman", atLevel: 6)` 回傳 2 個技能
- [ ] `SkillDef.unlocked(classKey: "paladin", atLevel: 20)` 回傳 5 個技能
- [ ] Build 通過，無 warning
