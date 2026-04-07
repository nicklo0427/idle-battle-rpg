# V3-2 Ticket 01：AutoDispatch 設定欄位

**狀態：** ✅ 完成

**依賴：** 無（獨立）

---

## 目標

PlayerStateModel 新增「自動連續出征」設定欄位，讓玩家的選擇在 App 重啟後保留。

---

## 修改檔案

`IdleBattleRPG/Models/PlayerStateModel.swift`

### 新增欄位

```swift
// MARK: - 自動連續出征
var autoDispatchEnabled: Bool = false
var autoDispatchFloorKey: String? = nil   // 目標樓層 key（nil = 未設定）
var autoDispatchDuration: Int = 900       // 出征時長（秒），預設 15 分鐘（900秒）
```

### 新增便利計算屬性

```swift
/// 目前設定的自動出征樓層定義；nil = 未設定或 key 已失效
var autoDispatchFloor: DungeonFloorDef? {
    guard let key = autoDispatchFloorKey else { return nil }
    return DungeonFloorDef.find(key: key)
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/PlayerStateModel.swift` | ✏️ 修改（新增 3 個欄位 + 便利屬性） |

---

## 驗收標準

- [ ] 3 個欄位存在，初始值正確（false / nil / 900）
- [ ] `autoDispatchFloor` 計算屬性可正確查詢 DungeonFloorDef
- [ ] SwiftData migration 無 crash
- [ ] Build 無錯誤
