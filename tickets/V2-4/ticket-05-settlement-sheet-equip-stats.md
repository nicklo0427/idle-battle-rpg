# V2-4 Ticket 05：SettlementSheet 裝備屬性顯示

**狀態：** ✅ 完成

**依賴：** 無（獨立）

---

## 目標

結算 Sheet 目前顯示「🗡 新裝備 ×1」，玩家不知道拿到了什麼裝備、屬性如何。
本 ticket 改為逐件顯示裝備名稱與屬性，並讓首通解鎖行更突出。

---

## 目標顯示效果

**鑄造完成：**
```
🗡 裂牙獵刃  ATK +22
```

**Boss 武器掉落（浮動 ATK）：**
```
🗡 裂牙獵刃  ATK +26 ✦
```

**普通裝備：**
```
🛡 荒徑皮甲  DEF +16 / HP +38
```

**首通解鎖（更突出）：**
```
🔓 解鎖配方：鑄造裂牙獵刃        ← 粗體 / accent color
```

---

## 修改一：SettlementViewModel

**檔案：** `IdleBattleRPG/ViewModels/SettlementViewModel.swift`

目前 `ClaimResult.rewardLines` 對裝備只輸出 `"🗡 新裝備 ×\(equipmentsAdded)"`。

### 方案

`ClaimResult` 的 `rewardLines` 目前是 `[String]`，難以區分裝備行與一般行。
建議在 `SettlementViewModel` 新增一個轉換層，從 `completed` TaskModel 組裝更豐富的 `SettlementRow`：

```swift
struct SettlementRow: Identifiable {
    enum RowKind {
        case gold(Int)
        case material(MaterialType, Int)
        case equipment(name: String, stats: String, isRolled: Bool)
        case firstClear(floorName: String)
        case regionUnlock(regionName: String)
    }
    let id = UUID()
    let kind: RowKind
}
```

`SettlementViewModel` 從 completed tasks 組裝 `[SettlementRow]`，
`SettlementSheet` 依 kind render 不同樣式。

### 裝備行組裝邏輯

```swift
// craft 任務
if task.kind == .craft, let key = task.resultCraftedEquipKey,
   let def = EquipmentDef.find(key: key) {
    let stats = statsString(def: def, rolledAtk: nil)
    rows.append(.init(kind: .equipment(name: def.name, stats: stats, isRolled: false)))
}

// dungeon Boss 武器掉落
if task.kind == .dungeon, let key = task.resultCraftedEquipKey,
   let def = EquipmentDef.find(key: key) {
    let atk   = task.resultRolledAtk > 0 ? task.resultRolledAtk : def.baseAtk
    let stats = "ATK +\(atk)"
    rows.append(.init(kind: .equipment(name: def.name, stats: stats, isRolled: true)))
}

// 輔助方法
func statsString(def: EquipmentDef, rolledAtk: Int?) -> String {
    var parts: [String] = []
    let atk = rolledAtk ?? def.baseAtk
    if atk > 0 { parts.append("ATK +\(atk)") }
    if def.baseDef > 0 { parts.append("DEF +\(def.baseDef)") }
    if def.baseHp  > 0 { parts.append("HP +\(def.baseHp)") }
    return parts.joined(separator: " / ")
}
```

---

## 修改二：SettlementSheet

**檔案：** `IdleBattleRPG/Views/SettlementSheet.swift`

根據 `SettlementRow.kind` render 不同樣式：

```swift
ForEach(viewModel.rows) { row in
    switch row.kind {
    case .gold(let amt):
        Text("💰 金幣 +\(amt)")
    case .material(let mat, let amt):
        Text("\(mat.icon) \(mat.displayName) +\(amt)")
    case .equipment(let name, let stats, let isRolled):
        HStack {
            Text("🗡 \(name)")
                .fontWeight(.medium)
            Spacer()
            Text(stats)
                .font(.caption)
                .foregroundStyle(.secondary)
            if isRolled { Text("✦").foregroundStyle(.orange) }
        }
    case .firstClear(let floorName):
        HStack {
            Image(systemName: "lock.open.fill").foregroundStyle(.accentColor)
            Text("解鎖配方：\(floorName)")
                .fontWeight(.semibold)
                .foregroundStyle(.accentColor)
        }
    case .regionUnlock(let regionName):
        HStack {
            Image(systemName: "map.fill").foregroundStyle(.green)
            Text("新區域開放：\(regionName)")
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `ViewModels/SettlementViewModel.swift` | ✏️ 修改（新增 SettlementRow struct + 組裝邏輯） |
| `Views/SettlementSheet.swift` | ✏️ 修改（依 SettlementRow.kind render 不同樣式） |

> `ClaimResult.rewardLines`（在 `TaskClaimService`）保持不變，只在 ViewModel 層做 UI 轉換。

---

## 驗收標準

- [ ] 鑄造完成結算顯示「裝備名稱 + ATK/DEF/HP」
- [ ] Boss 武器掉落顯示浮動 ATK 值 + ✦ 標記
- [ ] 首通解鎖行使用 accent color 加粗，視覺上比金幣/素材行更突出
- [ ] 區域解鎖行使用綠色 + 地圖圖示
- [ ] 無裝備掉落時不顯示裝備行（不出現空白行）
- [ ] Build 無錯誤
