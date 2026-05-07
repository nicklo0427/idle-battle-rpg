# V10-1 Ticket 05：職業初始裝備

**狀態：** ✅ 已完成

**依賴：** T03（ClassDef 需先有 `starterEquipmentKeys` 欄位）

---

## 目標

確認職業後，依職業發放對應的初始裝備（武器 + 副手），取代舊的「所有職業都拿破舊短劍」做法，讓玩家第一眼就感受到職業差異。

---

## 設計原則

- 各職業初始戰力控制在 **66–74**（荒野 F1 推薦戰力 40，保留合理挑戰感）
- 弓手 / 法師：武器名不同，屬性相近（感受職業特色）
- 聖騎士：額外副手（木盾），唯一一開始就有兩件不同風格裝備的職業

---

## 初始裝備對照

| 職業 | 武器 | 武器屬性 | 副手 | 副手屬性 | 估算戰力 |
|------|------|---------|------|---------|---------|
| 劍士 | 破舊短劍（現有 `rusty_sword`）| ATK+12 | 破舊格擋刃 `rusty_parry_blade` | ATK+2 | ≈72 |
| 弓手 | 破舊短弓 `rusty_bow` | ATK+12 | 破舊箭筒 `rusty_quiver` | ATK+4 | ≈66 |
| 法師 | 破舊魔杖 `rusty_wand` | ATK+12 | 破舊法典 `rusty_grimoire` | HP+6 | ≈70 |
| 聖騎士 | 破舊戰錘 `rusty_hammer` | ATK+6 | 破舊木盾 `rusty_shield` | DEF+2, HP+4 | ≈74 |

---

## 新增 EquipmentDef 條目（共 6 個，rusty_sword 現有）

| key | 名稱 | slot | ATK | DEF | HP | 稀有度 |
|-----|------|------|-----|-----|-----|--------|
| `rusty_bow` | 破舊短弓 | weapon | +12 | 0 | 0 | common |
| `rusty_wand` | 破舊魔杖 | weapon | +12 | 0 | 0 | common |
| `rusty_hammer` | 破舊戰錘 | weapon | +6 | 0 | 0 | common |
| `rusty_parry_blade` | 破舊格擋刃 | offhand | +2 | 0 | 0 | common |
| `rusty_quiver` | 破舊箭筒 | offhand | +4 | 0 | 0 | common |
| `rusty_grimoire` | 破舊法典 | offhand | 0 | 0 | +6 | common |
| `rusty_shield` | 破舊木盾 | offhand | 0 | +2 | +4 | common |

---

## 修改檔案

### `StaticData/EquipmentDef.swift`

新增上表 6 個 starter 裝備定義。

### `StaticData/ClassDef.swift`

```swift
struct ClassDef {
    // ...existing...
    let starterEquipmentKeys: [String]
    // 劍士: ["rusty_sword", "rusty_parry_blade"]
    // 弓手: ["rusty_bow", "rusty_quiver"]
    // 法師: ["rusty_wand", "rusty_grimoire"]
    // 聖騎士: ["rusty_hammer", "rusty_shield"]
}
```

### `Services/EquipmentService.swift`

```swift
func grantStarterEquipment(for classDef: ClassDef) {
    // 依 classDef.starterEquipmentKeys 查找 EquipmentDef
    // 建立 EquipmentModel（isEquipped: true）全部 insert，save
}
```

### `Views/ClassSelectionView.swift`

確認職業後，`grantStarterEquipment` 與 `classKey` 儲存在**同一個 context.save()** 中原子完成：

```swift
player.classKey = classDef.key
appState.equipmentService.grantStarterEquipment(for: classDef)
try? context.save()
```

### `Models/DatabaseSeeder.swift`

`seedStartingEquipment()` 加守門條件：

```swift
// 新玩家（classKey 空）略過，裝備由職業選擇時發放
guard let player = ..., !player.classKey.isEmpty else { return }
```

防止舊存檔升級時重複新增初始裝備（`existing.isEmpty` 已保護，但加 classKey 守門更明確）。

---

## 舊存檔相容

- 舊存檔的 `rusty_sword` 已在 DB 中 → `existing.isEmpty` 為 false → `seedStartingEquipment` 跳過 → 安全
- 新玩家職業選擇前 `classKey == ""` → `seedStartingEquipment` 跳過 → 由 `grantStarterEquipment` 負責

---

## 驗證

1. 選劍士 → 背包有「破舊短劍」+「破舊格擋刃」（皆已裝備）
2. 選弓手 → 背包有「破舊短弓」+「破舊箭筒」
3. 選法師 → 背包有「破舊魔杖」+「破舊法典」
4. 選聖騎士 → 背包有「破舊戰錘」+「破舊木盾」（兩件皆已裝備）
5. 舊存檔升級 → `rusty_sword` 保留，不被刪除或重複新增
