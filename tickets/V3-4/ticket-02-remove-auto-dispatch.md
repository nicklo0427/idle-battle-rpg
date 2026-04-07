# V3-4 Ticket 02：移除連續出征功能

**狀態：** ✅ 完成

**依賴：** 無（反向刪除 V3-2 所有變更）

---

## 目標

完整移除連續出征功能，不保留任何殘留程式碼或欄位。

---

## 修改一：PlayerStateModel

**檔案：** `IdleBattleRPG/Models/PlayerStateModel.swift`

刪除欄位：
```swift
// 刪除整個 MARK 區塊
var autoDispatchEnabled: Bool = false
var autoDispatchFloorKey: String? = nil
var autoDispatchDuration: Int = 900
```

刪除計算屬性：
```swift
// 刪除
var autoDispatchFloor: DungeonFloorDef? {
    guard let key = autoDispatchFloorKey else { return nil }
    return DungeonFloorDef.find(key: key)
}
```

> SwiftData 移除欄位會在下次啟動時自動輕量 migration（刪除對應 column），無需手動處理。

---

## 修改二：AppState

**檔案：** `IdleBattleRPG/AppState.swift`

1. 刪除 `private let taskCreationService: TaskCreationService`
2. 刪除 `init` 中的 `self.taskCreationService = TaskCreationService(context: context)`
3. 刪除 `claimAllCompleted()` 末尾的 `tryAutoDispatch()` 呼叫
4. 刪除 `tryAutoDispatch()` 整個私有方法

---

## 修改三：AdventureView

**檔案：** `IdleBattleRPG/Views/AdventureView.swift`

### 出征中 Banner（activeBannerSection）

刪除 Banner VStack 內 ProgressView 下方加入的全部連續出征 UI：
```swift
// 刪除以下全部
Divider()
    .padding(.vertical, 4)

HStack {
    Text("連續出征") ...
    Toggle(...) ...
}

if let p = players.first, p.autoDispatchEnabled, let floor = p.autoDispatchFloor {
    Text("🔄 結算後自動前往：...") ...
}
```

### floorRow contextMenu

刪除 `.contextMenu { ... }` 整個修飾符（含內容）。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/PlayerStateModel.swift` | ✏️ 刪除 3 個欄位 + 1 個計算屬性 |
| `AppState.swift` | ✏️ 刪除 taskCreationService + tryAutoDispatch |
| `Views/AdventureView.swift` | ✏️ 刪除 Banner 連續出征 UI + floorRow contextMenu |

---

## 驗收標準

- [ ] Build 無錯誤、無 warning（無殘留引用）
- [ ] 出征中 Banner 不再有 Toggle 或「🔄」文字
- [ ] 長按樓層 row 無任何 contextMenu
- [ ] `claimAllCompleted()` 收下後不自動建立新任務
- [ ] App 重啟無 SwiftData migration crash
