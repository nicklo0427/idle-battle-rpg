# CLAUDE.md — AI 協作說明文件

> 生活空檔放置 RPG，本地單機 iOS App。MVP 核心循環已完成（V1–V3），目前進入 V4 新玩法規劃階段。

---

## 這份文件的用途

這份文件是給 Claude / Claude Code 的專案協作說明。每次開啟新對話時，Claude 應先讀完這份文件，確保對目前開發階段有清楚認識。

**開發進度請見：** `PROGRESS.md`
**歷史 MVP 規格：** `MVP_SPEC_FINAL.md`（已完成，僅供參考）

---

## 專案一句話說明

玩家生活空檔（上班前 / 午休 / 睡前）派英雄去地下城 AFK，NPC 採集素材、打造裝備，純本地單機 iOS App，無後端無社交（後端為長期目標）。

## 目前開發狀態

| 版本 | 狀態 | 內容 |
|---|---|---|
| V1 MVP | ✅ 完成 | 核心循環：採集 / 鑄造 / 出征 / 結算 / 英雄成長 |
| V2-1 | ✅ 完成 | 地下城推進（3 區域 × 4 樓層 × Boss）|
| V2-2 | ✅ 完成 | 裝備強化系統 |
| V2-3 | ✅ 完成 | NPC 效率升級 |
| V2-4 | ✅ 完成 | 商人 V2-1 素材、任務進度條、配方預覽 |
| V2-5 | ✅ 完成 | EXP 升級系統、採集者專精、UI 清理 |
| V3-1 | ✅ 完成 | 玩家累計統計 |
| V3-3 | ✅ 完成 | 裝備比較 Diff |
| V3-4 | ✅ 完成 | Dev 工具修正、採集時長縮放 |
| V4 | 🔲 規劃中 | 見下方「V4 計劃方向」|

---

## Tech Stack

| 項目 | 技術選擇 |
|---|---|
| 語言 | Swift 5.9+ |
| UI | SwiftUI |
| 持久化 | SwiftData (iOS 17+) |
| 網路 | 無（MVP 純本地） |
| 最低系統 | iOS 17.0 |
| 專案管理 | XcodeGen（`project.yml`，`.xcodeproj` 不進 git）|

---

## MVP 規格速查

### 玩家

- 玩家本身即英雄，去地下城冒險
- 屬性：ATK / DEF / HP
- 戰力公式：`ATK × 2 + DEF × 1.5 + HP × 1`
- 裝備欄：武器 / 防具 / 飾品（3 部位）
- 升級：消耗金幣，每級得 3 屬性點，MVP 上限 Lv.10

### NPC

| NPC | 數量 | 功能 |
|---|---|---|
| 採集者 | 2 人 | 選地點 → AFK → 帶回素材 |
| 鑄造師 | 1 人 | 選配方 → AFK → 完成裝備 |
| 商人 | 1 人 | 固定兌換商店（無每日刷新）|

### 素材（5 種）

`木材`（採集）、`礦石`（採集）、`獸皮`（地下城區域1）、`魔晶石`（區域2+）、`古代碎片`（區域3）

### 裝備（3 部位 × 2 稀有度 = 6 種配方）

| 部位 | 主要加成 |
|---|---|
| 武器 | ATK |
| 防具 | DEF + HP |
| 飾品 | 混合屬性 |

稀有度：普通 / 精良。裝備強化延後至 V2。

### 地下城（3 區）

| 區域 | 解鎖門檻 | 主要產出 |
|---|---|---|
| 荒野邊境 | 初始 / 推薦戰力 50 | 獸皮、金幣 |
| 廢棄礦坑 | 戰力 ≥ 150 | 魔晶石、金幣 |
| 深淵遺跡 | 戰力 ≥ 400 | 古代碎片、金幣 |

出征時長：15 分鐘 / 1 小時 / 8 小時（自選）。離線上限：8 小時。

### 勝率公式

```
ratio   = heroStats.power / def.recommendedPower
winRate = clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (ratio - 1)))
```

勝場：全額獎勵。敗場：20% 安慰金幣，無素材。

### 初始狀態

金幣 100、木材 6、礦石 4、破舊短劍 × 1（已裝備）。

### 新手加速（各一次，永久消耗）

- 首件鑄造：30 秒完成（正常需 10–45 分鐘）
- 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥

---

## 資料模型

### 四個 SwiftData @Model

