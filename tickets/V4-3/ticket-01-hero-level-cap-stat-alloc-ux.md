# V4-3 Ticket 01：英雄等級上限 10→20 + 加點確認 / 重置 UX

**狀態：** ✅ 已完成（V6-4 涵蓋）

**依賴：** 無

---

## 目標

1. 英雄等級上限從 10 提升至 20，補充 Lv.11–20 的 EXP 需求
2. 加點改為「先 pending → 確認加點」流程，支援反悔取消
3. 新增「重置所有屬性點」功能

---

## 修改檔案

- `AppConstants.swift`
- `Views/CharacterView.swift`
- `ViewModels/CharacterViewModel.swift`
- `Services/CharacterProgressionService.swift`

---

## 等級上限修改

### AppConstants.swift

```swift
// 舊
static let heroMaxLevel = 10

// 新
static let heroMaxLevel = 20
```

### CharacterProgressionService.swift — EXP 門檻表

補充 Lv.11–20：

```swift
// 建議數值（遞增設計）
static let expThresholds: [Int: Int] = [
    1: 100,   2: 150,   3: 200,   4: 280,   5: 380,
    6: 500,   7: 650,   8: 820,   9: 1000,  10: 1200,
    11: 1500, 12: 1850, 13: 2250, 14: 2700, 15: 3200,
    16: 3800, 17: 4500, 18: 5300, 19: 6200, 20: 0  // Lv.20 上限，無需求
]
```

---

## 加點 Pending / 確認 / 取消流程

### CharacterViewModel.swift — 新增 pending 狀態

```swift
@Published var pendingAtk: Int = 0
@Published var pendingDef: Int = 0
@Published var pendingHp:  Int = 0

var hasPendingAllocations: Bool {
    pendingAtk > 0 || pendingDef > 0 || pendingHp > 0
}

var remainingPendingPoints: Int {
    (player?.availableStatPoints ?? 0) - pendingAtk - pendingDef - pendingHp
}
```

### 加點按鈕邏輯（`+` 按鈕）

```swift
func addPendingPoint(to stat: StatType) {
    guard remainingPendingPoints > 0 else { return }
    switch stat {
    case .atk: pendingAtk += 1
    case .def: pendingDef += 1
    case .hp:  pendingHp  += 1
    }
}
```

### 確認加點

```swift
func commitAllocations() {
    characterProgressionService.commitAllocations(
        atkDelta: pendingAtk, defDelta: pendingDef, hpDelta: pendingHp
    )
    pendingAtk = 0; pendingDef = 0; pendingHp = 0
}
```

### 取消加點

```swift
func cancelAllocations() {
    pendingAtk = 0; pendingDef = 0; pendingHp = 0
}
```

### 重置所有屬性點

```swift
func resetAllStats() {
    characterProgressionService.resetAllStats()
    pendingAtk = 0; pendingDef = 0; pendingHp = 0
}
```

---

## CharacterView.swift — UI 修改

### 數值橙色預覽

當有 pending 時，對應欄位顯示預覽：

```
ATK  15  →  +3 = 18   （橙色部分）
```

```swift
HStack {
    Text("ATK  \(player.atkPoints * 3)")
    if pendingAtk > 0 {
        Text("→ +\(pendingAtk * 3) = \((player.atkPoints + pendingAtk) * 3)")
            .foregroundStyle(.orange)
    }
}
```

### 確認 / 取消按鈕（pending 時出現）

```swift
if viewModel.hasPendingAllocations {
    HStack {
        Button("確認加點") { viewModel.commitAllocations() }
            .buttonStyle(.borderedProminent)
        Button("取消") { viewModel.cancelAllocations() }
            .buttonStyle(.bordered)
    }
}
```

### 重置按鈕

```swift
Button("重置所有屬性點") { showResetAlert = true }
    .font(.caption)
    .foregroundStyle(.secondary)
```

Alert：
```swift
.alert("確認重置？", isPresented: $showResetAlert) {
    Button("重置", role: .destructive) { viewModel.resetAllStats() }
    Button("取消", role: .cancel) { }
} message: {
    Text("所有已分配的屬性點將全部退回，可重新分配。")
}
```

---

## CharacterProgressionService.swift — 新增方法

```swift
func commitAllocations(atkDelta: Int, defDelta: Int, hpDelta: Int) {
    guard let player = fetchPlayer() else { return }
    player.atkPoints += atkDelta
    player.defPoints += defDelta
    player.hpPoints  += hpDelta
    player.availableStatPoints -= (atkDelta + defDelta + hpDelta)
    try? context.save()
}

func resetAllStats() {
    guard let player = fetchPlayer() else { return }
    let total = player.atkPoints + player.defPoints + player.hpPoints
    player.availableStatPoints += total
    player.atkPoints = 0
    player.defPoints = 0
    player.hpPoints  = 0
    try? context.save()
}
```

---

## 驗收標準

- [ ] 等級上限顯示為 20，Lv.10 後繼續可升級
- [ ] EXP 門檻 Lv.11–20 正確設置
- [ ] `+` 按鈕累加 pending，不即時寫入 SwiftData
- [ ] pending 期間橙色預覽數值顯示正確
- [ ] 「確認加點」後實際寫入，pending 清零
- [ ] 「取消」後 pending 清零，數值不變
- [ ] 「重置所有屬性點」Alert 確認後全部退回
