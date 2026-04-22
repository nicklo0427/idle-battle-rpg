# V6-1 Ticket 05：角色頁技能 Tab

**狀態：** ✅ 已完成
**版本：** V6-1 Phase 1
**依賴：** T01, T02, T03

---

## 目標

在角色頁新增「技能」Tab，讓玩家查看職業資訊、管理技能裝備槽（最多 4 個），並在出征確認畫面顯示已配備技能。

---

## 修改檔案

### `Views/CharacterView.swift`

#### 1. 新增 `.skills` Segment

```swift
private enum CharacterSegment: String, CaseIterable {
    case gear        = "裝備"
    case backpack    = "背包"
    case skills      = "技能"    // 新增，位於 backpack 後
    case achievement = "成就"
}
```

#### 2. 裝備 Tab 頂部英雄資訊區塊加入職業 badge

```swift
if let classDef = ClassDef.find(key: player.classKey) {
    HStack(spacing: 4) {
        Image(systemName: classDef.iconName)
            .font(.caption2)
        Text(classDef.name)
            .font(.caption2)
            .fontWeight(.semibold)
    }
    .foregroundStyle(classDef.themeColor)
    .padding(.horizontal, 8).padding(.vertical, 3)
    .background(classDef.themeColor.opacity(0.12))
    .clipShape(Capsule())
}
```

#### 3. 技能 Tab 佈局

```
┌ Section "配備技能"（出征時生效） ────────────────┐
│ 槽 1  [圖示] 斬擊強化    ATK +12  [移除]        │
│ 槽 2  [圖示] 防禦姿態    DEF +10  [移除]        │
│ 槽 3  ＋ 空槽（點擊已解鎖技能來配備）              │
│ 槽 4  ＋ 空槽                                  │
└────────────────────────────────────────────────┘
┌ Section "已解鎖技能" ───────────────────────────┐
│ [已配] 斬擊強化   ATK +12   Lv.3               │
│ [已配] 防禦姿態   DEF +10   Lv.6               │
│ [配備] 戰吼       ATK +20   Lv.10              │  ← 已解鎖但未配備
└────────────────────────────────────────────────┘
┌ Section "尚未解鎖" ─────────────────────────────┐
│ (灰色) 猛擊       ATK +30  需 Lv.15            │
│ (灰色) 無雙斬     ATK +45  需 Lv.20            │
└────────────────────────────────────────────────┘
```

各狀態 Row 邏輯：
- **已配備**：橙色圖示 + 技能名稱 + 效果加成 + [移除] 按鈕
- **已解鎖未配備**：正常顯示 + [配備] 按鈕（槽已滿 4 個時 disabled + 提示「槽已滿」）
- **未解鎖**：灰色顯示 + 「需 Lv.X」說明文字，無按鈕

效果加成文字輔助函式（顯示所有非零效果，以空格隔開）：
```swift
private func effectsSummary(for skill: SkillDef) -> String {
    skill.effects.map { effect in
        switch effect {
        case .atkBonus(let v): return "ATK +\(v)"
        case .defBonus(let v): return "DEF +\(v)"
        case .hpBonus(let v):  return "HP +\(v)"
        case .agiBonus(let v): return "AGI +\(v)"
        case .dexBonus(let v): return "DEX +\(v)"
        }
    }.joined(separator: "  ")
}
```

#### 4. 出征中 disabled 狀態

```swift
private var isOnExpedition: Bool {
    tasks.contains { $0.kind == .dungeon && $0.status == .inProgress }
}
// 技能 Tab 所有 [配備] / [移除] 按鈕加 .disabled(isOnExpedition)
// 出征中 Tab 頂部顯示說明文字：「出征中無法更換技能」
```

#### 5. 配備 / 移除邏輯

```swift
// 配備技能
func equipSkill(_ skillKey: String) {
    guard player.equippedSkillKeys.count < 4,
          !player.equippedSkillKeys.contains(skillKey) else { return }
    player.equippedSkillKeys.append(skillKey)
    try? context.save()
}

// 移除技能
func removeSkill(_ skillKey: String) {
    player.equippedSkillKeys.removeAll { $0 == skillKey }
    try? context.save()
}
```

---

### `Views/AdventureView.swift`

FloorDetailSheet 出發按鈕下方顯示已配備技能清單：

```swift
let skills = player.equippedSkillKeys.compactMap { SkillDef.find(key: $0) }
if !skills.isEmpty {
    HStack(spacing: 4) {
        Image(systemName: "bolt.fill")
            .foregroundStyle(.orange)
            .font(.caption)
        Text(skills.map { $0.name }.joined(separator: "、"))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

---

## 設計決策

| 決策 | 說明 |
|---|---|
| 最多 4 槽 | 與裝備欄（3 格）相當，策略選擇空間適中 |
| 出征中鎖定 | 避免玩家在結算前修改技能影響確定性 RNG |
| 橙色已配備標示 | 與任務進行中圖示用色一致 |
| 效果以字串顯示 | 簡潔清晰，多效果技能也能完整呈現 |

---

## 驗收標準

- [ ] 角色頁出現「技能」Tab（位於「背包」後）
- [ ] 職業 badge 顯示在裝備頁英雄資訊區（圖示 + 名稱 + 主題色）
- [ ] 技能 Tab 顯示 4 個槽位（已配備 / 空槽正確呈現）
- [ ] Lv.3 解鎖第 1 個技能後可配備（橙色圖示）
- [ ] 點擊 [配備] 正確新增至 `equippedSkillKeys` 並存入 SwiftData
- [ ] 點擊 [移除] 正確從 `equippedSkillKeys` 移除並存入 SwiftData
- [ ] 槽滿（4 個）時 [配備] 按鈕 disabled
- [ ] 出征中所有配備 / 移除操作 disabled，並顯示提示文字
- [ ] FloorDetailSheet 出發按鈕下方顯示已配備技能名稱
- [ ] Build 通過