**PlayerStateModel**（單例）
```
gold, heroLevel, availableStatPoints
atkPoints, defPoints, hpPoints
lastOpenedAt: Date
hasUsedFirstCraftBoost: Bool
hasUsedFirstDungeonBoost: Bool
onboardingStep: Int   // 0~3，3 = 完成
```

**MaterialInventoryModel**（單例）
```
wood, ore, hide, crystalShard, ancientFragment: Int
```

**EquipmentModel**（每件一筆）
```
defKey: String        // 對應靜態 EquipmentDef
slot: EquipmentSlot   // .weapon / .armor / .accessory
rarity: Rarity        // .common / .refined
isEquipped: Bool
```

**TaskModel**（進行中 + 待結算）
```
id: UUID
kind: TaskKind             // .gather / .craft / .dungeon
actorKey: String           // "gatherer_1" / "gatherer_2" / "blacksmith" / "player"
definitionKey: String
startedAt: Date
endsAt: Date
durationOverride: Int?     // 新手加速秒數
forcedBattles: Int?        // 首次出征固定 5 場
snapshotPower: Int?        // 出發當下的英雄戰力（.dungeon 用）
status: TaskStatus         // .inProgress / .completed（收下後直接刪除）
resultGold: Int
resultWood: Int
resultOre: Int
resultHide: Int
resultCrystalShard: Int
resultAncientFragment: Int
resultBattlesWon: Int?
resultBattlesLost: Int?
resultCraftedEquipKey: String?
```

> ⚠️ 沒有 `.settled` status。玩家點「收下」後 TaskModel 直接刪除。

### 靜態資料（不進 SwiftData）

純 Swift struct，放在 `StaticData/` 目錄：

`GatherLocationDef` / `CraftRecipeDef` / `DungeonAreaDef` / `EquipmentDef` / `MerchantTradeDef`

---

## 工程分層規則

### 分層架構

```
Views  →  ViewModels  →  Services  →  Models (SwiftData)
                     ↘  StaticData (純 Swift struct)
```

### 各層責任邊界

| 層 | 可以做 | 不可以做 |
|---|---|---|
| Views | 讀 ViewModel 資料、呼叫 ViewModel 方法 | 直接讀 Model、直接呼叫 Service |
| ViewModels | 組合 Service 資料、管理 UI 狀態 | 寫入 SwiftData、執行業務邏輯計算 |
| Services | 讀寫 SwiftData、業務邏輯計算 | 管理 UI 狀態 |
| Models | 持有資料 | 包含任何邏輯 |

### AppState 責任（嚴格限縮）

AppState 只做：
- ScenePhase 監聽 → 觸發 `SettlementService.scanAndSettle()`
- 前台 Timer（1 秒），ViewModel 訂閱 tick
- `shouldShowSettlement: Bool` + `pendingSettlementTasks`
- 持有所有 Services（注入點）

AppState **不存**：金幣、素材、英雄戰力或任何遊戲狀態。這些從 SwiftData 即時查詢。

### ModelContext 注入方式

**方案 A（已確認）：建構子注入**
Services 在初始化時接受 `ModelContext` 作為建構子參數。AppState 在 SwiftUI View 樹內建立所有 Services，此時可取得 `@Environment(\.modelContext)`。

### Service 三分（TaskService 拆為三個獨立檔案）

1. **`TaskRepository.swift`** — 薄層 CRUD，只管 TaskModel 的查詢與寫入
2. **`TaskCreationService.swift`** — 建立三種任務（含前置驗證、扣素材/金幣）
3. **`SettlementService.swift`** — `scanAndSettle()` + `commitResults()`，Service 內部直接寫入

### SettlementViewModel（最薄）

只做 UI 資料轉換。不含任何計算邏輯或 RNG。

### HeroStatsService + DungeonSettlementEngine

純計算層，無副作用，**完全不需要 ModelContext**。可以在沒有 SwiftUI 環境下進行單元測試。

---

## 確定性 RNG

```swift
seed = UInt64(task.startedAt.timeIntervalSinceReferenceDate)
     ^ UInt64(bitPattern: task.id.hashValue)
rng  = SeededRNG(seed: seed)  // LCG 演算法
```

相同輸入永遠產生相同輸出。結算在 App 回前台時用 seed 重算，不預先存結果。

---

## V4 計劃方向

以下是確認納入 V4 的功能，按優先順序排列。詳細 tickets 待規劃。

