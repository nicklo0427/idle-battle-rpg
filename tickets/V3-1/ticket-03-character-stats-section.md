# V3-1 Ticket 03：CharacterView 統計 Section

**狀態：** ✅ 完成

**依賴：** Ticket 01、Ticket 02

---

## 目標

在角色頁「裝備」Segment 底部加入「累計統計」Section，讓玩家直接看見自己的遊玩成就。

---

## 修改檔案

`IdleBattleRPG/Views/CharacterView.swift`

### 位置

在「裝備」Segment 的 List 內，升級區塊（或屬性分配）下方、List 結尾前加入：

```swift
Section("累計統計") {
    statRow(icon: "💰", label: "累計金幣收入", value: "\(player.totalGoldEarned)")
    statRow(icon: "⚔️", label: "地下城勝場",   value: "\(player.totalBattlesWon)")
    statRow(icon: "🛡",  label: "地下城敗場",   value: "\(player.totalBattlesLost)")
    statRow(icon: "🔨", label: "裝備獲得件數", value: "\(player.totalItemsCrafted)")
    statRow(icon: "⚡", label: "歷史最高戰力", value: "\(player.highestPowerReached)")
}
```

### statRow helper（抽成 @ViewBuilder）

```swift
@ViewBuilder
private func statRow(icon: String, label: String, value: String) -> some View {
    HStack {
        Text("\(icon) \(label)")
            .foregroundStyle(.secondary)
        Spacer()
        Text(value)
            .fontWeight(.medium)
            .monospacedDigit()
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/CharacterView.swift` | ✏️ 修改（裝備頁新增統計 Section + statRow helper） |

---

## 驗收標準

- [ ] 裝備 Segment 底部出現「累計統計」Section，包含 5 行
- [ ] 數值與 PlayerStateModel 欄位一致（@Query 驅動即時更新）
- [ ] 0 值時顯示 "0"，不隱藏（玩家剛開始時全為 0 是正常狀態）
- [ ] Build 無錯誤
