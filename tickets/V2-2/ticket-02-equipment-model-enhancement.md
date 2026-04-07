# V2-2 Ticket 02：EquipmentModel 強化欄位 + HeroStats 更新

**狀態：** ✅ 已完成

**依賴：** Ticket 01（EnhancementDef 靜態資料）

---

## 目標

在 `EquipmentModel` 加入 `enhancementLevel: Int`，並更新 `atkBonus / defBonus / hpBonus` 計算屬性以納入強化加成。`HeroStatsService` 不需修改（已透過這三個 computed property 讀值）。

---

## 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Models/EquipmentModel.swift` | ✏️ 修改 | 新增 `enhancementLevel: Int`；更新三個 computed property；更新 `init` |

**其他無需修改：**
- `HeroStatsService`：已透過 `equipment.atkBonus` 等 computed property 取值
- `CharacterView`：顯示邏輯在 Ticket 04 處理
- `EquipmentService`：只做裝備 / 卸除，不涉及強化

---

## 修改內容

### `EquipmentModel` 新增欄位

```swift
/// V2-2 強化等級；0 = 未強化，1–5 = 強化等級
var enhancementLevel: Int
```

**`init` 更新：**

```swift
init(
    defKey: String, slot: EquipmentSlot, rarity: EquipmentRarity,
    isEquipped: Bool = false, rolledAtk: Int? = nil,
    enhancementLevel: Int = 0   // 新增，預設 0
) { ... }
```

### Computed properties 更新

```swift
/// ATK 加成 = 基礎（rolledAtk 優先）+ 強化加成
var atkBonus: Int {
    let base = rolledAtk ?? def?.atkBonus ?? 0
    let bonus = EnhancementDef.bonus(for: slot)?.atkPerLevel ?? 0
    return base + bonus * enhancementLevel
}

/// DEF 加成 = 基礎 + 強化加成
var defBonus: Int {
    let base = def?.defBonus ?? 0
    let bonus = EnhancementDef.bonus(for: slot)?.defPerLevel ?? 0
    return base + bonus * enhancementLevel
}

/// HP 加成 = 基礎 + 強化加成
var hpBonus: Int {
    let base = def?.hpBonus ?? 0
    let bonus = EnhancementDef.bonus(for: slot)?.hpPerLevel ?? 0
    return base + bonus * enhancementLevel
}
```

### displayName 更新

```swift
var displayName: String {
    let base = def?.name ?? defKey
    return enhancementLevel > 0 ? "\(base) +\(enhancementLevel)" : base
}
```

---

## SwiftData Migration 注意

`enhancementLevel` 是新欄位，需確認 SwiftData 在既有資料上的行為：
- SwiftData 會自動補預設值 `0` 給舊資料（無需手動 migration）
- 但需確保 `init` 參數提供 `= 0` 預設值，防止 `TaskClaimService` 建立裝備時遺忘此欄位

---

## 驗收標準

- [ ] 新裝備（`enhancementLevel = 0`）的三個 bonus 與修改前完全相同（無回歸）
- [ ] `enhancementLevel = 3` 的武器，ATK 正確 = `base + 4×3 = base + 12`
- [ ] `displayName` 對 +0 裝備不顯示後綴，+1 顯示「XXX +1」
- [ ] 既有裝備資料在 App 重啟後 `enhancementLevel` 正確預設為 0
- [ ] `HeroStatsService` 無需修改且計算結果包含強化加成（透過 computed property 自動生效）
