# V4-2 Ticket 04：EliteBattleSheet UI

**狀態：** 🔲 待實作

**依賴：** T02 EliteBattleEngine、V4-1 T03 BattleLogSheet

---

## 目標

建立 `EliteBattleSheet`，作為薄層 wrapper，呼叫 `EliteBattleEngine` 並將結果傳入 `BattleLogSheet` 顯示。

---

## 新建檔案

`Views/EliteBattleSheet.swift`

---

## 結構設計

```swift
struct EliteBattleSheet: View {
    let elite: EliteDef
    let heroStats: HeroStats
    let onEliteDefeated: () -> Void    // 通關回呼（給 FloorDetailSheet 更新 UI）

    @State private var result: EliteBattleResult? = nil
    @Environment(\.dismiss) var dismiss
}
```

### 初始化邏輯（onAppear）

```swift
.onAppear {
    let seed = UInt64(Date.now.timeIntervalSinceReferenceDate)
              ^ UInt64(elite.floorKey.hashValue)
    result = EliteBattleEngine.simulate(heroStats: heroStats, elite: elite, seed: seed)
}
```

### 傳入 BattleLogSheet

```swift
if let result {
    BattleLogSheet(
        events: result.toBattleEvents(eliteName: elite.name, heroMaxHp: heroStats.maxHp),
        title: "挑戰 \(elite.name)",
        eliteResult: result.won ? .won : .lost,
        onRetry: { dismiss() }
    )
}
```

### 勝利處理

在 `BattleLogSheet` 播放完成後：
- `eliteResult == .won` → 顯示獎勵文字 + 「關閉」按鈕
- 點「關閉」→ 呼叫 `onEliteDefeated()` → dismiss

### 落敗處理

- `eliteResult == .lost` → 顯示「落敗… 再試一次」按鈕
- 點「再試一次」→ dismiss（回到 FloorDetailSheet，可再次挑戰）

---

## Sheet 設定

```swift
.presentationDetents([.large])
.interactiveDismissDisabled(true)   // 強制只能用按鈕關閉
```

---

## 驗收標準

- [ ] 開啟 EliteBattleSheet 即自動計算並開始播放
- [ ] 勝利後顯示獎勵 + 關閉按鈕
- [ ] 落敗後顯示再試一次按鈕
- [ ] `onEliteDefeated` 回呼在勝利關閉時正確觸發
- [ ] HP 條正確顯示（依 BattleLogSheet 實作）
