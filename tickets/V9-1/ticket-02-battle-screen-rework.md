# V9-1 Ticket 02：戰鬥畫面重設計

**狀態：** ✅ 完成

**依賴：** 無（BattleEvent.damageAmount 已在 V8-3 T03 新增）

---

## 目標

改善 `BattleLogSheet` 的視覺體驗，四項變更：

| 項目 | 說明 |
|---|---|
| **E** | HP 區改為英雄 vs 敵人左右對峙版面 |
| **D** | 敵人區新增視覺佔位區塊（為未來圖片預留位置）|
| **B** | 關鍵事件（技能 / 暴擊 / 勝敗 / 遭遇）視覺突出 |
| **C** | 受傷 / 治癒時在 HP 條旁短暫顯示傷害數字 |

---

## 修改細節

### `Views/BattleLogSheet.swift`

---

#### E + D：版面重構（hpBarsView → battleVisualsView）

新增 2 個 `@State` 追蹤浮動數字（供 C 使用），另加 2 個 UUID 防止計時器互蓋：

```swift
@State private var heroDamageFlash:    Int?   = nil
@State private var enemyDamageFlash:   Int?   = nil
@State private var heroDamageFlashID:  UUID   = UUID()
@State private var enemyDamageFlashID: UUID   = UUID()
```

將 `hpBarsView` 替換為 `battleVisualsView`，改為左右對峙版面：

```
┌──────────────────────────────────────────────────┐
│  [person.fill]  英雄       ⚔️       敵名  [佔位] │
│  HP ████████░░                   HP ░░████████   │
│  ATB ████░░░░                   ATB ░░░░░░░░██   │
└──────────────────────────────────────────────────┘
```

結構：
```swift
HStack(alignment: .top, spacing: 12) {
    heroColumn          // 左：英雄
    Spacer()
    battleCenterIcon    // 中：圖示（探索 vs 戰鬥切換）
    Spacer()
    enemyColumn         // 右：敵人（含 D 佔位）
}
.padding(.horizontal)
.padding(.vertical, 10)
.background(Color(.systemGroupedBackground))
```

**heroColumn：**
```swift
VStack(alignment: .leading, spacing: 4) {
    HStack(spacing: 4) {
        Image(systemName: "person.fill").foregroundStyle(.blue)
        Text("英雄").font(.caption).fontWeight(.semibold)
    }
    ProgressView(value: Double(max(0, currentHeroHp)), total: Double(max(1, heroMaxHp)))
        .tint(.blue)
        .animation(.easeInOut(duration: 0.2), value: currentHeroHp)
        .overlay(alignment: .trailing) {
            // C：浮動數字用 opacity 動畫（transition 在 overlay 內靜默失效）
            if let dmg = heroDamageFlash {
                Text(dmg < 0 ? "+\(-dmg)" : "-\(dmg)")
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(dmg < 0 ? .green : .red)
                    .padding(.trailing, 4)
            }
        }
    Text("\(max(0, currentHeroHp))/\(heroMaxHp)")
        .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
    ProgressView(value: model.heroATBProgress, total: 1.0)
        .tint(model.isExploring ? .teal : .yellow)
        .animation(.linear(duration: 0.055), value: model.heroATBProgress)
}
.frame(maxWidth: .infinity, alignment: .leading)
```

**battleCenterIcon：**
```swift
Image(systemName: model.isBattleActive ? "figure.fencing" : "map.fill")
    .foregroundStyle(.secondary)
    .font(.caption)
    .padding(.top, 6)
```

**enemyColumn（D：佔位區塊）：**
```swift
VStack(alignment: .trailing, spacing: 4) {
    HStack(spacing: 4) {
        Text(enemyLabel).font(.caption).fontWeight(.semibold)
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 26, height: 26)
            Image(systemName: "skull")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
    ProgressView(value: Double(max(0, currentEnemyHp)), total: Double(max(1, enemyMaxHp)))
        .tint(.red)
        .animation(.easeInOut(duration: 0.2), value: currentEnemyHp)
        .overlay(alignment: .trailing) {
            if let dmg = enemyDamageFlash {
                Text("-\(dmg)")
                    .font(.caption2).fontWeight(.bold).foregroundStyle(.orange)
                    .padding(.trailing, 4)
            }
        }
    Text("\(max(0, currentEnemyHp))/\(enemyMaxHp)")
        .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
    ProgressView(value: model.enemyATBProgress, total: 1.0)
        .tint(.orange)
        .animation(.linear(duration: 0.055), value: model.enemyATBProgress)
}
.frame(maxWidth: .infinity, alignment: .trailing)
.opacity(model.isBattleActive ? 1 : 0)
.animation(.easeInOut(duration: 0.25), value: model.isBattleActive)
```

