# V3-3 Ticket 02：背包列表換裝差值顯示

**狀態：** ✅ 完成

**依賴：** Ticket 01（StatDiff + equipDiff 存在）

---

## 目標

CharacterView「背包」Segment 的未裝備裝備列表，每件右側顯示換裝後的屬性差值，
以顏色區分提升（綠）/ 下降（紅）/ 相同（不顯示）。

---

## 修改檔案

`IdleBattleRPG/Views/CharacterView.swift`

### 背包裝備列表（backpackSection 或對應 ForEach）

在每個未裝備裝備 row 的 HStack 右側，按鈕/箭頭之前加入：

```swift
let diff = viewModel.equipDiff(candidate: equip, equipped: equipments.filter { $0.isEquipped })
if diff.hasAnyChange {
    diffBadge(diff)
}
```

### diffBadge helper（@ViewBuilder）

```swift
@ViewBuilder
private func diffBadge(_ diff: CharacterViewModel.StatDiff) -> some View {
    HStack(spacing: 3) {
        if diff.atk != 0 {
            Text(diffText("⚔", diff.atk))
                .foregroundStyle(diff.atk > 0 ? .green : .red)
        }
        if diff.def != 0 {
            Text(diffText("🛡", diff.def))
                .foregroundStyle(diff.def > 0 ? .green : .red)
        }
        if diff.hp != 0 {
            Text(diffText("❤", diff.hp))
                .foregroundStyle(diff.hp > 0 ? .green : .red)
        }
    }
    .font(.caption2)
}

private func diffText(_ icon: String, _ value: Int) -> String {
    value > 0 ? "\(icon)+\(value)" : "\(icon)\(value)"
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/CharacterView.swift` | ✏️ 修改（背包裝備 row 加差值 badge + helper） |

---

## 驗收標準

- [ ] 背包有裝備時，右側顯示差值（如 `⚔+16 🛡+0`，零值不顯示）
- [ ] 提升屬性顯示綠色，下降屬性顯示紅色
- [ ] 換裝後 diff 重新計算（@Query 驅動）
- [ ] 同部位無已裝備時，差值等於裝備本身屬性（全綠）
- [ ] 背包空時不崩潰
- [ ] Build 無錯誤
