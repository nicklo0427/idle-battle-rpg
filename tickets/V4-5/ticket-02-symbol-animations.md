# V4-5 Ticket 02：SF Symbols 動畫（進行中任務）

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

為進行中任務的圖示加上 SF Symbols 動畫，增強「任務進行中」的視覺回饋感。

---

## 修改檔案

- `Views/BaseView.swift`（Tab Bar 圖示）
- `Views/AdventureView.swift`（出征圖示）
- `Views/GatherView.swift` 或 NPC 列表（採集圖示）

---

## 動畫規格

| 位置 | 條件 | 動畫 | SF Symbol |
|---|---|---|---|
| 採集者 NPC 圖示 | 任一採集者任務進行中 | `.symbolEffect(.breathe)` | `person.fill` |
| 地下城出征圖示 | 英雄任務進行中 | `.symbolEffect(.pulse)` | `map.fill` / `bolt.fill` |
| Tab Bar 地圖圖示 | 英雄任務進行中 | `.symbolEffect(.pulse)` | `map.fill` |
| Tab Bar 採集圖示 | 任一採集進行中 | `.symbolEffect(.breathe)` | `person.2.fill` |

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

## 實作位置

### AdventureView — 出征進行中

```swift
// 樓層卡片或進行中 banner 的圖示
Image(systemName: "bolt.fill")
    .symbolEffect(.pulse, isActive: task?.status == .inProgress)
```

### NPC 列表 — 採集進行中

```swift
// 每個採集者行的圖示
Image(systemName: "figure.walk")
    .symbolEffect(.breathe, isActive: gathererTask?.status == .inProgress)
```

### BaseView Tab Bar — 狀態反映

```swift
// Tab label
Label {
    Text("地下城")
} icon: {
    Image(systemName: "map.fill")
        .symbolEffect(.pulse, isActive: appState.hasDungeonTaskInProgress)
}
```

`appState.hasDungeonTaskInProgress` 為 computed property，查詢是否有 `.dungeon` + `.inProgress` 任務。

---

## 驗收標準

- [ ] 採集進行中：採集者圖示播放呼吸動畫
- [ ] 出征進行中：地下城圖示播放脈衝動畫
- [ ] 任務結束後動畫停止（`isActive: false`）
- [ ] 使用 iOS 17 原生 `symbolEffect`，無第三方依賴
- [ ] 不影響現有 UI 佈局
