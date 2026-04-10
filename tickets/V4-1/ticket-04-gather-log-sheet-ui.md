# V4-1 Ticket 04：GatherLogSheet UI + GathererDetailSheet 入口

**狀態：** ✅ 完成

**依賴：** T02 GatherLogGenerator

---

## 目標

建立 `GatherLogSheet` 並在 `GathererDetailSheet` 進行中狀態新增「查看過程」入口。

---

## 新建檔案

`Views/GatherLogSheet.swift`

## 修改檔案

`Views/GathererDetailSheet.swift`

---

## GatherLogSheet 結構

```swift
struct GatherLogSheet: View {
    let events: [GatherEvent]
    let locationName: String
}
```

### UI 佈局

```
NavigationStack {
    List {
        ForEach(displayedEvents) { event in
            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
    .navigationTitle("採集過程：\(locationName)")
    .navigationBarTitleDisplayMode(.inline)
}
.presentationDetents([.medium, .large])
```

### 文字播放

- `@State private var displayedCount = 0`
- `Timer` 每 0.4 秒追加一個 event（採集節奏較慢）
- `.onDisappear` 停止 Timer

---

## GathererDetailSheet 修改

在進行中狀態區塊新增：

```swift
Button("查看過程") {
    let idx = GatherLogGenerator.currentCycleIndex(for: task, location: location)
    gatherEvents = GatherLogGenerator.generate(task: task, location: location, fromCycleIndex: idx)
    showGatherLog = true
}
.buttonStyle(.bordered)
```

- `.sheet(isPresented: $showGatherLog) { GatherLogSheet(events: gatherEvents, locationName: location.name) }`
- 只在任務進行中時顯示此按鈕

---

## 驗收標準

- [ ] GatherLogSheet 顯示採集週期描述
- [ ] 文字以每 0.4 秒逐行播放
- [ ] GathererDetailSheet 進行中時出現「查看過程」按鈕
- [ ] 點擊後正確開啟 GatherLogSheet
