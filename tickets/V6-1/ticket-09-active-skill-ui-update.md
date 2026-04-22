# V6-1 Ticket 09：主動技能 UI 更新

**狀態：** ✅ 已完成
**版本：** V6-1（修訂）
**依賴：** T07、T08 完成
**修改檔案：**
- `IdleBattleRPG/Views/CharacterView.swift`
- `IdleBattleRPG/Views/ClassSelectionView.swift`
- `IdleBattleRPG/Views/AdventureView.swift`（可選）

---

## 背景

T07 改寫 `SkillDef` 後，UI 顯示需要對應調整：
- 技能 Tab 不再顯示「ATK +12」之類的屬性加成，改為主動效果描述 + 冷卻時間
- 職業選擇卡片預覽文字反映新的效果格式
- 出征前技能預覽補充冷卻資訊

---

## 1. CharacterView.swift — 技能 Tab

T05 實作的技能 Tab 主要透過 `effectSummary` 顯示效果文字，
T07 更新 `effectSummary` 後大部分顯示自動正確。

以下需確認或微調：

### 已裝備槽（配備技能 Section）

目前顯示：
```
⚡ 重斬擊
   ATK +12          ← 舊格式
```

T07 後自動改為：
```
⚡ 重斬擊
   150% ATK 傷害 · CD 20s   ← 新 effectSummary
```

確認版面沒有 truncation 問題（文字較長）。

### 已解鎖技能 Section

目前每列顯示：
```
⚡ 重斬擊  [Lv.3 capsule]
   ATK +12
   [配備] 按鈕
```

T07 後：
```
⚡ 重斬擊  [Lv.3 capsule]
   150% ATK 傷害 · CD 20s
   [配備] 按鈕
```

如果 `effectSummary` 文字太長，改為兩行顯示：
```
⚡ 重斬擊  [Lv.3 capsule]
   150% ATK 傷害
   CD 20s
```

### 尚未解鎖 Section

顯示格式不變（灰色 + 「需 Lv.X」），只確認 effectSummary 文字格式正確。

---

## 2. ClassSelectionView.swift — 職業卡片 Lv.3 技能預覽

目前職業卡片底部顯示：
```swift
Text("Lv.3：\(firstSkill.name)")
```

T07 後 `effectSummary` 包含效果描述，更新為：
```swift
Text("Lv.3 · \(firstSkill.name)")
    .font(.caption)
    .foregroundStyle(.secondary)
Text(firstSkill.effectSummary)
    .font(.caption2)
    .foregroundStyle(classDef.themeColor.opacity(0.8))
```

或合併為一行（若版面允許）：
```swift
Text("Lv.3：\(firstSkill.name)  \(firstSkill.effectSummary)")
```

---

## 3. AdventureView.swift — FloorDetailSheet 出征技能預覽（可選）

目前顯示：
```
⚡ 重斬擊・神聖之光
```

可選更新為：
```
⚡ 重斬擊（CD 20s）・神聖之光（CD 40s）
```

實作方式：
```swift
Text(equippedSkills.map { "\($0.name)（CD \($0.cooldownSeconds)s）" }.joined(separator: "・"))
```

此為可選優化，若版面過長可保留原有格式。

---

## 4. BattleLogSheet.swift — 不需修改

`.skill` 事件已有 `bolt.fill` 橙色圖示顯示，
主動技能觸發的 `.skill` 事件描述文字在 T08 中已定義，UI 自動顯示。

---

## 驗收標準

- [ ] 技能 Tab「配備技能」Section：裝備槽顯示技能名 + 主動效果描述（非舊的屬性加成）
- [ ] 技能 Tab「已解鎖技能」Section：顯示效果 + CD，文字無截斷
- [ ] 技能 Tab「尚未解鎖」Section：顯示效果（灰色）+ 需 Lv.X
- [ ] 職業選擇卡片：Lv.3 技能預覽顯示主動效果文字
- [ ] `xcodebuild` 通過，無 error
- [ ] 視覺確認：在 Simulator 中檢查各頁面顯示正確，無文字截斷
