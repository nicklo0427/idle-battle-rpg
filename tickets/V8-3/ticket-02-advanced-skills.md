# V8-3 Ticket 02：英雄進階技能（各職業 Lv23 + Lv28，共 8 個）

**狀態：** ✅ 完成

**依賴：** T01（需 heroMaxLevel = 30 才能出現 Lv23/28 技能）

---

## 目標

每個職業在高等級解鎖 2 個全新主動技能，強化後期冒險的戰鬥深度。全部使用現有 `ActiveEffect` 枚舉，BattleLogGenerator 無需額外修改。`autoEquipNewSkills` 機制已自動裝備，無需額外處理。

---

## 新增技能

| 職業 | key | 等級 | 名稱 | CD | effect |
|------|-----|------|------|----|--------|
| 劍士 | `sw_dragon_slayer` | 23 | 屠龍者 | 50s | `.damage(multiplier: 3.2)` |
| 劍士 | `sw_judgment_falls` | 28 | 審判降臨 | 60s | `.damageAndWeaken(4.0, -40%, 2t)` |
| 弓手 | `ar_piercing_shot` | 23 | 穿透射擊 | 48s | `.damageAndBurn(2.8, dpt:15, 3t)` |
| 弓手 | `ar_soul_destroyer` | 28 | 滅魂箭 | 58s | `.damage(multiplier: 4.0)` |
| 法師 | `mg_frost_flame` | 23 | 冰炎融合 | 45s | `.damageAndPoison(2.6, dptPerStack:18)` |
| 法師 | `mg_dimensional_collapse` | 28 | 次元崩裂 | 60s | `.stunAndDamage(3.8, 2t)` |
| 聖騎士 | `pl_holy_burst` | 23 | 神聖爆發 | 50s | `.damageAndHeal(2.8, 20%)` |
| 聖騎士 | `pl_celestial_judgment` | 28 | 天啟審判 | 60s | `.damageAndEnemyAtkDown(3.5, -50%)` |

---

## 修改細節

### `StaticData/SkillDef.swift`

各職業的 extension 區塊末尾加入 2 個新 `static let`，並將全部 8 個 key 加入 `all` 陣列。

實際 `ActiveEffect` 參數名稱：
- `.damage(multiplier:)`
- `.damageAndWeaken(dmgMultiplier:, reduction:, duration:)`
- `.damageAndBurn(dmgMultiplier:, dpt:, duration:)`
- `.damageAndPoison(dmgMultiplier:, dptPerStack:)`
- `.stunAndDamage(dmgMultiplier:, stunDuration:)`
- `.damageAndHeal(dmgMultiplier:, healMultiplier:)`（healMultiplier = 0.20 = 20% MaxHP）
- `.damageAndEnemyAtkDown(dmgMultiplier:, reduction:)`

---

## 修改檔案

- `StaticData/SkillDef.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] Lv23 角色在技能頁可見新技能（已可用狀態）
- [ ] Lv22 角色看不到 Lv23 技能（尚未解鎖）
- [ ] 戰鬥記錄中可看到新技能觸發事件
- [ ] 各職業 Lv28 技能 classKey 正確對應（不會混到其他職業）
