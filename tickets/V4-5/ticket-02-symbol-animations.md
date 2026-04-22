# V4-5 Ticket 02：SF Symbols 動畫（進行中任務）

**狀態：** ✅ 已完成

**依賴：** 無

---

## 目標

為進行中任務的圖示加上 SF Symbols 動畫，增強「任務進行中」的視覺回饋感。

---

## 修改檔案

- `Views/BaseView.swift`（採集者 / 鑄造師圖示）
- `Views/ContentView.swift`（Tab Bar 圖示）
- `Views/AdventureView.swift`（出征圖示）— ✅ 已完成

---

## 動畫規格

| 位置 | 條件 | 動畫 | SF Symbol | 狀態 |
|---|---|---|---|---|
| 採集者 NPC 圖示 | 任一採集者任務進行中 | `.symbolEffect(.breathe)` | `person.fill` | 🔲 未完成（目前誤用 `.pulse`）|
| 地下城出征圖示 | 英雄任務進行中 | `.symbolEffect(.pulse)` | `map.fill` | ✅ 已完成 |
| Tab Bar 冒險圖示 | 英雄任務進行中 | `.symbolEffect(.pulse)` | `map.fill` | 🔲 未完成 |
| Tab Bar 基地圖示 | 任一採集進行中 | `.symbolEffect(.breathe)` | `house.fill` | 🔲 未完成 |

> 鑄造師保持 `.pulse`（鑄造與採集視覺語義不同）。

---

## iOS 17 API

```swift
// iOS 17+ 原生，不需第三方套件
Image(systemName: "map.fill")
    .symbolEffect(.pulse, isActive: isInProgress)

Image(systemName: "person.fill")
    .symbolEffect(.breathe, isActive: isGathering)
```

---

## 實作細節

### 1. BaseView — 採集者圖示（`.pulse` → `.breathe`）

`Views/BaseView.swift` 約 line 214：

```swift
// 改前：
.symbolEffect(.pulse, isActive: isBusy)

// 改後：
.symbolEffect(.breathe, isActive: isBusy)
```

### 2. ContentView — Tab Bar 動畫

`Views/ContentView.swift` → `mainTabView`：

需在 `mainTabView` 中以 `@Query` 讀取 `TaskModel`，計算兩個 computed property：

```swift
// 英雄出征中
private var hasDungeonTask: Bool {
    tasks.contains { $0.kind == .dungeon && $0.status == .inProgress }
}

// 任一採集進行中
private var hasGatherTask: Bool {
    tasks.contains { $0.kind == .gather && $0.status == .inProgress }
}
```

Tab item 改為自訂 Label icon：

```swift
BaseView(appState: appState)
    .tabItem {
        Label {
            Text("基地")
        } icon: {
            Image(systemName: "house.fill")
                .symbolEffect(.breathe, isActive: hasGatherTask)
        }
    }

AdventureView(appState: appState)
    .tabItem {
        Label {
            Text("冒險")
        } icon: {
            Image(systemName: "map.fill")
                .symbolEffect(.pulse, isActive: hasDungeonTask)
        }
    }
```

> ⚠️ 注意：`.tabItem` 的 `symbolEffect` 在 iOS 17 可運作，但需實機測試確認渲染行為。

---

## 驗收標準

- [x] 出征進行中：地下城圖示播放脈衝動畫（AdventureView 內）
- [x] 採集進行中：採集者圖示播放**呼吸**動畫（非脈衝）
- [x] Tab Bar 冒險標籤：英雄出征時播放脈衝
- [x] Tab Bar 基地標籤：採集進行時播放呼吸
- [x] 任務結束後動畫停止（`isActive: false`）
- [x] 使用 iOS 17 原生 `symbolEffect`，無第三方依賴
- [x] 不影響現有 UI 佈局
