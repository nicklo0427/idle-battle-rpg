# V10-2 T03 — 職業選擇加即時戰力預覽

## 狀態：✅ 已完成

## 目標

在職業選擇卡片（ClassSelectionView）加入戰力影響預覽，讓玩家在選擇前有數字依據，不再純靠背景故事決定。

## 設計

戰力公式：`ATK × 2 + DEF × 1.5 + HP × 1`（AGI / DEX 不計入基礎戰力）

各職業預估戰力加成：
| 職業 | 加成 | 預估戰力 +N |
|------|------|------------|
| 劍士 | ATK +5 | +10 |
| 弓手 | AGI +3, DEX +2 | 顯示「敏捷 / 暴擊率提升」|
| 法師 | ATK +3, AGI +2 | +6 |
| 聖騎士 | DEF +4, HP +15 | +21 |

卡片在 `bonusSummary` 下方加一行：
```
⚡ 戰力 +N   或   ⚡ 敏捷 / 暴擊率提升
```

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `StaticData/ClassDef.swift` | 新增 `estimatedPowerBonus: Int`（`Int(ATK*2.0 + DEF*1.5) + HP`）✅ |
| `Views/ClassSelectionView.swift` | `classCard(_:)` 在加成 Capsule 下方加戰力預覽 HStack ✅ |

## 驗收

1. 職業選擇畫面，每張職業卡片顯示「⚡ 戰力 +N」
2. 弓手卡片顯示「⚡ 敏捷 / 暴擊率提升」（因 AGI/DEX 不進戰力公式）
3. 數字計算正確：劍士 +10，法師 +6，聖騎士 +21
