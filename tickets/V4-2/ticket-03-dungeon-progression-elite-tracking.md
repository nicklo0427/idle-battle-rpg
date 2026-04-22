# V4-2 Ticket 03：DungeonProgressionModel 菁英進度追蹤

**狀態：** ✅ 已完成

**依賴：** T01 EliteDef

---

## 目標

修改 `DungeonProgressionModel` 新增菁英通關記錄，並修改樓層解鎖邏輯，改為「擊敗菁英解鎖下一層」。

---

## 修改檔案

- `Models/DungeonProgressionModel.swift`
- `Services/DungeonProgressionService.swift`

---

## DungeonProgressionModel 修改

新增欄位：

```swift
@Model class DungeonProgressionModel {
    // ... 現有欄位 ...
    var clearedElites: [String] = []    // 已通關菁英的 floorKey 陣列
}
```

---

## DungeonProgressionService 修改

### 新增方法

```swift
func markEliteCleared(floorKey: String) {
    guard let model = fetchOrCreate() else { return }
    if !model.clearedElites.contains(floorKey) {
        model.clearedElites.append(floorKey)
        try? context.save()
    }
}

func isEliteCleared(floorKey: String) -> Bool {
    fetchOrCreate()?.clearedElites.contains(floorKey) ?? false
}
```

### 修改 isFloorUnlocked 邏輯

```swift
func isFloorUnlocked(_ floorKey: String, in area: DungeonAreaDef) -> Bool {
    // 第一層永遠解鎖
    guard let index = area.floors.firstIndex(where: { $0.key == floorKey }),
          index > 0 else { return true }
    // 第 N 層 = 第 N-1 層菁英已清除
    let previousFloor = area.floors[index - 1]
    return isEliteCleared(floorKey: previousFloor.key)
}
```

> ⚠️ 原本 AFK 首通觸發解鎖的邏輯（`resultFirstClearedFloorKey`）**不再影響解鎖**，但欄位保留（用於玩家統計）。

---

## 驗收標準

- [ ] `clearedElites` 欄位正確持久化
- [ ] `markEliteCleared()` 不重複寫入
- [ ] `isFloorUnlocked()` 邏輯改為依菁英通關判斷
- [ ] 第一層每個區域仍預設解鎖
- [ ] `resultFirstClearedFloorKey` 欄位保留（不刪）