### 優先 1 — 戰鬥文字記錄（A2a）
結算時用相同 deterministic seed 重新生成每場戰鬥的事件描述：
> 「進入廢棄礦坑第三層 → 遭遇礦穴巨魔 → 發動斬擊 → 造成 42 傷害 → 受到 18 傷害 → 勝利」

- 只在玩家點「查看過程」時生成，不持久儲存
- 新增 `BattleLogGenerator`（純計算，無副作用）
- UI：任務完成後可展開「戰鬥記錄」Sheet

### 優先 2 — 採集文字記錄（A3）
採集結算時依地點、素材類型生成探索描述：
> 「進入森林深處 → 發現古老橡樹叢 → 費力砍伐 → 獲得 6 木材」

- 同樣只在查看時生成
- 新增 `GatherLogGenerator`

### 優先 3 — 解鎖門檻強化（A1）
目前靠機率即可堆量通關。改為「首通需達到最低戰力門檻」：
- `TaskCreationService` 新增戰力驗證
- `FloorDetailSheet` 顯示「戰力不足，無法首通」提示

### 優先 4 — 更多等級 / 地下城（A5）
- 英雄等級上限：10 → 20
- 增加地下城區域或樓層深度

### 優先 5 — 成就系統（C）
給玩家明確的長期目標：
- 靜態定義成就列表（`AchievementDef`）
- `AchievementService` 在各結算點檢查觸發
- 角色頁新增「成就」Tab segment

### 優先 6 — 視覺強化（D）
- 各地下城區域差異化色調（荒野橙 / 礦坑藍灰 / 遺跡紫）
- SF Symbols 動畫（進行中任務呼吸效果）
- 精良裝備金色邊框

### 後排 — 技能 / 天賦系統（A2b）
大型系統，需獨立規劃，影響戰鬥計算全面重構。

### 後排 — 社交功能（B）
組隊 / 工會 / 聊天 / 季節活動，全部需要後端，另立版本規劃。

---

## 絕對不做的事（後端版本再說）

- ❌ 後端 API / 伺服器（長期目標，先做好本地版）
- ❌ Apple Sign In / 帳號系統
- ❌ 組隊 / 工會 / 聊天（需後端）
- ❌ 季節性 / 節日活動（需後端）
- ❌ 第二貨幣（鑽石 / 寶石）
- ❌ 推播通知
- ❌ 商人每日刷新
- ❌ 多件鑄造佇列
- ❌ 提早從地下城召回（含懲罰機制）
- ❌ 超過 3 個 Tab
- ❌ 任何需要 Internet 的功能
- ❌ Claude AI 文字生成

---

## 商人套利防護

固定商店，單向不對稱設計，無每日次數限制：

```
素材 → 金幣（出售多餘素材）
金幣 → 稀有素材（高單價補給）
```

不設計「素材 ↔ 素材」的雙向兌換，避免套利循環。

---

## lastOpenedAt 更新順序

```
正確：
  1. 讀取 lastOpenedAt → 計算結算
  2. 結算完成後 → 更新 lastOpenedAt = now

錯誤（避免）：
  先更新 → 再計算（離線時長會變成 0）
```

---

## 鑄造任務特殊規則

鑄造是唯一「建立時就知道結果」的任務：
- `resultCraftedEquipKey` 在建立時直接寫入（不需 RNG）
- 素材和金幣在**建立時立即扣除**（不是入帳時才扣）
- 扣除 + 建立 TaskModel 必須原子完成（用同一個 ModelContext.save()）

---

## 首次出征保底

```
if forcedBattles == 5（首次出征）：
  正常跑 5 場 RNG（不強制前幾場勝）
  保底：if resultGold == 0 → resultGold = def.goldPerBattleRange.lowerBound
  目的：確保第一次結算至少有金幣，而非保證勝場
```

---

## 給 Claude 的行為原則

1. **先查 PROGRESS.md**：了解目前完成了什麼，避免重複實作
2. **遵守分層架構**：不要跳過 Service 層直接在 View 寫邏輯
3. **計算核心純化**：任何涉及結算的計算必須用確定性 RNG，不預存結果
4. **不要動 AppState 邊界**：AppState 不存遊戲狀態，有疑問就從 SwiftData 查
5. **SettlementViewModel 保持最薄**：只做 UI 轉換，計算邏輯一律在 Service 層
6. **靜態資料用 Swift struct**：不要把 StaticData 放進 SwiftData
7. **看到「加後端 / 網路」就停下來**：目前版本純本地，後端是獨立版本的事
8. **新功能先寫 ticket 再實作**：見 `tickets/` 目錄格式
