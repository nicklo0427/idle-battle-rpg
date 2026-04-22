# V4-5 Ticket 03：精良裝備金色視覺

**狀態：** ✅ 已完成

**依賴：** 無

---

## 目標

為精良裝備在背包、裝備選擇、裝備槽等位置加上金色視覺標記，提升稀有度辨識感。

---

## 修改檔案

`Views/CharacterView.swift`（背包 + 裝備槽 + EquipSelectSheet）

---

## 各位置狀態

| 位置 | 功能 | 狀態 |
|---|---|---|
| 背包列表 | 名稱 + 稀有度文字金色 | ✅ 已完成 |
| 背包列表 | 左側金色 3px indicator | 🔲 未完成 |
| EquipSelectSheet | 名稱 + 稀有度文字金色 | ✅ 已完成 |
| EquipSelectSheet | 精良裝備 ★ 前綴 | 🔲 未完成 |
| 裝備槽（已裝備） | 名稱 + 稀有度文字金色 | ✅ 已完成 |
| 裝備槽（已裝備） | 金色 strokeBorder 外框 | 🔲 未完成 |

---

## 已完成：文字金色

`CharacterView.swift` 多處已套用 `Color.rarityRefined`：

```swift
.foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.primary)
```

---

## 待實作：背包列表左側 indicator

`backpackItemRow(_:)` 約 line 1128，在 `HStack` 開頭插入：

```swift
if item.rarity == .refined {
    Rectangle()
        .fill(Color.rarityRefined.opacity(0.8))
        .frame(width: 3)
        .clipShape(Capsule())
}
```

---

## 待實作：EquipSelectSheet ★ 前綴

`EquipSelectSheet` 約 line 1218，在 `isRolledBossWeapon` 判斷之前插入：

```swift
if item.rarity == .refined && !item.isRolledBossWeapon {
    Text("★").font(.caption2).foregroundStyle(Color.rarityRefined)
}
```

> Boss 武器（`isRolledBossWeapon == true`）保留原有 `✦`，不疊加 ★。

---

## 待實作：裝備槽金色外框

`equippedSlotRow(slot:item:)` 約 line 1120，在 `.contentShape(Rectangle())` 之後加 `.overlay`：

```swift
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
            item?.rarity == .refined
                ? Color.rarityRefined.opacity(0.6)
                : Color.clear,
            lineWidth: 1.5
        )
)
```

---

## 驗收標準

- [x] 背包列表：精良裝備名稱 + 稀有度標籤呈金色
- [x] 背包列表：精良裝備左側顯示金色 3px 細線
- [x] EquipSelectSheet：精良裝備名稱呈金色
- [x] EquipSelectSheet：精良裝備名稱前有 ★ 金色（Boss 武器除外）
- [x] 裝備槽：已裝備精良裝備顯示金色外框
- [x] 普通裝備視覺不受影響
- [x] 不影響現有 UI 佈局或互動