---

#### C：浮動傷害數字觸發

在 `battleVisualsView` 後方加 `.onChange(of: model.displayedCount)`：

```swift
.onChange(of: model.displayedCount) { _, _ in
    guard let event = model.currentBattleEvents.prefix(model.displayedCount).last else { return }
    switch event.type {
    case .damage where event.damageAmount > 0:
        // 英雄受傷（正數 → 紅色）
        let id = UUID()
        heroDamageFlashID = id
        withAnimation { heroDamageFlash = event.damageAmount }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard heroDamageFlashID == id else { return }
            withAnimation { heroDamageFlash = nil }
        }
    case .attack, .skill where event.damageAmount > 0:
        // 敵人受傷
        let id = UUID()
        enemyDamageFlashID = id
        withAnimation { enemyDamageFlash = event.damageAmount }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard enemyDamageFlashID == id else { return }
            withAnimation { enemyDamageFlash = nil }
        }
    case .heal where event.damageAmount > 0:
        // 英雄回血（負數存入 → overlay 顯示 +X 綠色）
        let id = UUID()
        heroDamageFlashID = id
        withAnimation { heroDamageFlash = -(event.damageAmount) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard heroDamageFlashID == id else { return }
            withAnimation { heroDamageFlash = nil }
        }
    default: break
    }
}
```

> **風險修正：** 每次觸發產生新的 `UUID`，asyncAfter 執行時先驗證 ID 一致才清空，避免快速連發時計時器互蓋。

---

#### B：關鍵事件視覺突出

新增 `isHighlightedEvent()` 判斷：

```swift
private func isHighlightedEvent(_ event: BattleEvent) -> Bool {
    switch event.type {
    case .skill, .victory, .defeat, .encounter: return true
    case .attack: return event.isCrit
    default: return false
    }
}
```

修改 `eventRow()`，突出事件加背景色 + 粗體：

```swift
private func eventRow(_ event: BattleEvent) -> some View {
    let highlight = isHighlightedEvent(event)
    return HStack(alignment: .top, spacing: 8) {
        eventIconView(event.type)
            .frame(width: highlight ? 18 : 16, height: highlight ? 18 : 16)
            .padding(.top, 2)
        Text(event.description)
            .font(highlight ? .subheadline.weight(.semibold) : .subheadline)
            .foregroundStyle(eventColor(event.type))
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, highlight ? 8 : 0)
    .padding(.vertical, highlight ? 4 : 0)
    .background(highlight ? eventColor(event.type).opacity(0.08) : .clear)
    .clipShape(RoundedRectangle(cornerRadius: 6))
}
```

---

## 不動的部分

- `skillCooldownPanel`：結構不變，位置不變
- `eliteResultView`：不動
- `eventColor()` / `eventIconView()`：不動
- `BattleLogPlaybackModel`：不需要修改
- `hpBar()` / `atbBar()` helper 函式：不再使用，可刪除

---

## 修改檔案

- `Views/BattleLogSheet.swift`

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 英雄 / 敵人改為左右對峙版面
- [ ] 敵人區右上方有圓角灰色佔位框 + skull icon
- [ ] 探索階段敵人欄位隱藏（opacity 0），進入戰鬥才顯示
- [ ] 技能觸發 / 暴擊 / 勝敗 / 遭遇 log 行有淡色背景 + 粗體
- [ ] 英雄受傷時 HP 條上短暫顯示 `-X`（紅色）
- [ ] 敵人受傷時 HP 條上短暫顯示 `-X`（橙色）
- [ ] 英雄回血時顯示 `+X`（綠色）
- [ ] 浮動數字約 0.9 秒後淡出
- [ ] 快速連續受傷時，計時器不互蓋（舊數字不提早清掉新數字）
