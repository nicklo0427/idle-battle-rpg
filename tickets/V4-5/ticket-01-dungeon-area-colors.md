# V4-5 Ticket 01：地下城區域差異化色調

**狀態：** 🔲 待實作

**依賴：** V4-3 T02 沉落王城靜態資料

---

## 目標

為各地下城區域套用差異化主題色，增強視覺辨識度。

---

## 修改檔案

`Views/AdventureView.swift`

---

## 各區域色調

| 區域 | key | 主題色 |
|---|---|---|
| 荒野邊境 | wildland | `.orange` |
| 廢棄礦坑 | mine | `.blue.opacity(0.8)` |
| 古代遺跡 | ruins | `.purple` |
| 沉落王城 | sunken_city | `.indigo` |

---

## 實作方式

在 `DungeonAreaDef` 或 `DungeonRegionDef` 新增 `themeColor: Color` 屬性（純計算，不存 SwiftData）：

```swift
struct DungeonAreaDef {
    // ... 現有欄位 ...
    var themeColor: Color {
        switch key {
        case "wildland":    return .orange
        case "mine":        return .blue.opacity(0.8)
        case "ruins":       return .purple
        case "sunken_city": return .indigo
        default:            return .gray
        }
    }
}
```

### 區域卡片套用

```swift
// 區域卡片背景
RoundedRectangle(cornerRadius: 12)
    .fill(area.themeColor.opacity(0.15))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(area.themeColor.opacity(0.4), lineWidth: 1)
    )

// 區域圖示
Image(systemName: area.icon)
    .foregroundStyle(area.themeColor)

// 區域名稱
Text(area.name)
    .foregroundStyle(area.themeColor)
```

### FloorDetailSheet 套用

```swift
// 樓層選中狀態 tint
.tint(area.themeColor)

// 進行中狀態 indicator
Circle()
    .fill(area.themeColor)
    .frame(width: 8, height: 8)
```

---

## 驗收標準

- [ ] 荒野邊境卡片呈橙色系
- [ ] 廢棄礦坑卡片呈藍灰色系
- [ ] 古代遺跡卡片呈紫色系
- [ ] 沉落王城卡片呈深藍色系
- [ ] 色調不影響文字可讀性（opacity 適當）
- [ ] FloorDetailSheet 內元素跟隨對應區域色調
