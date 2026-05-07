# V10-1 Ticket 04：NPC 首次對話 + NPC 命名

**狀態：** ✅ 已完成

**依賴：** 無

---

## 目標

玩家第一次開啟 NPC Sheet 時，顯示該 NPC 的首次台詞，讓每個 NPC 有自己的個性。台詞結束後，讓玩家為 NPC 取一個自訂名字（可跳過）。

---

## 觸發條件

- Sheet 頂部顯示台詞氣泡
- 條件：`!player.seenNpcIntroKeys.contains(actorKey)`
- 「明白了」按鈕關閉後展示命名輸入（inline，非 Alert）
- 完成後：`seenNpcIntroKeys` 加入該 actorKey

---

## NPC 台詞與預設名

| actorKey | 預設名 | 首次台詞 |
|---------|--------|--------|
| `gatherer_1` | 石頭 | 嘿，你終於醒了。是我在森林邊緣找到你的——半埋在廢石裡，差點沒認出是個人。叫我石頭就好，需要採集，找我。 |
| `gatherer_2` | 二毛 | 哦，廢墟撿回來的？我是採集者，跑腿的活交給我。不用謝，反正我閒著也是閒著。 |
| `gatherer_3` | 藥草婆 | 這些草藥我認識，你身上的傷多虧了它們才好得快。我採草藥採了幾十年，叫我藥草婆就好。 |
| `gatherer_4` | 魚仔 | 嗯，你醒了啊。我一天到晚在溪邊，魚比人好說話。需要魚就找我，不需要也沒關係。 |
| `farmer` | 老農 | 孩子，你算是命大。我在這片土地耕種了大半輩子，見過不少倒在荒野的人，能活著醒來的沒幾個。 |
| `blacksmith` | 老鐵 | 嗯，你的劍我看過了，再打幾場就廢了。我是鑄造師，什麼料到我手上都能變成裝備。把素材給我，我替你打。 |
| `chef` | 阿廚 | 哎，坐下來！你剛醒，第一件事就該好好吃一頓。上陣前帶些料理——肚子飽，手才穩。 |
| `pharmacist` | 藥師 | 讓我看看。傷口恢復不錯，體質不差。進地下城前來備藥，沒有人只靠意志力撐過深層的。 |
| `merchant` | 魚商 | 大難不死的傢伙！我就說嘛，撿回來的准是人物。什麼都賣什麼都收，素材換金幣，最實在。 |

---

## UX 流程

```
玩家開啟 NPC Sheet
  ↓
Sheet 頂部顯示台詞氣泡（非 Alert，不阻擋下方內容）
  ↓
點「明白了」
  ↓
台詞縮小，顯示「幫他取個名字吧」TextField + 「確認」/「跳過」
  ↓
確認 → 存 NPC 名字
跳過 → 保留預設名
  ↓
對話區塊消失，seenNpcIntroKeys 加入該 actorKey
```

---

## NPC 名字顯示位置

- `BaseView` NPC row / 卡片標題：`player.npcDisplayName(for: actorKey)`
- 各 NPC Sheet `navigationTitle`：同上
- `npcDisplayName(for:)` 邏輯：有自訂名優先，否則用 `NpcIntroDef.defaultName`

---

## 新增檔案

### `StaticData/NpcIntroDef.swift`

```swift
struct NpcIntroDef {
    let actorKey: String
    let defaultName: String
    let introLine: String

    static let all: [NpcIntroDef] = [ /* 9 個 NPC */ ]
    static func find(actorKey: String) -> NpcIntroDef? { ... }
}
```

### `Views/NpcIntroSection.swift`

可重用的 SwiftUI View，嵌入 NPC Sheet 的 List 作為第一個 Section：

```swift
struct NpcIntroSection: View {
    let actorKey: String
    // @Query players, @Environment context
    // @State showNaming, nameInput, @FocusState nameFocused

    var body: some View {
        // 條件顯示：尚未看過首次對話
        // Section 1：台詞氣泡 + 「明白了」
        // Section 2（showNaming）：TextField + 確認/跳過
    }
}
```

---

## 修改檔案

### `Models/PlayerStateModel.swift`

```swift
var seenNpcIntroKeysRaw: String = ""    // 逗號分隔 actorKey
var npcNamesRaw: String = ""            // "actorKey:名字,actorKey:名字"
```

Extension 便利方法：
- `seenNpcIntroKeys: [String]`
- `markNpcIntroSeen(for actorKey:)`
- `customNpcName(for actorKey:) -> String?`
- `setCustomNpcName(_ name: String, for actorKey:)`
- `npcDisplayName(for actorKey:) -> String`

### 各 NPC Sheet（共 6 個）

在 `List { ... }` 第一個位置加入：

```swift
NpcIntroSection(actorKey: "gatherer_1")  // 各自對應 actorKey
```

`navigationTitle` 改用：

```swift
.navigationTitle(player?.npcDisplayName(for: actorKey) ?? fallbackName)
```

涉及檔案：
- `Views/GathererDetailSheet.swift`
- `Views/CraftSheet.swift`
- `Views/CuisineSheet.swift`
- `Views/PharmacySheet.swift`
- `Views/FarmerDetailSheet.swift`
- `Views/MerchantSheet.swift`

### `Views/BaseView.swift`

NPC 卡片 / Row 名稱文字改用 `player?.npcDisplayName(for: actorKey) ?? fallback`

---

## 驗證

1. 第一次點採集者 Sheet → 顯示台詞 → 命名 → 下次再開不再顯示台詞
2. 命名後 BaseView NPC 名稱更新
3. 命名後 Sheet navigationTitle 更新
4. 跳過命名 → 保留預設名（如「石頭」）
5. 所有 9 個 NPC 均有首次台詞
