# V6-1 Ticket 02：資料模型擴充

**狀態：** ✅ 已完成
**版本：** V6-1 Phase 1
**依賴：** T01

---

## 目標

擴充 `PlayerStateModel` 與 `TaskModel`，加入職業選擇與技能裝備所需的持久化欄位。

---

## 修改檔案

### `Models/PlayerStateModel.swift`

在現有欄位後新增 V6-1 職業 & 技能欄位：

```swift
// MARK: - 職業 & 技能（V6-1）
var classKey: String = ""               // 空字串 = 尚未選擇職業
var equippedSkillKeysRaw: String = ""   // 逗號分隔，最多 4 個 key

// 便利存取（非 SwiftData 欄位）
var equippedSkillKeys: [String] {
    get {
        equippedSkillKeysRaw
            .split(separator: ",")
            .compactMap { s in s.isEmpty ? nil : String(s) }
    }
    set {
        equippedSkillKeysRaw = newValue.joined(separator: ",")
    }
}
```

---

### `Models/TaskModel.swift`

在現有欄位後新增技能快照欄位：

```swift
var snapshotSkillKeysRaw: String = ""   // 出發時裝備的技能快照（逗號分隔）

var snapshotSkillKeys: [String] {
    get {
        snapshotSkillKeysRaw
            .split(separator: ",")
            .compactMap { s in s.isEmpty ? nil : String(s) }
    }
    set {
        snapshotSkillKeysRaw = newValue.joined(separator: ",")
    }
}
```

---

## SwiftData 遷移策略

| 項目 | 說明 |
|---|---|
| 遷移方式 | 輕量遷移（不需 VersionedSchema） |
| 原因 | 所有新欄位皆有預設值 `""`，SwiftData 自動處理新增欄位 |
| 失敗保底 | `IdleBattleRPGApp.swift` 第 23-34 行現有 fallback 邏輯：遷移失敗時刪除 store 重建 |
| 舊存檔升級後 | `classKey = ""`，進入遊戲自動觸發職業選擇畫面（見 T04） |

---

## 設計決策

| 決策 | 說明 |
|---|---|
| 用逗號分隔字串而非 Array | SwiftData 不原生支援 `[String]`，逗號字串是最簡方案 |
| computed property 雙向轉換 | 呼叫端直接操作 `[String]`，不需手動處理逗號 |
| `snapshotSkillKeysRaw` 在出發時寫入 | 結算時用快照，確保確定性 RNG |

---

## 驗收標準

- [ ] `PlayerStateModel` 有 `classKey` 和 `equippedSkillKeysRaw` 欄位
- [ ] `equippedSkillKeys` computed 屬性正確讀寫（逗號分隔雙向轉換）
- [ ] `TaskModel` 有 `snapshotSkillKeysRaw` 欄位
- [ ] `snapshotSkillKeys` computed 屬性正確讀寫
- [ ] 舊存檔升級後 `classKey = ""`，不 crash
- [ ] Build + Test 通過
