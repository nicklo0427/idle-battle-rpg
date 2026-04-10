# V4-2 Ticket 05：FloorDetailSheet 菁英整合

**狀態：** 🔲 待實作

**依賴：** T03 DungeonProgressionModel、T04 EliteBattleSheet

---

## 目標

修改 `FloorDetailSheet`（在 AdventureView 內），新增「地區菁英」Section，並調整解鎖說明文字。

---

## 修改檔案

`Views/AdventureView.swift`（FloorDetailSheet 內部）

---

## 新增「地區菁英」Section

位置：放在出征按鈕之前

```swift
// 菁英已清除
if progressionService.isEliteCleared(floorKey: floor.key) {
    Label("菁英已討伐", systemImage: "checkmark.seal.fill")
        .foregroundStyle(.green)
}
// 菁英未清除 + 戰力足夠
else if heroStats.power >= (EliteDef.find(floorKey: floor.key)?.minimumPowerToChallenge ?? 0) {
    Button("挑戰菁英") {
        showEliteBattle = true
    }
    .buttonStyle(.bordered)
    .tint(.orange)
}
// 菁英未清除 + 戰力不足
else {
    VStack(alignment: .leading, spacing: 4) {
        Button("挑戰菁英") { }
            .buttonStyle(.bordered)
            .disabled(true)
        Text("需要戰力 \(EliteDef.find(floorKey: floor.key)?.minimumPowerToChallenge ?? 0)")
            .font(.caption)
            .foregroundStyle(.red)
    }
}
```

`.sheet(isPresented: $showEliteBattle) {`
```swift
    if let elite = EliteDef.find(floorKey: floor.key) {
        EliteBattleSheet(
            elite: elite,
            heroStats: heroStats,
            onEliteDefeated: {
                progressionService.markEliteCleared(floorKey: floor.key)
            }
        )
    }
}
```

---

## 解鎖說明文字修改

現有 UI 中「首通解鎖」相關提示：

**舊：** `"首次通關此層即解鎖下一層"`
**新：** `"擊敗地區菁英以解鎖下一層"`

（只改說明文字，不影響其他 UI）

---

## 驗收標準

- [ ] 菁英已清除：顯示綠色勾勾標記
- [ ] 菁英未清除 + 戰力足：顯示橙色「挑戰菁英」按鈕
- [ ] 菁英未清除 + 戰力不足：按鈕 disabled + 紅色戰力需求提示
- [ ] 點「挑戰菁英」開啟 EliteBattleSheet
- [ ] 勝利後 Sheet 關閉，FloorDetailSheet 顯示「菁英已討伐」
- [ ] 下一層在菁英通關後正確解鎖（isFloorUnlocked 回傳 true）
