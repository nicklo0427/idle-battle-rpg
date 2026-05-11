# V10-1 Ticket 05：職業初始裝備

**狀態：** ⚠️ 調整中（配合 T06 引導式教程，發放時機從職業確認改為教程完成）

**依賴：** T03（ClassDef 需先有 `starterEquipmentKeys` 欄位）

---

## 原始設計調整說明

原設計在 ClassSelectionView 確認職業後立即呼叫 `grantStarterEquipment`，發放對應初始裝備。

**T06 引入後，改為：**
- ClassSelectionView 確認職業時**不再**發放裝備
- 裝備改由 T06 引導式教程完成（教程鑄造 5 秒後授予）
- `starterEquipmentKeys` 欄位與 `grantStarterEquipment` 方法**保留**，改由 T06 的教程鑄造結算時呼叫

---

## 職業裝備對照（不變）

| 職業 | 武器 | 武器屬性 | 副手 | 副手屬性 |
|------|------|---------|------|---------|
| 劍士 | 破舊短劍 `rusty_sword` | ATK+12 | 破舊格擋刃 `rusty_parry_blade` | ATK+2 |
| 弓手 | 破舊短弓 `rusty_bow` | ATK+12 | 破舊箭筒 `rusty_quiver` | ATK+4 |
| 法師 | 破舊魔杖 `rusty_wand` | ATK+12 | 破舊法典 `rusty_grimoire` | HP+6 |
| 聖騎士 | 破舊戰錘 `rusty_hammer` | ATK+6 | 破舊木盾 `rusty_shield` | DEF+2, HP+4 |

---

## EquipmentDef 新增條目（不變）

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

### `StaticData/ClassDef.swift`（不變）

```swift
let starterEquipmentKeys: [String]
```

### `Services/EquipmentService.swift`（不變）

```swift
func grantStarterEquipment(for classDef: ClassDef)
// 由 T06 教程鑄造結算時呼叫，不再由 ClassSelectionView 呼叫
```

### `Views/ClassSelectionView.swift`（調整）

移除確認職業時的 `grantStarterEquipment` 呼叫：

```swift
// ❌ 移除
appState.equipmentService.grantStarterEquipment(for: classDef)

// ✅ 只保留
player.classKey = classDef.key
try? context.save()
// 裝備改由 T06 教程結算時發放
```

### `Models/DatabaseSeeder.swift`（調整）

`seedStartingEquipment()` 守門更嚴格：
- 新玩家（`classKey` 空）：跳過（裝備由 T06 教程授予）
- 舊存檔（`classKey` 非空，`onboardingStep >= 3`）：若無裝備則補種 `rusty_sword`（向後相容保護）

---

## 舊存檔相容

- 舊存檔 `rusty_sword` 已在 DB → `seedStartingEquipment` 的 `existing.isEmpty` 守門生效 → 安全
- 新玩家直到教程完成（`onboardingStep == 3`）才拿到武器

---

## 驗證

1. 新玩家選完職業後，背包**無任何裝備**
2. 完成 T06 教程鑄造後，背包出現對應職業武器 + 副手（皆已裝備）
3. 舊存檔升級後 `rusty_sword` 保留不消失
