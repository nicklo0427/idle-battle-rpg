# V9-2 Ticket 07：Region 卡片上下間距 & 樓層清單內距

**狀態：** 📋 規劃中
**改動檔案：** `Views/AdventureView.swift`（`regionListSection`、`regionBannerCard`）

---

## 問題

區域卡片之間 `listRowInsets` top/bottom 只有 6pt，
Banner 圖片與下方樓層清單之間沒有分隔感，整體偏擠。

---

## 改動細節

### 1. List Row 上下間距放大

```swift
// 前
.listRowInsets(.init(top: 6, leading: 12, bottom: 6, trailing: 12))

// 後
.listRowInsets(.init(top: 10, leading: 12, bottom: 10, trailing: 12))
```

### 2. 樓層清單容器加入內距

展開後的 `VStack(spacing: 0)` 樓層清單，
頂端加 4pt padding，讓 Banner 底角與第一列有點呼吸空間。

```swift
// 前
VStack(spacing: 0) {
    ForEach(region.floors) { floor in
        floorRow(...)
        ...
    }
}
.background(...)
.clipShape(...)

// 後
VStack(spacing: 0) {
    ForEach(region.floors) { floor in
        floorRow(...)
        ...
    }
}
.padding(.top, 4)         // ← 新增
.background(...)
.clipShape(...)
```

### 3. Banner 高度微調

Banner 目前 130pt，樓層圖示放大後視覺重量增加，
把 Banner 高度提高到 150pt，讓比例更協調。

```swift
// 前
.frame(height: 130)

// 後
.frame(height: 150)
```

### 4. 鎖定區域文字層級調整

鎖定區域右側目前是 `caption2`，在灰化背景上不夠清晰。
改為 `caption` 並加上半透明膠囊背景，提升可讀性。

```swift
// 前
Label(unlockCaption, systemImage: "lock.fill")
    .font(.caption2)
    .foregroundStyle(.white.opacity(0.9))

// 後
Label(unlockCaption, systemImage: "lock.fill")
    .font(.caption2)
    .foregroundStyle(.white)
    .padding(.horizontal, 8).padding(.vertical, 4)
    .background(.black.opacity(0.35))
    .clipShape(Capsule())
```

---

## 視覺目標

- 區域卡片彼此之間有清楚的間隔感
- Banner 與樓層清單之間有微小呼吸空間
- 鎖定狀態文字在灰化背景上清晰可讀

---

## 驗證

1. Build 通過
2. 三個區域卡片之間間距明顯，不擁擠
3. 展開 Banner 下方第一列不緊貼 Banner 底邊
4. 鎖定區域（血色曠野 / 烈焰沙海）的 Lock label 清晰可見
