# V6-1 Ticket 07：SkillDef 主動技能重設計（靜態資料）

**狀態：** ✅ 已完成
**版本：** V6-1（修訂）
**依賴：** T01–T05 已完成
**修改檔案：** `IdleBattleRPG/StaticData/SkillDef.swift`

---

## 背景

T01 實作的技能系統為純被動屬性加成（ATK +12 等），在出征時 bake 進 snapshotPower。
本 ticket 將全部 20 個技能重設計為**主動戰鬥技能**，戰鬥中自動觸發（冷卻計時器），
有傷害 / 治癒 / 增益 / 敵方減益效果，並顯示在戰鬥記錄中。

---

## 設計規格

### 移除：`SkillEffect` enum（被動加成）

```swift
// 刪除以下內容
enum SkillEffect {
    case atkBonus(Int)
    case defBonus(Int)
    case hpBonus(Int)
    case agiBonus(Int)
    case dexBonus(Int)
}
```

### 新增：`ActiveEffect` enum（5 種主動效果）

```swift
enum ActiveEffect {
    /// 對敵造成 heroAtk × multiplier 傷害
    case damage(multiplier: Double)

    /// 恢復英雄 heroMaxHp × multiplier HP
    case heal(multiplier: Double)

    /// 傷害 + 治癒組合（一個技能事件）
    case damageAndHeal(dmgMultiplier: Double, healMultiplier: Double)

    /// 下次英雄攻擊傷害 × (1 + bonus)（單次生效後重置）
    case heroAtkUp(bonus: Double)

    /// 下次敵方攻擊傷害 × (1 - reduction)（單次生效後重置）
    case enemyAtkDown(reduction: Double)
}
```

### 修改：`SkillDef` struct

```swift
struct SkillDef {
    let key:             String
    let classKey:        String
    let requiredLevel:   Int
    let name:            String
    let description:     String
    let cooldownSeconds: Int      // 冷卻時間（秒）
    let effect:          ActiveEffect

    // 靜態查詢
    static let all: [SkillDef] = [...]
    static func find(key: String) -> SkillDef? { ... }
    static func unlocked(classKey: String, atLevel: Int) -> [SkillDef] { ... }

    // UI 摘要（例："150% ATK 傷害 · CD 20s"）
    var effectSummary: String { ... }
}
```

### `effectSummary` 格式

| 效果類型 | 顯示範例 |
|---|---|
| `.damage(1.5)` | `150% ATK 傷害 · CD 20s` |
| `.heal(0.25)` | 恢復 25% HP · CD 40s |
| `.damageAndHeal(1.2, 0.1)` | `120% ATK 傷害 + 恢復 10% HP · CD 22s` |
| `.heroAtkUp(0.8)` | `下次攻擊 +80% 傷害 · CD 28s` |
| `.enemyAtkDown(0.4)` | `敵方下次攻擊 -40% · CD 35s` |

---

## 新技能設計（20 個，全主動）

### 劍士（Swordsman）— 爆發傷害型

| Lv | Key | 名稱 | 效果 | CD | `ActiveEffect` |
|---|---|---|---|---|---|
| 3 | `sw_heavy_slash` | 重斬擊 | 150% ATK 傷害 | 20s | `.damage(1.5)` |
| 6 | `sw_battle_cry` | 戰吼 | 下次攻擊 +80% 傷害 | 28s | `.heroAtkUp(0.8)` |
| 10 | `sw_whirlwind` | 旋風斬 | 200% ATK 傷害 | 28s | `.damage(2.0)` |
| 15 | `sw_intimidate` | 威嚇 | 下次敵方攻擊 -40% | 35s | `.enemyAtkDown(0.4)` |
| 20 | `sw_deathblow` | 必殺一擊 | 300% ATK 傷害 | 45s | `.damage(3.0)` |

### 弓手（Archer）— 速攻 + 敵方減益型

| Lv | Key | 名稱 | 效果 | CD | `ActiveEffect` |
|---|---|---|---|---|---|
| 3 | `ar_rapid_shot` | 速射 | 120% ATK 傷害 | 12s | `.damage(1.2)` |
| 6 | `ar_cripple` | 腱射 | 下次敵方攻擊 -50% | 22s | `.enemyAtkDown(0.5)` |
| 10 | `ar_barrage` | 連矢 | 180% ATK 傷害 | 22s | `.damage(1.8)` |
| 15 | `ar_eagle_shot` | 神鷹射 | 240% ATK 傷害 | 32s | `.damage(2.4)` |
| 20 | `ar_lethal_aim` | 致命狙擊 | 340% ATK 傷害 | 42s | `.damage(3.4)` |

### 法師（Mage）— 爆發 + 混合型

| Lv | Key | 名稱 | 效果 | CD | `ActiveEffect` |
|---|---|---|---|---|---|
| 3 | `mg_fireball` | 火球術 | 140% ATK 傷害 | 18s | `.damage(1.4)` |
| 6 | `mg_frost_nova` | 冰霜新星 | 120% ATK 傷害 + 下次敵方攻擊 -35% | 28s | 見備註 |
| 10 | `mg_arcane_blast` | 魔爆 | 210% ATK 傷害 | 30s | `.damage(2.1)` |
| 15 | `mg_mana_shield` | 魔盾恢復 | 恢復 15% 最大 HP | 35s | `.heal(0.15)` |
| 20 | `mg_meteor` | 隕星術 | 310% ATK 傷害 | 50s | `.damage(3.1)` |

> **備註（mg_frost_nova）：** 效果為「傷害 + 敵方減益」，目前 `ActiveEffect` 不直接支援此組合。
> 實作時選擇以下其中一種方式：
> a) 使用 `.damage(1.2)`，description 說明附帶減益，減益效果暫緩 T08 決定；
> b) 在 T08 新增 `case damageAndEnemyAtkDown(dmgMultiplier:reduction:)` 效果類型。
> T08 實作時確認。

### 聖騎士（Paladin）— 坦克 + 治癒型

| Lv | Key | 名稱 | 效果 | CD | `ActiveEffect` |
|---|---|---|---|---|---|
| 3 | `pl_holy_strike` | 聖光擊 | 120% ATK 傷害 + 恢復 10% HP | 22s | `.damageAndHeal(1.2, 0.1)` |
| 6 | `pl_divine_shield` | 神盾 | 下次敵方攻擊 -60% | 32s | `.enemyAtkDown(0.6)` |
| 10 | `pl_consecration` | 奉獻 | 160% ATK 傷害 + 恢復 12% HP | 34s | `.damageAndHeal(1.6, 0.12)` |
| 15 | `pl_holy_light` | 神聖之光 | 恢復 25% 最大 HP | 40s | `.heal(0.25)` |
| 20 | `pl_judgment` | 審判 | 280% ATK 傷害 | 55s | `.damage(2.8)` |

---

## 驗收標準

- [ ] `SkillEffect` enum 完全移除，無殘留
- [ ] `ActiveEffect` enum 包含 5 種 case，associated values 型別正確
- [ ] `SkillDef.cooldownSeconds` 欄位存在
- [ ] `SkillDef.effect: ActiveEffect` 欄位存在（取代舊 `effects: [SkillEffect]`）
- [ ] `effectSummary` 針對各效果類型回傳正確格式文字
- [ ] 全部 20 個技能靜態資料定義正確（key / classKey / requiredLevel / CD / effect）
- [ ] `xcodebuild` 通過（此步驟會有多處 compile error，需同步處理 T08 引用點）
