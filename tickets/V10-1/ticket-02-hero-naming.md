# V10-1 Ticket 02：英雄命名

**狀態：** ✅ 已完成

**依賴：** T01（接在開場敘事後顯示）

---

## 目標

讓玩家在進入職業選擇前，為自己的英雄取一個名字，增加代入感。

---

## 設計

**觸發：** T01 敘事卡完成後，或 `hasSeenIntro == true && heroName` 尚未設定時

**UI 規格：**
- 全屏黑色背景（與 T01 風格連貫）
- SF Symbol：`person.fill.questionmark`
- 標題：「你叫什麼名字？」
- TextField（最大 12 字）
- Placeholder：「冒險者」
- 確認按鈕：「確定，出發」
- 小字提示：「（可留空，預設顯示冒險者）」
- 可跳過（留空直接確認）

**完成後：** 存 `heroName`，進入 `ClassSelectionView`

---

## 英雄名顯示位置

- `CharacterView` 英雄屬性 Section 標題：`"\(displayName) · 英雄屬性"`
  - `let displayName = player.heroName.isEmpty ? "冒險者" : player.heroName`

---

## 新增檔案

### `Views/HeroNameView.swift`

```swift
struct HeroNameView: View {
    var onFinished: () -> Void
    @State private var nameInput = ""
    // TextField（.focused）+ 確認按鈕
    // 完成：player.heroName = nameInput.trimmingCharacters(...)，context.save()，onFinished()
}
```

---

## 修改檔案

### `Models/PlayerStateModel.swift`

```swift
var heroName: String = ""
```

### `Views/CharacterView.swift`

英雄屬性 Section header 顯示英雄名：

```swift
let displayName = player.heroName.isEmpty ? "冒險者" : player.heroName
// Section header: "\(displayName) · 英雄屬性"
```

---

## 驗證

1. 完成 T01 敘事卡 → 進入命名畫面
2. 填入名字確認 → CharacterView 顯示該名字
3. 留空確認 → CharacterView 顯示「冒險者」
4. 命名後進入 ClassSelectionView
