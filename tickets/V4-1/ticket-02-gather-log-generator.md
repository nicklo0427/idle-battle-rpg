# V4-1 Ticket 02：GatherLogGenerator（純計算層）

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

建立純計算層 `GatherLogGenerator`，生成每個採集週期的探索文字陣列，供 V4-1 T04 GatherLogSheet 使用。

---

## 新建檔案

`Services/GatherLogGenerator.swift`

---

## 輸入

```swift
static func generate(
    task: TaskModel,
    location: GatherLocationDef,
    fromCycleIndex: Int
) -> [GatherEvent]
```

---

## 輸出

`[GatherEvent]`，每個 event 包含：

```swift
struct GatherEvent {
    let cycleIndex: Int
    let description: String    // 完整採集文字（多行合併或單行）
}
```

---

## 輔助方法

```swift
static func currentCycleIndex(for task: TaskModel, location: GatherLocationDef) -> Int
```

計算方式：
```swift
let elapsed = Date.now.timeIntervalSince(task.startedAt)
let totalDuration = task.endsAt.timeIntervalSince(task.startedAt)
let cycleSeconds = Double(location.shortestDuration)  // 900s = 15min
let totalCycles = Int(totalDuration / cycleSeconds)
return min(Int(elapsed / cycleSeconds), max(0, totalCycles - 1))
```

---

## 事件描述模板（中文）

每個週期生成 3–4 行描述，合併為單一 `description`：

| 步驟 | 模板（以森林為例）|
|---|---|
| 進入 | `"[週期 \(n+1)] 進入 \(locationName)…"` |
| 搜索 | 從候選描述隨機選：`"發現隱蔽的採集點"` / `"深入搜索區域"` / `"循著足跡前行"` |
| 採集結果 | `"採集到 \(amount) \(materialName)"` 或 `"此處收穫不多"` |

地點候選搜索描述（各地點各 3 條）：

**森林：**
- `"發現一片茂密的硬木林"`
- `"深入幽靜的林間小道"`
- `"沿著古老樹根蜿蜒前行"`

**礦坑：**
- `"找到一處富含礦脈的岩層"`
- `"深入狹窄的礦道"`
- `"敲擊岩壁，尋找礦石縫隙"`

---

## 實作細節

- RNG seed 公式：`seed = UInt64(task.startedAt.timeIntervalSinceReferenceDate) ^ UInt64(bitPattern: task.id.hashValue)`
- 每個週期用 `seed XOR cycleIndex` 作為子 seed
- 結果（素材數量）用相同 RNG 確保與實際結算一致
- **純計算，不引入 SwiftData**

---

## 驗收標準

- [ ] `GatherLogGenerator.generate()` 回傳 `[GatherEvent]`
- [ ] 相同輸入永遠回傳相同結果
- [ ] `currentCycleIndex()` 回傳正確當前週期索引
- [ ] 不引入任何 `import SwiftData`
