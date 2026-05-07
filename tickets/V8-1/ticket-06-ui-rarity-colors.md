# V8-1 Ticket 06：UI 稀有度顏色顯示

**狀態：** ✅ 完成

**依賴：** T01（rare / epic enum case）

---

## 目標

在 View 層加入稀有度 → 顏色映射，讓稀有（紫）與史詩（金）裝備在 CraftSheet 和 CharacterView 中有視覺區分。EquipmentDef 保持純 Swift struct（不引入 SwiftUI）。

---

## 稀有度顏色規範

| rarity | displayColor | 備註 |
|--------|-------------|------|
| .common  | `.primary` | 無特殊標記 |
| .refined | `.blue` | 現有精良為藍色（確認後補上若無） |
| .rare    | `.purple` | 稀有紫 |
| .epic    | `Color(red: 1.0, green: 0.75, blue: 0.0)` | 史詩金 |

---

## 修改細節

### `Views/CraftSheet.swift`

#### 1. 在檔案頂層（非 struct 內）加入 extension

```swift
private extension EquipmentRarity {
    var displayColor: Color {
        switch self {
        case .common:  return .primary
        case .refined: return .blue
        case .rare:    return .purple
        case .epic:    return Color(red: 1.0, green: 0.75, blue: 0.0)
        }
    }
}
```

#### 2. 配方列加入稀有度 badge

在每個配方 row 的裝備名稱旁加入稀有度 label（只對 rare / epic 顯示）：

```swift
// 裝備名稱 + 稀有度 badge
HStack(spacing: 4) {
    Text(recipe.name)
        .font(.headline)
    if recipe.rarity == .rare || recipe.rarity == .epic {
        Text(recipe.rarity.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(recipe.rarity.displayColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(recipe.rarity.displayColor.opacity(0.12), in: Capsule())
    }
}
```

---

### `Views/CharacterView.swift`

在已裝備欄的裝備名稱加入稀有度顏色前景。找到裝備名稱顯示的 `Text(equip.name)` 並套用：

```swift
Text(equip.name)
    .foregroundStyle(equip.rarity.displayColor)
```

> 注意：須在 CharacterView.swift 或其使用的 extension 中也加入同樣的 `EquipmentRarity.displayColor` extension（或共用同一個位置）。建議將 extension 放在 `EquipmentDef.swift` 之外、CraftSheet.swift 之內，CharacterView 獨立再寫一次，避免跨 View 檔案 coupling。

---

## 修改檔案

- `Views/CraftSheet.swift`（extension + badge）
- `Views/CharacterView.swift`（裝備名稱顏色）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] CraftSheet 稀有配方名旁顯示紫色「稀有」膠囊 badge
- [ ] CraftSheet 史詩配方名旁顯示金色「史詩」膠囊 badge
- [ ] 普通/精良配方無 badge
- [ ] CharacterView 已裝備的稀有裝備名稱顯示紫色
- [ ] CharacterView 已裝備的史詩裝備名稱顯示金色
- [ ] 普通/精良裝備顏色不變（不受影響）
