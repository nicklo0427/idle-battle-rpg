# V10-1：新手敘事體驗 + 命名系統

**主題：** 在不干擾核心 loop 的前提下，加入輕量的敘事層與命名系統，讓新玩家了解世界觀、角色背景與 NPC 關係。

**世界觀：** 玩家是從廢墟中甦醒的冒險者，被 NPC 群救回邊境要塞，需要重新站起來面對地下城的威脅。

**依賴：** 無外部依賴，純本地邏輯

---

## 觸發流程

```
開啟 App（新玩家）
  → hasSeenIntro == false？
      ↓
  IntroNarrativeView（3 張敘事卡，可跳過）    ← T01
      ↓
  HeroNameView（英雄命名，可跳過）             ← T02
      ↓
  classKey.isEmpty？
      ↓
  ClassSelectionView（含職業背景故事）          ← T03 + T05
      ↓
  基地頁
      第一次點擊 NPC → NPC 首次對話 → 命名    ← T04
```

**舊存檔升級：** `hasSeenIntro` 在 DatabaseSeeder migration guard 中對 classKey 非空的存檔設為 `true`，舊玩家不會看到開場。

---

## Ticket 清單

| # | 票號 | 標題 | 狀態 |
|---|---|---|---|
| 1 | T01 | 開場敘事屏 | ✅ 已完成 |
| 2 | T02 | 英雄命名 | ✅ 已完成 |
| 3 | T03 | 職業選擇背景故事 | ✅ 已完成 |
| 4 | T04 | NPC 首次對話 + NPC 命名 | ✅ 已完成 |
| 5 | T05 | 職業初始裝備 | ✅ 已完成 |

---

## 新增 PlayerStateModel 欄位

```swift
var hasSeenIntro: Bool = false          // 是否已看過開場敘事
var heroName: String = ""               // 英雄名字（空字串顯示「冒險者」）
var seenNpcIntroKeysRaw: String = ""    // 已看過首次對話的 NPC，逗號分隔 actorKey
var npcNamesRaw: String = ""            // NPC 自訂名字，格式 "actorKey:名字,..."
```

---

## 修改檔案總覽

| 檔案 | 涉及 Tickets |
|---|---|
| `Models/PlayerStateModel.swift` | T01、T02、T04（新增欄位 + extension） |
| `Models/DatabaseSeeder.swift` | T01、T05（migration guard + seedStartingEquipment 守門） |
| `StaticData/ClassDef.swift` | T03、T05（backstory + starterEquipmentKeys） |
| `StaticData/EquipmentDef.swift` | T05（rusty 初始裝備定義） |
| `StaticData/NpcIntroDef.swift` | T04（新增，NPC 台詞 + 預設名） |
| `Services/EquipmentService.swift` | T05（grantStarterEquipment） |
| `ContentView.swift` | T01、T02（新手流程閘門） |
| `Views/NewPlayerFlowView.swift` | T01、T02（新增，流程容器） |
| `Views/IntroNarrativeView.swift` | T01（新增，3 張敘事卡） |
| `Views/HeroNameView.swift` | T02（新增，英雄命名畫面） |
| `Views/ClassSelectionView.swift` | T03、T05（backstory + grantStarterEquipment） |
| `Views/NpcIntroSection.swift` | T04（新增，可重用 NPC 首次對話元件） |
| `Views/BaseView.swift` | T04（NPC row 改用 npcDisplayName） |
| `Views/CharacterView.swift` | T02（英雄名顯示） |
| `Views/GathererDetailSheet.swift` | T04（加 NpcIntroSection） |
| `Views/CraftSheet.swift` | T04（加 NpcIntroSection） |
| `Views/CuisineSheet.swift` | T04（加 NpcIntroSection） |
| `Views/PharmacySheet.swift` | T04（加 NpcIntroSection） |
| `Views/FarmerDetailSheet.swift` | T04（加 NpcIntroSection） |
| `Views/MerchantSheet.swift` | T04（加 NpcIntroSection） |
