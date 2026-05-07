# V8-3 Ticket 04：樓層個人最佳記錄（Personal Best per Floor）

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

記錄每個地下城樓層的個人最佳戰績（勝場數 + 金幣），在 FloorDetailSheet 顯示。非持久化更新（SwiftData 輕量遷移，設預設值無需版本號）。

---

## 修改細節

### `Models/DungeonProgressionModel.swift` — 新增欄位

```swift
var floorBestRecordsJSON: String = "{}"
```

SwiftData 輕量遷移相容：預設值 `"{}"` 代表空字典，舊存檔不受影響。

### `Services/DungeonProgressionService.swift` — 新增結構與方法

```swift
struct FloorBestRecord: Codable {
    var wins: Int
    var gold: Int
}

func updateBest(floorKey: String, wins: Int, gold: Int)
func getBest(floorKey: String) -> FloorBestRecord?
private func decodeBests(_ json: String?) -> [String: FloorBestRecord]
private func encodeBests(_ dict: [String: FloorBestRecord]) -> String
```

`updateBest` 更新規則：勝場數更高時覆蓋；勝場相同但金幣更多時覆蓋；否則不更新。

### `Views/DungeonBattleSheet.swift` — 在 `finalizeBattle()` 呼叫

```swift
appState.progressionService.updateBest(
    floorKey: floor.key,
    wins: result.battlesWon,
    gold: result.gold
)
```

### `Views/AdventureView.swift` — FloorDetailSheet 顯示

在 `floorInfoSection` 新增最佳記錄列：

```swift
if let best = appState.progressionService.getBest(floorKey: floor.key) {
    Label("最佳：\(best.wins) 勝 / 💰\(best.gold)", systemImage: "trophy.fill")
        .font(.caption)
        .foregroundStyle(.yellow)
}
```

有記錄才顯示，無記錄時不佔空間。

---

## 修改檔案

- `Models/DungeonProgressionModel.swift`（新增 `floorBestRecordsJSON`）
- `Services/DungeonProgressionService.swift`（`FloorBestRecord` + CRUD 方法）
- `Views/DungeonBattleSheet.swift`（`finalizeBattle()` 呼叫 `updateBest`）
- `Views/AdventureView.swift`（FloorDetailSheet 顯示最佳記錄）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 第一次跑某層：FloorDetailSheet 沒有最佳記錄顯示
- [ ] 完成一次後：FloorDetailSheet 顯示「🏆 最佳：X 勝 / 💰Y」
- [ ] 更高勝場覆蓋舊記錄，相同勝場但更多金幣覆蓋
- [ ] 較差成績不覆蓋既有最佳記錄
- [ ] 舊存檔（無 `floorBestRecordsJSON` 欄位）正常啟動，不 crash
