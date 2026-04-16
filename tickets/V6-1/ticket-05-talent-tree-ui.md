# V6-1 Ticket 05：天賦樹 UI

**狀態：** 🔲 待實作
**版本：** V6-1
**依賴：** T01、T03

---

## 目標

在角色頁「技能」Tab 下方（同一頁面捲動），顯示三路線天賦樹。
天賦自動解鎖，玩家只需升等即可獲得，無需手動點擊。

---

## 修改檔案

`IdleBattleRPG/Views/CharacterView.swift`（或抽出 `TalentTreeView.swift`）

---

## UI 設計

### 天賦樹佈局（技能 Tab 下半部）

```
被動天賦（依等級自動解鎖）

攻擊路線          防禦路線          速攻路線
─────────────    ─────────────    ─────────────
[✓] 鋒芒初露     [✓] 堅盾初形     [✓] 輕步初學
    ATK +3 Lv.3      DEF +3 Lv.3      AGI +2 Lv.3
    |                |                |
[✓] 利刃磨礪     [✓] 厚甲鍛造     [✓] 銳眼訓練
    ATK +5 Lv.6      HP +15 Lv.6      DEX +2 Lv.6
    |                |                |
[ ] 斬鐵如泥     [ ] 鋼鐵意志     [ ] 迅影身法
    ATK +8 Lv.10     DEF +6 Lv.10     AGI +3 Lv.10
    （需 Lv.10）      （需 Lv.10）      （需 Lv.10）
    ...              ...              ...
```

- 已解鎖節點：橙色 `checkmark.circle.fill` + 亮色文字
- 未解鎖節點：灰色 `lock.fill` + 暗色文字 + 顯示「需 Lv.X」
- 節點之間有連接線（`Divider()` 或簡單 `Rectangle()`）

### 程式碼結構

```swift
private func talentTreeSection(player: PlayerStateModel) -> some View {
    let unlockedKeys = Set(TalentDef.unlocked(atLevel: player.heroLevel).map { $0.key })

    return Section("被動天賦（依等級自動解鎖）") {
        HStack(alignment: .top, spacing: 12) {
            talentColumn(path: .attack,  unlockedKeys: unlockedKeys)
            Divider()
            talentColumn(path: .defense, unlockedKeys: unlockedKeys)
            Divider()
            talentColumn(path: .speed,   unlockedKeys: unlockedKeys)
        }
    }
}

private func talentColumn(path: TalentPath, unlockedKeys: Set<String>) -> some View {
    let talents = TalentDef.all.filter { $0.path == path }
                              .sorted { $0.requiredLevel < $1.requiredLevel }
    return VStack(spacing: 0) {
        Text(path.displayName)
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(path.themeColor)
            .padding(.bottom, 6)
        ForEach(talents, id: \.key) { talent in
            talentNode(talent: talent, isUnlocked: unlockedKeys.contains(talent.key))
            if talent.key != talents.last?.key {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 10)
            }
        }
    }
}

private func talentNode(talent: TalentDef, isUnlocked: Bool) -> some View {
    VStack(spacing: 2) {
        Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
            .foregroundStyle(isUnlocked ? talent.path.themeColor : .secondary)
            .font(.caption)
        Text(talent.name)
            .font(.caption2)
            .fontWeight(isUnlocked ? .semibold : .regular)
            .foregroundStyle(isUnlocked ? .primary : .secondary)
        Text(talent.description)
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
        if !isUnlocked {
            Text("Lv.\(talent.requiredLevel)")
                .font(.system(size: 9))
                .foregroundStyle(.orange)
        }
    }
    .padding(.vertical, 4)
}
```

### TalentPath 擴充

```swift
extension TalentPath {
    var displayName: String {
        switch self {
        case .attack:  return "攻擊"
        case .defense: return "防禦"
        case .speed:   return "速攻"
        }
    }
    var themeColor: Color {
        switch self {
        case .attack:  return .red
        case .defense: return .blue
        case .speed:   return .green
        }
    }
}
```

---

## 天賦總加成摘要

天賦樹頂端顯示目前已解鎖天賦的總加成：

```swift
// 例如 Lv.10：ATK +16、DEF +9、HP +15、AGI +5、DEX +2
let summary = TalentDef.unlocked(atLevel: player.heroLevel)
    .reduce(into: [...]) { ... }
Text("天賦加成：ATK +\(summary.atk) DEF +\(summary.def) ...")
    .font(.caption).foregroundStyle(.secondary)
```

---

## 驗收標準

- [ ] 三欄天賦樹正確顯示，每欄 5 個節點
- [ ] Lv.3 解鎖各路線第 1 個節點（橙色勾選）
- [ ] Lv.6 解鎖各路線前 2 個
- [ ] 未解鎖節點顯示「Lv.X」需求
- [ ] 天賦總加成摘要顯示正確
- [ ] 升等後節點即時變為已解鎖（@Query 自動更新）
