# V2-1 Ticket 01：地下城靜態資料正式化

**狀態：** ✅ 已完成（commit `c8ab784`）

---

## 目標

依照 `V2_1_DUNGEON_PROGRESSION_SPEC.md` 正式定義 3 區域 × 4 樓層的靜態資料、12 種區域素材、新 `offhand` 裝備部位、12 件套裝裝備。

---

## 新增 / 修改檔案

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `StaticData/DungeonRegionDef.swift` | 🆕 新增 | `DungeonFloorDef` + `DungeonRegionDef` struct；3 區域 × 4 樓層完整靜態資料 |
| `StaticData/MaterialType.swift` | ✏️ 修改 | 新增 12 個區域素材 enum case；`displayName` / `icon` / `isRegionMaterial` / `isBossMaterial` |
| `StaticData/EquipmentDef.swift` | ✏️ 修改 | `EquipmentSlot` 新增 `.offhand`；12 件 V2-1 套裝裝備定義（3 區 × 4 部位）|
| `Models/MaterialInventoryModel.swift` | ✏️ 修改 | Bridge no-op：3 個 switch 皆加入 12 個新素材 grouped case（Ticket 02 前暫回傳 0 / no-op）|
| `Services/SettlementService.swift` | ✏️ 修改 | Bridge case：`fillGatherResults` switch 新增 12 個新素材的 `break` case |
| `Views/CharacterView.swift` | ✏️ 修改 | `amount(for:)` private extension 改為 `default: return amount(of: mat)` 以保持 exhaustiveness |

---

## StaticData 結構

```
DungeonRegionDef（3 個）
  └── DungeonFloorDef（每區 4 層）
        ├── floorIndex: 1–4（第 4 層為 isBossFloor）
        ├── recommendedPower（佔位值，待數值平衡工單調整）
        ├── goldPerBattleRange: ClosedRange<Int>
        ├── dropTable: [DropTableEntry]
        ├── unlocksEquipmentKey / unlocksSlot（首通解鎖裝備）
        └── bossName: String?（一般層為 nil）
```

### 區域與樓層對應

| 區域 | 樓層 | 解鎖部位 | 建議戰力 |
|---|---|---|---|
| 荒野邊境 | F1 殘木前哨 | 飾品 | 40 |
| 荒野邊境 | F2 獸痕荒徑 | 防具 | 60 |
| 荒野邊境 | F3 掠影交界 | 副手 | 80 |
| 荒野邊境 | F4 裂牙王庭（Boss）| 武器 | 110 |
| 廢棄礦坑 | F1 殘軌礦道 | 飾品 | 140 |
| 廢棄礦坑 | F2 支架裂層 | 防具 | 175 |
| 廢棄礦坑 | F3 沉脈深坑 | 副手 | 210 |
| 廢棄礦坑 | F4 吞岩巢庭（Boss）| 武器 | 260 |
| 古代遺跡 | F1 破階外庭 | 飾品 | 330 |
| 古代遺跡 | F2 斷碑迴廊 | 防具 | 400 |
| 古代遺跡 | F3 守誓前殿 | 副手 | 470 |
| 古代遺跡 | F4 王印聖所（Boss）| 武器 | 550 |

---

## 刻意先不做的事

- **`MaterialInventoryModel` SwiftData 欄位**：留待 Ticket 02
- **`TaskModel` 結果欄位**：區域素材結算欄位留待 Ticket 02
- **`AdventureView` 樓層選擇 UI**：留待 Ticket 04
- **首通解鎖邏輯（Progression）**：留待 Ticket 03
- **數值平衡**：`recommendedPower` 為佔位值，待獨立工單調整

---

## 關鍵決策

**V1 DungeonAreaDef.swift 維持不動：**
舊的 `DungeonAreaDef`（3 區域，扁平結構）與新的 `DungeonRegionDef`（樓層結構）並存，確保 MVP 功能不受影響。

**Bridge no-op 模式：**
所有 V2-1 新素材在 `MaterialInventoryModel` 內以 grouped case 回傳 0 / no-op，Ticket 01 可安全合入 main 而不破壞任何現有功能。

**`DropTableEntry` 複用：**
`DungeonRegionDef` 的掉落表直接複用 `DungeonAreaDef.swift` 中已定義的 struct，不重複定義。
