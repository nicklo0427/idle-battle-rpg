# V6-1 Ticket 02：PlayerStateModel 技能欄位擴充

**狀態：** 🔲 待實作
**版本：** V6-1
**依賴：** T01（SkillDef 靜態資料）

---

## 目標

在 `PlayerStateModel` 新增技能選擇欄位。
天賦自動解鎖（依等級），**不需存入 Model**，每次從 `TalentDef.unlocked(atLevel:)` 計算即可。

---

## 修改檔案

### `IdleBattleRPG/Models/PlayerStateModel.swift`

新增一個欄位：

```swift
@Model
class PlayerStateModel {
    // ... 現有欄位 ...

    /// 目前選中的主動技能 key（nil = 未選，使用預設無技能）
    var equippedSkillKey: String?

    // 注意：天賦不存 Model，由 TalentDef.unlocked(atLevel: heroLevel) 動態計算
}
```

---

## SwiftData Migration

由於新增欄位，需要做 schema migration，避免現有存檔資料遺失。

### 實作方式：VersionedSchema + MigrationPlan

```swift
// Models/Migration/SchemaV1.swift（現有 schema 封存）
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        PlayerStateModel.self, MaterialInventoryModel.self,
        EquipmentModel.self, TaskModel.self,
        DungeonProgressionModel.self, AchievementProgressModel.self
    ]
    // 舊版 PlayerStateModel（不含 equippedSkillKey）
}

// Models/Migration/SchemaV2.swift（新 schema）
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [
        PlayerStateModel.self, ...  // 含 equippedSkillKey
    ]
}

// Models/Migration/MigrationPlan.swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    static var stages: [MigrationStage] = [
        MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    ]
    // lightweight migration 可自動處理新增 optional 欄位（nil 填入）
}
```

### `IdleBattleRPGApp.swift` 更新

```swift
let container = try ModelContainer(
    for: PlayerStateModel.self, ...,
    migrationPlan: AppMigrationPlan.self
)
```

---

## 設計決策

| 決策 | 說明 |
|---|---|
| 天賦不存 Model | 天賦由等級動態計算，存 key array 容易過期且增加複雜度 |
| `equippedSkillKey` 為 optional | nil = 使用「無技能」，向下相容舊存檔 |
| Lightweight migration | 只新增 optional 欄位，Swift Data 可自動處理 |

---

## 驗收標準

- [ ] 舊存檔升級後 `equippedSkillKey = nil`，不 crash
- [ ] 新存檔可正常讀寫 `equippedSkillKey`
- [ ] Build + Test 通過
- [ ] 無 SwiftData migration error log
