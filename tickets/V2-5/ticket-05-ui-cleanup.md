# V2-5 Ticket 05：UI 清理（首頁移除素材庫存、角色頁移除空白列）

**狀態：** ✅ 完成

**依賴：** 無

---

## 問題描述

### 問題一：首頁顯示素材庫存（不需要）

`BaseView` 有一個 `Section("素材庫存")` 列出所有素材數量。
素材已可在角色頁「背包」Segment 查看，首頁不需要重複顯示。

### 問題二：角色頁「英雄屬性」Section 有空白列

`CharacterView.gearSegment` 的英雄屬性 Section 結構如下：

```
等級 row
金幣 row
Divider()     ← 在 List 內渲染成空白列（金幣下方）
戰力 row
Divider()     ← 在 List 內渲染成空白列（戰力下方）
ATK row
DEF row
HP row
```

SwiftUI `List` 內的 `Divider()` 會作為獨立 row 渲染，視覺上是一條沒有任何文字的空白列。

---

## 修改一：BaseView — 移除素材庫存 Section

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

移除整個 `Section("素材庫存")` 區塊（約 18 行）：

```swift
// 刪除以下整段
Section("素材庫存") {
    if let inv = inventories.first {
        ForEach(MaterialType.allCases, id: \.self) { mat in
            let amount = inv.amount(of: mat)
            HStack {
                Text("\(mat.icon) \(mat.displayName)")
                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                Spacer()
                Text("\(amount)")
                    .fontWeight(amount > 0 ? .semibold : .regular)
                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                    .monospacedDigit()
            }
        }
    } else {
        Text("⚠️ 尚無素材資料").foregroundStyle(.red)
    }
}
```

移除後，`@Query private var inventories` 若僅供素材庫存 Section 使用則可一併移除；
但若其他地方（如 Alert 費用顯示）仍用到，需保留。

> 注意：`inventories` 在 `BaseView` 的 Alert 費用計算（持有量顯示）仍有使用，保留 `@Query` 宣告。

---

## 修改二：CharacterView — 移除兩個 Divider()

**檔案：** `IdleBattleRPG/Views/CharacterView.swift`

在 `gearSegment` 的英雄屬性 Section 內，移除兩個作為 List row 的 `Divider()`：

```swift
// 改前
if let stats = heroStats {
    Divider()           // ← 刪除
    powerRow(stats.power)
    Divider()           // ← 刪除
    if let player {
        ...
    }
}

// 改後
if let stats = heroStats {
    powerRow(stats.power)
    if let player {
        ...
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/BaseView.swift` | ✏️ 刪除 `Section("素材庫存")` 區塊 |
| `Views/CharacterView.swift` | ✏️ 刪除 gearSegment 內兩個 `Divider()` |

---

## 驗收標準

- [ ] 首頁（基地）不再顯示素材庫存 Section
- [ ] 角色頁「英雄屬性」Section：金幣列與戰力列之間無空白列，戰力列與 ATK 列之間無空白列
- [ ] Build 無錯誤
