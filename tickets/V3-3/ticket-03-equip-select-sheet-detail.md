# V3-3 Ticket 03：EquipSelectSheet 屬性詳情改善

**狀態：** ✅ 完成

**依賴：** Ticket 01（StatDiff + equipDiff）

---

## 目標

點擊已裝備欄位觸發的換裝 Sheet，目前只顯示裝備名稱與稀有度。
改為同時顯示完整屬性 + 換裝差值，讓玩家在換裝時有足夠資訊做判斷。

---

## 現狀定位

**觸發路徑：** CharacterView 裝備 Segment → 點已裝備欄位 → `equipSheetSlot = slot` → Sheet 彈出

**現有 EquipSelectSheet 行為：**
- 列出同部位所有裝備（已裝備 + 背包）
- 點擊 → 呼叫 viewModel.equip()
- 顯示：名稱 / 稀有度 / 強化等級（`+N`）/ 已裝備勾勾

---

## 修改檔案

`IdleBattleRPG/Views/CharacterView.swift`（EquipSelectSheet 相關部分）

### 每個備選裝備 row 改為三行結構

```swift
VStack(alignment: .leading, spacing: 2) {
    // 行 1：名稱 + 強化等級
    HStack {
        Text(equip.displayName)      // 含 +N 後綴
            .fontWeight(equip.isEquipped ? .semibold : .regular)
            .foregroundStyle(equip.isEquipped ? .primary : .primary)
        if equip.isEquipped {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        }
        Spacer()
        Text(equip.rarity.displayName)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    // 行 2：完整屬性
    let def = EquipmentDef.find(key: equip.defKey)
    HStack(spacing: 8) {
        if equip.totalAtk > 0 { Text("⚔ \(equip.totalAtk)").font(.caption2).foregroundStyle(.secondary) }
        if equip.totalDef > 0 { Text("🛡 \(equip.totalDef)").font(.caption2).foregroundStyle(.secondary) }
        if equip.totalHp  > 0 { Text("❤ \(equip.totalHp)") .font(.caption2).foregroundStyle(.secondary) }
    }

    // 行 3：換裝差值（已裝備的不顯示 diff）
    if !equip.isEquipped {
        let diff = viewModel.equipDiff(
            candidate: equip,
            equipped: equipments.filter { $0.isEquipped }
        )
        if diff.hasAnyChange {
            diffBadge(diff)   // 複用 Ticket 02 的 helper
        }
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/CharacterView.swift` | ✏️ 修改（EquipSelectSheet row 改三行結構） |

---

## 驗收標準

- [ ] 點武器欄位 → Sheet 顯示所有武器，每件含完整屬性（ATK 數值）
- [ ] 非當前已裝備的武器顯示換裝差值
- [ ] 已裝備的武器不顯示 diff（因為差值為 0）
- [ ] Boss 武器（浮動 ATK）顯示當前已入帳的實際 ATK 值（totalAtk 從 EquipmentModel 算）
- [ ] Build 無錯誤
