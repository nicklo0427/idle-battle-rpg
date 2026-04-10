# V4-5 Ticket 03：精良裝備金色視覺

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

為精良裝備在背包、裝備選擇、裝備槽等位置加上金色視覺標記，提升稀有度辨識感。

---

## 修改檔案

`Views/CharacterView.swift`（背包 + 裝備槽 + EquipSelectSheet）

---

## 背包列表（Inventory List）

精良裝備 row 左側加金色 indicator：

```swift
HStack {
    // 金色 indicator（精良裝備）
    if equipment.rarity == .refined {
        Rectangle()
            .fill(Color.yellow.opacity(0.8))
            .frame(width: 3)
            .clipShape(Capsule())
    }

    VStack(alignment: .leading) {
        Text(def.name)
            .foregroundStyle(equipment.rarity == .refined ? .yellow : .primary)
        Text(equipment.rarity.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    // ...
}
```

---

## EquipSelectSheet（裝備選擇）

精良裝備名稱加金色 + 星號前綴：

```swift
HStack {
    Text(equipment.rarity == .refined ? "★ " : "")
        .foregroundStyle(.yellow)
    + Text(def.name)
        .foregroundStyle(equipment.rarity == .refined ? .yellow : .primary)
}
```

---

## 裝備槽（已裝備精良裝備）

裝備槽外框微光效果：

```swift
// 裝備槽容器
RoundedRectangle(cornerRadius: 8)
    .fill(Color(.systemBackground))
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(
                equippedItem?.rarity == .refined
                    ? Color.yellow.opacity(0.6)
                    : Color.secondary.opacity(0.2),
                lineWidth: equippedItem?.rarity == .refined ? 1.5 : 1
            )
    )
```

---

## 驗收標準

- [ ] 背包列表：精良裝備顯示金色左側 indicator + 金色名稱
- [ ] EquipSelectSheet：精良裝備名稱前有 ★ + 金色
- [ ] 裝備槽：已裝備精良裝備顯示金色邊框
- [ ] 普通裝備視覺不受影響
- [ ] 不影響現有 UI 佈局或互動
