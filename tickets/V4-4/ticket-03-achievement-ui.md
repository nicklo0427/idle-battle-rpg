# V4-4 Ticket 03：CharacterView 成就 UI

**狀態：** ✅ 已完成

**依賴：** T01 AchievementDef、T02 AchievementService

---

## 目標

在角色頁新增「成就」Segment，顯示已解鎖（金色）與未解鎖（灰色隱藏）成就列表。

---

## 修改檔案

- `Views/CharacterView.swift`
- `ViewModels/CharacterViewModel.swift`

---

## CharacterViewModel 修改

新增成就資料：

```swift
var unlockedAchievementKeys: [String] {
    player?.unlockedAchievements ?? []
}

var achievementRows: [(def: AchievementDef, isUnlocked: Bool)] {
    AchievementDef.all.map { def in
        (def: def, isUnlocked: unlockedAchievementKeys.contains(def.key))
    }
}
```

---

## CharacterView 修改

### Segment 新增「成就」

```swift
Picker("", selection: $selectedSegment) {
    Text("屬性").tag(0)
    Text("背包").tag(1)
    Text("成就").tag(2)
}
.pickerStyle(.segmented)
```

### 成就列表（selectedSegment == 2）

```swift
List(viewModel.achievementRows, id: \.def.key) { row in
    HStack(spacing: 12) {
        Image(systemName: row.isUnlocked ? row.def.icon : "questionmark.circle")
            .font(.title2)
            .foregroundStyle(row.isUnlocked ? .yellow : .secondary)
            .frame(width: 36)

        VStack(alignment: .leading, spacing: 2) {
            Text(row.isUnlocked ? row.def.name : row.def.hiddenName)
                .font(.headline)
                .foregroundStyle(row.isUnlocked ? .primary : .secondary)
            if row.isUnlocked {
                Text(row.def.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("???")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }

        Spacer()

        if row.isUnlocked {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.yellow)
        }
    }
    .padding(.vertical, 4)
}
```

### 已解鎖數量標頭

```swift
Section {
    // 成就列表
} header: {
    Text("已解鎖 \(viewModel.unlockedAchievementKeys.count) / \(AchievementDef.all.count)")
        .font(.footnote)
}
```

---

## 驗收標準

- [ ] CharacterView 顯示「成就」Segment
- [ ] 已解鎖成就顯示金色圖示、名稱、說明
- [ ] 未解鎖成就顯示灰色問號、隱藏名稱、「???」說明
- [ ] 標頭顯示解鎖數量
- [ ] 解鎖新成就後重新整理 UI（ViewModel @Published 更新）
