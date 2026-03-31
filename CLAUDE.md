# CLAUDE.md — AI 協作說明文件

> 生活空檔放置 RPG，MVP 是純本地單機。嚴守規格，不擴充，先讓核心循環跑通。

---

## 這份文件的用途

這份文件是給 Claude / Claude Code 的專案協作說明。每次開啟新對話時，Claude 應先讀完這份文件，確保對 MVP 邊界有清楚認識，不自行擴展功能需求。

**完整規格請見：** `MVP_SPEC_FINAL.md`（本文件為濃縮版 + 約束清單）

---

## 專案一句話說明

玩家生活空檔（上班前 / 午休 / 睡前）派英雄去地下城 AFK，NPC 採集素材、打造裝備，純本地單機 iOS App，MVP 無後端無社交。

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

## 實作優先順序（20 步）

**Phase 1 — 計算核心（可先寫單元測試）**
1. StaticData 全部定義
2. 四個 SwiftData @Model
3. HeroStatsService（純計算）
4. DungeonSettlementEngine（確定性 RNG + 單元測試）

**Phase 2 — 任務生命週期**
5. TaskRepository（薄層 CRUD）
6. TaskCreationService（建立三種任務）
7. SettlementService（scanAndSettle + commitResults）
8. EquipmentService（薄版）

**Phase 3 — 全域協調**
9. AppState（ScenePhase + Timer + Settlement 觸發）
10. SettlementViewModel（只做 UI 轉換）

**Phase 4 — ViewModels + Views**
11. 總結算 Modal（優先完成，驗證結算流程）
12. BaseViewModel + 基地 Tab + 採集 Sheet + 鑄造 Sheet
13. AdventureViewModel + 冒險 Tab
14. CharacterViewModel + 角色 Tab（裝備 + 背包 Segment）

**Phase 5 — P0.5（first-session 收尾）**
15. Onboarding highlight（3 步驟）
16. 首次加速說明文字（鑄造 + 出征）
17. 採集 / 鑄造完成小通知

**Phase 6 — P1**
18. MerchantService + 商店 Sheet
19. 數值平衡調整（靜態資料微調）
20. 整體測試與 TestFlight 準備

---

## 絕對不做的事（V2 以後再說）

- ❌ 後端 API / 伺服器
- ❌ Apple Sign In / 帳號系統
- ❌ 好友 / 非同步組隊
- ❌ 裝備強化系統
- ❌ NPC 升級 / 招募更多 NPC
- ❌ 第二貨幣（鑽石 / 寶石）
- ❌ 推播通知
- ❌ 商人每日刷新
- ❌ 多件鑄造佇列
- ❌ 提早從地下城召回（含懲罰機制）
- ❌ 超過 3 個 Tab
- ❌ 任何需要 Internet 的功能
- ❌ 第二種主要貨幣
- ❌ Claude AI 文字生成（舊設計殘留，本版本不使用）

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

1. **嚴守規格**：有疑問時先查 `MVP_SPEC_FINAL.md`，不自行擴充功能
2. **先做 Phase 1 再做 Phase 4**：不要跳過 Service 層直接寫 View
3. **計算核心最優先**：`HeroStatsService` 和 `DungeonSettlementEngine` 是最容易測試的，先寫好
4. **優先用確定性**：任何涉及結算的計算必須用確定性 RNG
5. **不要動 AppState 邊界**：AppState 不存遊戲狀態，有疑問就從 SwiftData 查
6. **SettlementViewModel 保持最薄**：只做 UI 轉換，計算邏輯一律在 Service 層
7. **靜態資料用 Swift struct**：不要把 StaticData 放進 SwiftData
8. **看到「加後端」就停下來**：MVP 是純本地，後端是 V2 的事
