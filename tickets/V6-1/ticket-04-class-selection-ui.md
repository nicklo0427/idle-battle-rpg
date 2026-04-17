# V6-1 Ticket 04：職業選擇畫面

**狀態：** 🔲 待實作
**版本：** V6-1 Phase 1
**依賴：** T01, T02

---

## 目標

遊戲啟動時，若玩家尚未選擇職業（`classKey == ""`），顯示全螢幕職業選擇畫面，強制選擇後才能進入遊戲。

---

## 新建檔案

### `Views/ClassSelectionView.swift`

版面佈局（2 × 2 職業卡片網格）：

```
┌──────────────────────────────────┐
│         選擇你的職業               │
│  踏上冒險前，選擇你的英雄路線。     │
│  一旦選定，不可更換。              │
├──────────────────────────────────┤
│  ┌────────┐  ┌────────┐          │
│  │  劍士  │  │  弓手  │          │
│  │  紅色  │  │  綠色  │          │
│  │ATK +5  │  │AGI +3  │          │
│  │        │  │DEX +2  │          │
│  └────────┘  └────────┘          │
│  ┌────────┐  ┌────────┐          │
│  │  法師  │  │ 聖騎士 │          │
│  │  紫色  │  │  藍色  │          │
│  │ATK +3  │  │DEF +4  │          │
│  │AGI +2  │  │HP  +15 │          │
│  └────────┘  └────────┘          │
└──────────────────────────────────┘
```

每個職業卡片顯示：
- SF Symbol 圖示（`classDef.iconName`）+ 主題色（`classDef.themeColor`）
- 職業名稱（粗體大字）
- 職業簡介（1 行次要文字）
- 基礎加成列表（小字，只顯示非零加成，例如「ATK +5」）

點擊卡片流程：
1. 顯示確認 Alert：「確定選擇[職業名]嗎？\n選定後不可更換。」
2. 玩家確認 → `player.classKey = classDef.key`、`try? context.save()`
3. `fullScreenCover` 自動 dismiss（由 binding 觸發）

```swift
// 基礎加成輔助函式（只顯示非零項目）
private func bonusLines(for classDef: ClassDef) -> [String] {
    var lines: [String] = []
    if classDef.baseATKBonus > 0 { lines.append("ATK +\(classDef.baseATKBonus)") }
    if classDef.baseDEFBonus > 0 { lines.append("DEF +\(classDef.baseDEFBonus)") }
    if classDef.baseHPBonus  > 0 { lines.append("HP +\(classDef.baseHPBonus)")  }
    if classDef.baseAGIBonus > 0 { lines.append("AGI +\(classDef.baseAGIBonus)") }
    if classDef.baseDEXBonus > 0 { lines.append("DEX +\(classDef.baseDEXBonus)") }
    return lines
}
```

---

## 修改檔案

### `Views/BaseView.swift`

在 `body` 最外層（`NavigationStack` 外）加入 `.fullScreenCover`：

```swift
.fullScreenCover(isPresented: Binding(
    get: { players.first?.classKey.isEmpty == true },
    set: { _ in }   // 不允許外部關閉，必須選職業
)) {
    ClassSelectionView()
}
```

注意：
- `ClassSelectionView` 透過 `@Environment(\.modelContext)` 取得 context，由 `ModelContainer` 自動傳遞
- Binding 的 `set` 為空，確保玩家無法透過手勢關閉畫面
- 職業確認後更新 `classKey`，`get` 條件變為 `false`，`fullScreenCover` 自動關閉

---

## 設計決策

| 決策 | 說明 |
|---|---|
| `fullScreenCover` 而非 `sheet` | 強制選擇，不允許滑動關閉 |
| 無「跳過」按鈕 | 職業是核心身份，必須選擇才能遊玩 |
| 確認 Alert | 避免誤觸，強調「不可更換」 |
| 舊存檔自動觸發 | `classKey = ""` 時自動顯示，無縫升級 |

---

## 驗收標準

- [ ] 新遊戲：啟動後顯示職業選擇全螢幕畫面，無法關閉（無「跳過」按鈕）
- [ ] 4 個職業卡片顯示正確（名稱、加成、圖示顏色）
- [ ] 點擊職業 → 顯示確認 Alert → 確認後記錄職業、畫面關閉
- [ ] 舊存檔（`classKey = ""`）也觸發選擇畫面
- [ ] 已有職業的存檔不顯示選擇畫面
- [ ] Build 通過
