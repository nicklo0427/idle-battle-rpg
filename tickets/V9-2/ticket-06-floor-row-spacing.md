# V9-2 Ticket 06：樓層列間距 & 圖示放大

**狀態：** 📋 規劃中
**改動檔案：** `Views/AdventureView.swift`（`floorRow`）

---

## 問題

展開區域後的樓層列 `.padding(.vertical, 2)` 太緊，
怪物 / Boss 圓形圖示只有 30pt，視覺上太小且擁擠。

---

## 改動細節

### 1. 怪物 / Boss 圖示放大

```swift
// 前
Circle().frame(width: 30, height: 30)
Image(...).frame(width: 26, height: 26)

// 後
Circle().frame(width: 40, height: 40)
Image(...).frame(width: 36, height: 36)
```

### 2. 樓層列垂直 padding 放大

```swift
// 前（floorRow label 末尾）
.padding(.vertical, 2)

// 後
.padding(.vertical, 10)
```

### 3. Divider leading 對齊新圖示寬度

```swift
// 前
Divider().padding(.leading, 50)

// 後（40pt circle + 10pt spacing + 12pt row leading padding）
Divider().padding(.leading, 62)
```

### 4. 樓層名稱字級微升

```swift
// 前
.font(.subheadline)

// 後（維持 subheadline，但 unlocked 時加 semibold weight）
.fontWeight(unlocked ? .semibold : .regular)
```

---

## 視覺目標

每個樓層列感覺像一個獨立的 List Row，而不是密集文字清單。
圓形圖示夠大，讓怪物 / Boss 臉清晰可見。

---

## 驗證

1. Build 通過，無新警告
2. 展開「金穗之野」看 4 個樓層，行間距明顯舒適
3. Boss 圖示 36pt 清晰，不裁切
4. Divider 對齊圖示右緣
