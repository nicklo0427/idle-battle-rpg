# V6-2 Ticket 01：TalentDef 靜態資料

**狀態：** 🔲 待實作
**版本：** V6-2
**依賴：** V6-1 完成

---

## 說明

新增 `TalentDef.swift` 靜態資料檔，定義天賦效果型別（`TalentEffect`）、天賦節點（`TalentNodeDef`）、天賦路線（`TalentRouteDef`），以及全部 8 條路線 × 5 個節點 = 40 個節點的靜態資料。

**不進 SwiftData**，純 Swift struct。

---

## 新增型別

### TalentEffect enum

```swift
enum TalentEffect {
    case atkPercent(Double)       // ATK 百分比加成，e.g. 0.03 = +3%
    case defPercent(Double)       // DEF 百分比加成
    case hpPercent(Double)        // HP 百分比加成
    case critRatePercent(Double)  // 暴擊率加成（折算為 AGI 等效值）
    case skillDmgPercent(Double)  // 技能傷害倍率加成（折算為 ATK 等效值）
    case healPercent(Double)      // 治癒量加成（折算為 HP 等效值）
}
```

### TalentNodeDef struct

```swift
struct TalentNodeDef {
    let key:         String           // 唯一識別，e.g. "sw_berserker_1"
    let name:        String           // 顯示名稱，e.g. "蠻力突破"
    let description: String           // 效果描述，e.g. "ATK +3%"
    let routeKey:    String           // 所屬路線 key
    let nodeIndex:   Int              // 在路線中的位置（0-based，0 = 第一個）
    let effects:     [TalentEffect]   // 可有多個效果（N5 常有複合效果）
}
```

### TalentRouteDef struct

```swift
struct TalentRouteDef {
    let key:              String           // e.g. "sw_berserker"
    let name:             String           // e.g. "狂戰士"
    let classKey:         String           // 所屬職業 key
    let themeDescription: String           // 一句話描述路線風格
    let nodes:            [TalentNodeDef]  // 按 nodeIndex 排序，共 5 個

    static func all(for classKey: String) -> [TalentRouteDef]
    static func find(key: String) -> TalentRouteDef?
}

extension TalentNodeDef {
    static func find(key: String) -> TalentNodeDef?
    var effectSummary: String  // 用於 UI 顯示，e.g. "ATK +3%"
}
```

---

## 靜態資料（8 路線 × 5 節點）

### 劍士（classKey: "swordsman"）

**狂戰士路線（sw_berserker）** — 以傷換傷，高爆發攻擊
| key | name | effects |
|---|---|---|
| sw_berserker_1 | 蠻力突破 | ATK +3% |
| sw_berserker_2 | 戰意高漲 | ATK +5% |
| sw_berserker_3 | 致命衝動 | ATK +5%, Crit +2% |
| sw_berserker_4 | 血怒覺醒 | ATK +8% |
| sw_berserker_5 | 不滅戰魂 | ATK +10% |

**鐵壁路線（sw_ironwall）** — 以守為攻，堅不可摧
| key | name | effects |
|---|---|---|
| sw_ironwall_1 | 硬化皮膚 | DEF +3% |
| sw_ironwall_2 | 強壯體魄 | HP +5% |
| sw_ironwall_3 | 鐵甲磨礪 | DEF +5% |
| sw_ironwall_4 | 生命汲取 | HP +8% |
| sw_ironwall_5 | 鋼鐵意志 | DEF +8%, HP +5% |

### 弓手（classKey: "archer"）

**精準路線（ar_precision）** — 精心瞄準，必中要害
| key | name | effects |
|---|---|---|
| ar_precision_1 | 鷹眼觀察 | Crit +3% |
| ar_precision_2 | 穩定呼吸 | Crit +3% |
| ar_precision_3 | 要害穿刺 | SkillDmg +5% |
| ar_precision_4 | 獵手本能 | Crit +5% |
| ar_precision_5 | 神射境界 | Crit +5%, SkillDmg +10% |

**毒箭路線（ar_poison）** — 侵蝕削弱，持續消耗
| key | name | effects |
|---|---|---|
| ar_poison_1 | 淬毒箭頭 | ATK +3% |
| ar_poison_2 | 腐蝕劑量 | SkillDmg +5% |
| ar_poison_3 | 劇毒萃取 | ATK +5% |
| ar_poison_4 | 蔓延感染 | SkillDmg +8% |
| ar_poison_5 | 致命毒素 | ATK +8%, SkillDmg +5% |

### 法師（classKey: "mage"）

**爆發路線（mg_burst）** — 蓄積魔力，一擊必殺
| key | name | effects |
|---|---|---|
| mg_burst_1 | 魔力聚焦 | SkillDmg +5% |
| mg_burst_2 | 靈能共鳴 | SkillDmg +5% |
| mg_burst_3 | 元素過載 | SkillDmg +8% |
| mg_burst_4 | 魔法強化 | ATK +5% |
| mg_burst_5 | 奧術暴走 | SkillDmg +10% |

**結界路線（mg_barrier）** — 魔力護盾，以耐制勝
| key | name | effects |
|---|---|---|
| mg_barrier_1 | 魔力皮膚 | HP +5% |
| mg_barrier_2 | 反射護盾 | DEF +3% |
| mg_barrier_3 | 生命強化 | HP +8% |
| mg_barrier_4 | 治癒波動 | Heal +10% |
| mg_barrier_5 | 不朽之軀 | HP +10% |

### 聖騎士（classKey: "paladin"）

**神聖路線（pl_holy）** — 神聖光輝，治癒庇護
| key | name | effects |
|---|---|---|
| pl_holy_1 | 聖光觸碰 | Heal +5% |
| pl_holy_2 | 神聖祈禱 | HP +5% |
| pl_holy_3 | 光明恩賜 | Heal +8% |
| pl_holy_4 | 聖域守護 | HP +8% |
| pl_holy_5 | 神聖奇蹟 | Heal +15% |

**審判路線（pl_judgment）** — 神聖審判，以正義之名傷敵
| key | name | effects |
|---|---|---|
| pl_judgment_1 | 正義之怒 | ATK +3% |
| pl_judgment_2 | 神聖烙印 | SkillDmg +5% |
| pl_judgment_3 | 聖徒鍛鍊 | ATK +5% |
| pl_judgment_4 | 神裁印記 | SkillDmg +8% |
| pl_judgment_5 | 最終審判 | ATK +8%, SkillDmg +5% |

---

## 實作位置

- 新建：`IdleBattleRPG/StaticData/TalentDef.swift`

---

## 驗收標準

- [ ] `TalentRouteDef.all(for:)` 對每個職業 key 回傳恰好 2 條路線
- [ ] 每條路線恰好 5 個節點，`nodeIndex` 為 0–4
- [ ] 所有 `key` 唯一，無重複
- [ ] `TalentNodeDef.find(key:)` 可正確查詢
- [ ] `effectSummary` 能正確格式化（e.g. `"ATK +3%"`、`"ATK +8% · SkillDmg +5%"`）
