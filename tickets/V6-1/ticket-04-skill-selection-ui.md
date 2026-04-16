# V6-1 Ticket 04：技能選擇 UI

**狀態：** 🔲 待實作
**版本：** V6-1
**依賴：** T01、T02、T03

---

## 目標

在角色頁新增「技能」Tab，讓玩家選擇出征使用的主動技能。

---

## 修改檔案

`IdleBattleRPG/Views/CharacterView.swift`

---

## UI 設計

### CharacterSegment 擴充

```swift
enum CharacterSegment: String, CaseIterable {
    case gear    = "裝備"
    case stats   = "屬性"
    case skills  = "技能"   // 新增
    case achieve = "成就"
}
```

### 技能 Tab 佈局

```
┌─────────────────────────────┐
│ 主動技能（出征時選一個）         │
├─────────────────────────────┤
│ [✓] 斬擊強化                 │
│     首場戰鬥 ATK ×1.5        │
│                             │
│ [ ] 鐵壁防禦                 │
│     出征全程 DEF +20         │
│                             │
│ [ ] 疾風步法                 │
│     出征全程 AGI +4          │
└─────────────────────────────┘
```

每個技能卡片：
- 選中：橙色邊框 + 勾選圖示
- 未選中：灰色邊框
- 點擊切換選中（radio 邏輯）
- 出征中：所有卡片 disabled（`isOnExpedition`）

### 程式碼結構

```swift
private func skillsSection(player: PlayerStateModel) -> some View {
    Section("主動技能（出征時選一個）") {
        ForEach(SkillDef.all, id: \.key) { skill in
            skillRow(skill: skill, player: player)
        }
    }
}

private func skillRow(skill: SkillDef, player: PlayerStateModel) -> some View {
    let isSelected = player.equippedSkillKey == skill.key
    return HStack {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isSelected ? .orange : .secondary)
        VStack(alignment: .leading, spacing: 2) {
            Text(skill.name).fontWeight(.medium)
            Text(skill.description).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
        guard !isOnExpedition else { return }
        player.equippedSkillKey = isSelected ? nil : skill.key
        try? context.save()
    }
    .disabled(isOnExpedition)
}
```

---

## 出征入口提示

`FloorDetailSheet`（出征確認畫面）新增目前選中技能的小 badge：

```swift
// 出征確認列最下方
if let skillKey = player.equippedSkillKey,
   let skill = SkillDef.find(key: skillKey) {
    HStack(spacing: 4) {
        Image(systemName: "bolt.fill").foregroundStyle(.orange)
        Text("技能：\(skill.name)").font(.caption).foregroundStyle(.secondary)
    }
}
```

---

## 驗收標準

- [ ] 角色頁出現「技能」Tab，位於「屬性」與「成就」之間
- [ ] 3 個技能卡片正確顯示，radio 邏輯正常
- [ ] 選中技能儲存至 SwiftData，重啟 App 後維持
- [ ] 出征中技能卡片 disabled
- [ ] FloorDetailSheet 顯示目前選中技能名稱
- [ ] 未選技能時 FloorDetailSheet 不顯示技能 badge
