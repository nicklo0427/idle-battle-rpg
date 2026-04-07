# PROGRESS.md — 開發進度紀錄

> 生活空檔放置 RPG，MVP 純本地單機 iOS App。
> 本文件記錄各 Phase 完成了什麼、做了哪些決策，以及下一步。

---

## Phase 1 — 資料地基（已完成）

**目標：** 建立 SwiftData 模型與靜態資料，確認資料可正常讀寫。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Models/PlayerStateModel.swift` | 玩家狀態單例（金幣、等級、屬性點、onboarding） |
| `Models/MaterialInventoryModel.swift` | 素材庫存單例（5 種素材） |
| `Models/EquipmentModel.swift` | 裝備個體（defKey + isEquipped） |
| `Models/TaskModel.swift` | 統一任務模型（gather / craft / dungeon） |
| `Models/HeroStats.swift` | 英雄屬性 value type（含戰力公式 / 勝率公式） |
| `Models/DatabaseSeeder.swift` | 首次啟動初始化（玩家 100 金幣、木材 6、礦石 4、破舊短劍） |
| `StaticData/MaterialType.swift` | 5 種素材靜態定義 |
| `StaticData/EquipmentDef.swift` | 7 種裝備定義（含稀有度、部位、加成） |
| `StaticData/GatherLocationDef.swift` | 2 個採集地點（森林 / 礦坑） |
| `StaticData/CraftRecipeDef.swift` | 6 種鑄造配方（3 部位 × 2 稀有度） |
| `StaticData/DungeonAreaDef.swift` | 3 個地下城區域（含解鎖門檻 / 掉落表） |
| `StaticData/MerchantTradeDef.swift` | 商人兌換定義（4 賣出 + 1 買入） |
| `AppConstants.swift` | 所有遊戲常數（初始值、時長、升級費用等） |
| `ContentView.swift` | Phase 1 驗證頁（確認 seeding 與讀寫正常） |

### 關鍵決策
- SwiftData `@Model` 四個，靜態資料用純 Swift struct（不進 DB）
- `HeroStats` 是 value type，每次現算，不存 DB
- `DatabaseSeeder` 在 App 啟動時幂等執行（已存在則跳過）

---

## Phase 2 — Service 層與英雄戰力聚合（已完成）

**目標：** 建立最小 Service 分層，View 不再直接操作 ModelContext 寫入。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/HeroStatsService.swift` | 純計算層（無副作用）；`compute(player:equipped:)` 可單元測試 |
| `Services/PlayerStateService.swift` | PlayerStateModel 查詢入口 |
| `Services/EquipmentService.swift` | 裝備讀取 / 部位互斥裝備切換 |
| `Services/TaskRepository.swift` | TaskModel 薄層 CRUD（fetchAll / fetchInProgress / fetchCompleted） |
| `Services/TaskCreationService.swift` | 採集任務建立（驗證地點 + 填入欄位） |
| `ViewModels/PhaseValidationViewModel.swift` | 驗證頁最薄 ViewModel（Phase 4 後棄用） |
| `Models/DatabaseSeeder.swift` | ✏️ 修改：三個 sub-seeder 改為統一一次 `save()`，避免部分寫入 |
| `ContentView.swift` | ✏️ 修改：移除直接寫入，改走 ViewModel |

### 關鍵決策
- `HeroStatsService.compute()` 是靜態純函式，`fetchAndCompute(context:)` 是便利包裝
- `DatabaseSeeder` 改為統一 save：三個 sub-seeder 只 insert，最後一次 save，確保原子性
- ViewModel 不直接查 SwiftData，接收 View 的 `@Query` 結果做轉換

---

## Phase 3 — 任務完成掃描與離線結算骨架（已完成）

**目標：** 任務第一次形成「建立 → 到期 → 標記 completed」最小閉環。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/SettlementService.swift` | 掃描到期任務，標記 completed（Phase 3 暫不填獎勵） |
| `AppState.swift` | 全域協調層：持有 SettlementService、提供 `scanAndSettle()` |
| `Services/TaskRepository.swift` | ✏️ 修改：新增 `fetchDueTasks(now:)`、`save()` 改為 public |
| `ContentView.swift` | ✏️ 修改：加入 `scenePhase` 監聽，回到前景時自動掃描 |

### 關鍵決策
- `scenePhase` 監聽放在 View（非 AppState），因 `@Environment(\.scenePhase)` 需在 View 樹內
- AppState 不存任何遊戲狀態，金幣 / 素材從 SwiftData 即時查詢
- `scanAndSettle()` 在 `.onAppear` 與 `.onChange(of: scenePhase)` 各呼叫一次

---

## Phase 4 — 正式 Tab 容器與結算顯示骨架（已完成）

**目標：** 從驗證頁轉為正式 app 骨架，三大 Tab 成立。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Views/BaseView.swift` | 基地 Tab（玩家金幣、NPC 任務摘要、開發模式） |
| `Views/AdventureView.swift` | 冒險 Tab（地下城區域列表、解鎖狀態） |
| `Views/CharacterView.swift` | 角色 Tab（英雄屬性、已裝備欄位、背包件數） |
| `Views/SettlementSheet.swift` | 結算 Sheet 骨架（Phase 4：僅顯示筆數） |
| `ViewModels/BaseViewModel.swift` | 任務數量摘要計算 |
| `ViewModels/AdventureViewModel.swift` | 地下城解鎖判斷 |
| `ViewModels/CharacterViewModel.swift` | 英雄屬性聚合（委派 HeroStatsService） |
| `ViewModels/SettlementViewModel.swift` | 結算 UI 資料轉換（含 SettlementSummary） |
| `AppState.swift` | ✏️ 修改：加入 `shouldShowSettlement` / `dismissSettlement()` |
| `ContentView.swift` | ✏️ 修改：正式 TabView 容器 + SettlementSheet 綁定 |

### 關鍵決策
- ViewModel 全部為純計算（接收 @Query 結果做轉換，不直接查 SwiftData）
- AppState 持有 Service 作為注入點，不持有遊戲狀態
- 開發模式區塊移至 BaseView 底部，有 footer 標注「正式版將移除」

---

## Phase 5 — 任務收下與最小獎勵入帳（已完成）

**目標：** MVP 第一次形成真正完整的最小遊戲循環。

```
建立任務 → 到期掃描 → 填入結果 → 標記 completed
    → 顯示結算 Sheet → 玩家收下
    → 入帳（金幣 / 素材 / 裝備）→ 刪除任務
```

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/TaskClaimService.swift` | 收下入口：讀 result* 欄位 → 入帳 → 刪任務 → save |
| `Services/SettlementService.swift` | ✏️ 修改：gather 任務結算時填入採集量（`Int.random(in:)`） |
| `AppState.swift` | ✏️ 修改：持有 TaskClaimService，新增 `claimAllCompleted()` |
| `ViewModels/SettlementViewModel.swift` | ✏️ 修改：`makeRewardLines()` 從 result* 欄位格式化獎勵行 |
| `Views/SettlementSheet.swift` | ✏️ 修改：顯示獎勵明細行，「收下」接線 `claimAllCompleted()` |
| `Views/BaseView.swift` | ✏️ 修改：加入素材庫存 Section（收下後即時驗證入帳） |
| `ContentView.swift` | ✏️ 修改：Sheet binding 拖曳關閉也走 `claimAllCompleted()` |

### 關鍵決策

**責任分工：**
- `SettlementService`：計算結果（填 result* 欄位）+ 標記 completed
- `TaskClaimService`：讀結果 + 入帳 + 刪任務（兩個 Service 各司其職）
- `AppState`：協調兩個 Service，不含業務邏輯
- `SettlementSheet`：透過 `@Query` 讀 completed 任務的 result* 欄位做預覽，不呼叫 Service

**gather 採集量：**
Phase 5 使用 `Int.random(in: def.outputRange)` 填入採集量。
Phase 6+ 替換為確定性 RNG（seed = `startedAt XOR taskId`）。

**Sheet 關閉路徑：**
無論玩家按「收下」按鈕或向下拖曳關閉 Sheet，都會觸發 `claimAllCompleted()`，確保任務不會遺留在 DB 中。

**craft 任務收下：**
`TaskClaimService` 讀取 `resultCraftedEquipKey`，建立 `EquipmentModel` 插入背包（`isEquipped: false`）。裝備已在任務建立時決定，收下只負責實體化。

---

## Phase 6 — NPC 任務建立 UI 與正式任務入口（已完成）

**目標：** 讓玩家可以從正式頁面建立任務，不再只靠開發模式按鈕。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/TaskCreationService.swift` | ✏️ 修改：補上 `createCraftTask` + `createDungeonTask`；採集任務加入採集者忙碌驗證 |
| `ViewModels/BaseViewModel.swift` | ✏️ 修改：新增 NPC 狀態查詢（`gatherTaskForActor`、`craftTask`）、`canAffordRecipe`、任務建立委派方法 |
| `ViewModels/AdventureViewModel.swift` | ✏️ 修改：新增 `dungeonTask`、`currentArea`、`startDungeon` 委派方法 |
| `Views/GatherSheet.swift` | 🆕 新增：採集地點選擇 Sheet（選地點 → 建採集任務 → 自動關閉） |
| `Views/CraftSheet.swift` | 🆕 新增：鑄造配方選擇 Sheet（顯示素材需求 + 可否負擔 + 首件加速提示） |
| `Views/BaseView.swift` | ✏️ 修改：NPC 區塊改為可點擊 NPC row（閒置 → 開 Sheet，忙碌 → 顯示進度）；開發模式明確標示降級 |
| `Views/AdventureView.swift` | ✏️ 修改：地下城卡片加入時長 Chip + 出發按鈕；英雄出征中顯示 Banner + 按鈕 disabled |

### 關鍵決策

**任務建立分層：**
- View 只呼叫 ViewModel 方法，傳入 `ModelContext`（從 `@Environment` 取得）
- ViewModel 收到 context 後建立 `TaskCreationService` 並呼叫，回傳 `Result<Void, TaskCreationError>`
- Service 負責驗證 + 扣資源 + 建立 TaskModel，`repository.insert()` 統一 save（原子性）
- View 依 Result 決定關閉 Sheet 或顯示 Alert

**鑄造任務原子性：**
- 扣除素材 / 金幣 → context 標記 dirty → `repository.insert(task)` 內部呼叫 `context.save()` → 全部一次寫入
- `resultCraftedEquipKey` 在建立時填入，不需 RNG

**首件加速：**
- `createCraftTask`：`hasUsedFirstCraftBoost == false` → `durationOverride = 30`，flag 立即設為 true
- `createDungeonTask`：`hasUsedFirstDungeonBoost == false` 且選 15 分鐘 → `durationOverride = 30`、`forcedBattles = 5`

**地下城時長 Chip：**
- `AdventureView` 持有 `@State private var selectedDurations: [String: Int]`（key = area.key）
- 預設選中 15 分鐘；玩家可在出發前自由切換
- 首次出征加速只在選 15 分鐘時觸發（規格明確）

**NPC row 互動：**
- 閒置 NPC 整個 row 可點擊，`Button` 包裹 `HStack`，`buttonStyle(.plain)` 保持 List 外觀
- 忙碌 NPC row 的 button action 為空（`if !isBusy { onTap() }`）；顯示任務進度 + 標籤

**剩餘時間顯示：**
- Phase 6 為靜態快照（render 時計算一次）；Phase 7+ 補 AppState 1 秒 Timer 驅動動態倒數

**開發模式降級：**
- BaseView 開發模式 Section 標題改為 `⚙️ 開發模式`，footer 明確說明「正式版將移除」
- 正式 NPC 入口在上方，開發模式置底

### 待實作 / 下一步

---

## Phase 7 — 確定性 RNG 與地下城結算正式化（已完成）

**目標：** 將 gather / dungeon 結算從臨時隨機值改為可重現、可驗證的確定性 RNG 流程。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/DeterministicRNG.swift` | 🆕 LCG 種子 RNG；seed = `startedAt.bitPattern XOR taskId.hashValue`；`nextDouble()` / `nextInt(in:)` |
| `Services/DungeonSettlementEngine.swift` | 🆕 純計算層；接收 TaskModel + DungeonAreaDef；計算場次 / 勝率 / 掉落；無副作用可單元測試 |
| `Models/HeroStats.swift` | ✏️ 抽出 `static winRate(power:recommendedPower:)`；公式集中在單一位置；instance method 委派給 static |
| `Services/SettlementService.swift` | ✏️ gather 改為 `DeterministicRNG`（移除 `Int.random`）；dungeon 委派 `DungeonSettlementEngine` |
| `ViewModels/SettlementViewModel.swift` | ✏️ 新增地下城勝敗行「⚔️ 戰鬥 X勝 Y敗」（從 `resultBattlesWon/Lost` 讀取，無計算邏輯）|

### 關鍵決策

**確定性 RNG seed：**
- `startedAt.timeIntervalSinceReferenceDate.bitPattern`（UInt64，保留 IEEE 754 全精度）XOR `UInt64(bitPattern: taskId.hashValue)`
- 選用 `.bitPattern` 而非截整：精度更高，同秒建立的不同任務 seed 仍有差異

**LCG 參數（Knuth）：**
- 乘數 `6364136223846793005`，增量 `1442695040888963407`
- seed=0 時替換為乘數本身，避免全零序列

**勝率公式集中點：**
- `HeroStats.winRate(power:recommendedPower:)` static method 是唯一實作
- `HeroStats.winRate(recommendedPower:)` instance method 委派給 static
- `DungeonAreaDef.winRate(snapshotPower:)` extension 委派給 static
- SettlementService / AdventureViewModel 透過上述入口使用，公式不重複

**地下城場次：**
- `totalBattles = task.forcedBattles ?? max(1, Int(actualDuration / 60))`
- 每 60 秒一場，最少 1 場

**首次出征保底：**
- `forcedBattles != nil`（首次加速觸發）且 `resultGold == 0` → `resultGold = goldMin`
- 目的：確保第一次結算至少有金幣，非保證勝場

**gather 改 RNG：**
- 僅呼叫一次 `rng.nextInt(in: def.outputRange)`，行為與舊版 `Int.random` 相同但可重現

### 待實作 / 下一步

---

## Phase 8 — 角色系統完整化（已完成）

**目標：** 讓 CharacterView 從展示頁變成真正可操作的成長系統（升級 / 分點 / 裝備切換），並確保變動即時影響 HeroStats 與地下城 snapshotPower。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/CharacterProgressionService.swift` | 🆕 升級（金幣驗證 + 等級上限）+ 屬性點分配；純 SwiftData 寫入，無 UI 邏輯 |
| `ViewModels/CharacterViewModel.swift` | ✏️ 新增 `levelUp` / `allocatePoint` / `equip` / `unequip` 委派方法；移除已廢棄 `inventoryCount` |
| `Views/CharacterView.swift` | ✏️ 全面改寫：Segment（裝備 / 背包）、屬性行 +1 按鈕、升級區塊、裝備槽 row（點選 → EquipSelectSheet）、背包列表（點選 → 裝備）、素材庫存 |

### 關鍵決策

**Segment 設計：**
- `裝備` Segment：英雄屬性（含戰力）、升級按鈕、3 個裝備槽
- `背包` Segment：5 種素材庫存 + 未裝備裝備列表
- 預設進入裝備 Segment（與規格一致，不記憶上次狀態）

**屬性點分配 UI：**
- `availableStatPoints > 0` 時，ATK / DEF / HP 行右側顯示 `+` 按鈕（橙色），點擊即分配 1 點
- 無可分配點數時，`+` 按鈕完全隱藏（不佔空間）

**裝備切換流程：**
- 點擊裝備槽 row 整列 → 開啟 `EquipSelectSheet`（同部位未裝備裝備清單）
- 點擊槽 row 右側 `×` → 直接卸除（不開 Sheet）
- `EquipSelectSheet` 定義在 `CharacterView.swift` 內（private struct），不另開檔案

**裝備 → 戰力即時更新：**
- `HeroStatsService.compute(player:equipped:)` 純計算，`@Query` 裝備異動後 View 自動 re-render
- 不需手動觸發，SwiftData `@Query` 觀察已涵蓋

**snapshotPower 對齊：**
- `TaskCreationService.createDungeonTask` 在任務建立時呼叫 `HeroStatsService.fetchAndCompute(context:)`
- 換裝後新建的任務自動拿到新戰力快照；已建立任務的 `snapshotPower` 不受影響

**升級失敗提示：**
- `CharacterProgressionService.levelUp()` 回傳 `Result<Void, LevelUpError>`
- ViewModel 將 error 轉成訊息字串回傳給 View
- View 用 `.alert` 顯示，不在 ViewModel 存 UI 狀態

**`EquipmentSlot: Identifiable` 擴充：**
- `id = rawValue`，讓 `.sheet(item: $equipSheetSlot)` 可直接使用 slot 作為 item

**技術備忘（deterministic seed 穩定性）：**
- 目前 seed 使用 `task.id.hashValue`；Swift 的 `hashValue` 在同一 process 內穩定，但跨啟動可能不同（`SWIFT_DETERMINISTIC_HASHING` 預設關閉）
- 若未來需要跨啟動 / 跨裝置完全穩定，可改為直接解析 UUID bytes（`task.id.uuid` tuple → UInt64）

### 待實作 / 下一步

---

## Phase 9 — 即時狀態同步（1 秒倒數 + 前台自動結算）（已完成）

**目標：** 讓 Base / Adventure 頁的 NPC / 出征倒數從靜態快照變成每秒即時更新，並補上前台任務到期時的自動結算觸發。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/TaskCountdown.swift` | 🆕 共用倒數格式化工具；`≥1h → H:mm:ss`、`<1h → mm:ss`、到期 → "即將完成" |
| `AppState.swift` | ✏️ 新增 `tick: Date`（每秒更新）+ `startForegroundTimer()` / `stopForegroundTimer()`；Timer callback 同時呼叫 `scanAndSettle()`，補抓前台到期任務 |
| `ContentView.swift` | ✏️ `onAppear` 啟動 Timer；`onChange(of: scenePhase)` — `.active` 啟動、`.background/.inactive` 停止 |
| `Views/BaseView.swift` | ✏️ NPC row 剩餘時間改用 `TaskCountdown.remaining(for:relativeTo: appState.tick)`，移除舊靜態 `remainingDisplay()` |
| `Views/AdventureView.swift` | ✏️ 新增 `let appState: AppState` 參數；出征 Banner 倒數改用 `TaskCountdown.remaining(for:relativeTo: appState.tick)`；移除舊靜態 `remainingDisplay()` |

### 關鍵決策

**tick 驅動機制：**
- `AppState.tick: Date` 每秒更新，AppState 是 `@Observable`
- View 讀取 `appState.tick` 即自動訂閱；tick 變動 → View re-render → 倒數字串重新計算
- 不需要 View 自己維護 Timer，也不需要 `.onReceive(timer)` boilerplate

**Timer 生命週期：**
- `startForegroundTimer()` 有保護（`guard timer == nil`），重複呼叫安全
- app 進背景 → `stopForegroundTimer()` 釋放資源；回前景 → 重新啟動
- `[weak self]` 防止 retain cycle

**前台自動結算：**
- Timer callback 每秒呼叫 `scanAndSettle()`
- `SettlementService.scanAndSettle()` 已幂等（無到期任務時直接 return），性能影響可忽略
- 任務到期 → `@Query` 更新 → NPC row 自動切換「閒置」狀態；同時 `shouldShowSettlement = true` → 結算 Sheet 彈出

**AdventureView 接收 appState：**
- 傳入方式與 BaseView 一致（構造子注入），符合現有架構模式
- Preview 改為手動建立 AppState（需要 ModelContext）

**格式選擇：**
- 使用數字倒數（`01:23:45`）而非文字（「剩約 X 分鐘」），精確度更高、每秒更新可感知
- `monospacedDigit()` 防止數字寬度跳動

### 待實作 / 下一步

---

## Phase 10 — 商人系統（固定商店 / 單向不對稱兌換）（已完成）

**目標：** 補齊基地商人 NPC 功能，讓玩家能以固定規則進行素材↔金幣、金幣↔稀有素材的單向交換，形成完整資源循環。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Services/MerchantService.swift` | 🆕 `executeSellTrade()` 素材→金幣；`executeBuyTrade()` 金幣→稀有素材；資源驗證 + 原子寫入 |
| `Views/MerchantSheet.swift` | 🆕 固定商店 Sheet；資源摘要 + 出售區 + 補給區；資源不足時按鈕 disabled |
| `Views/BaseView.swift` | ✏️ 新增 `npcMerchantRow()`（商人 NPC row，常駐閒置，點擊開 Sheet）+ `showMerchantSheet` 狀態 |

### 關鍵決策

**資料結構沿用：**
- `MerchantTradeDef.all`（素材→金幣）與 `MerchantTradeDef.goldTrades`（金幣→稀有素材）已在 Phase 1 定義，Phase 10 直接使用，無需改動靜態資料

**兩個方法分開：**
- `executeSellTrade` 處理 `MerchantTradeDef.all`（`give material → receive gold`）
- `executeBuyTrade` 處理 `MerchantTradeDef.goldTrades`（`give gold → receive material`）
- 邏輯路徑分離，不混用，防止意外的套利路徑

**原子寫入：**
- 扣除與入帳在同一 `context.save()` 內完成（一次寫入），不存在「扣了但沒入帳」的中間態

**按鈕 disabled 而非彈錯誤：**
- `canAfford` 直接從 `@Query` 即時計算，資源不足時按鈕 disabled，視覺清晰，不需要額外 alert 流程
- 保留 alert 做為 service 層意外失敗的後備（極少觸發）

**商人無任務狀態：**
- 商人不參與 Task 系統（無 `TaskModel`），NPC row 永遠顯示「閒置」，直接點擊開 Sheet

**套利防護（設計層面）：**
- 出售方向（素材→金幣）與補給方向（金幣→稀有素材）不可反向操作
- 無「素材↔素材」交換，無「基礎素材←金幣」補給（木材/礦石/獸皮只能靠採集/地下城）
- `MerchantTradeDef.goldTrades` 只有古代碎片可購買，且單價高（800金/個），不划算作為主要來源

### 待實作 / 下一步

---

## Phase 11 — Onboarding 與 MVP 收尾（已完成）

**目標：** 補齊首次體驗缺口，讓首次進入遊戲的玩家能自然理解「採集 → 鑄造 → 冒險」流程，並補上首件鑄造 / 首次出征加速說明與輕量完成提示。

### 完成項目
| 檔案 | 說明 |
|---|---|
| `Views/OnboardingBannerView.swift` | 🆕 3 步驟引導 Banner；依 `player.onboardingStep` 顯示；「知道了 / 下一步」推進；step ≥ 3 自動隱藏 |
| `ViewModels/BaseViewModel.swift` | ✏️ 新增 `advanceOnboarding(expectedStep:player:context:)`；幂等推進 |
| `Views/BaseView.swift` | ✏️ List 頂部加入 `OnboardingBannerView`（`onboardingStep < 3` 時顯示） |
| `Views/AdventureView.swift` | ✏️ 地下城列表前加入首次出征加速提示 Banner（`!hasUsedFirstDungeonBoost` 時顯示）|
| `AppState.swift` | ✏️ 新增 `toastMessage` + `showToast()`（2.5 秒自動清除）；結算時自動觸發 |
| `ContentView.swift` | ✏️ `.overlay(alignment: .top)` 顯示 `ToastBanner`（private struct，淡入滑出） |

### 關鍵決策

**Onboarding 最小化：**
- 純 Banner 形式，不遮罩、不強制互動，玩家可直接忽略
- `player.onboardingStep`（0–3）已在 SwiftData Model，無需新增欄位
- Step 3 = 完成，Banner 永不再出現

**加速提示雙重保障：**
- 首件鑄造：CraftSheet 已有「✨ 特快 30 秒」提示（Phase 6）；Onboarding Step 1 補強提醒
- 首次出征：AdventureView 新增 Label Banner；Onboarding Step 2 補強提醒；使用後自動消失

**Toast 不替代 SettlementSheet：**
- Toast 為補充提示（非阻擋），SettlementSheet 仍是收下獎勵的主要入口
- `DispatchQueue.main.asyncAfter` 2.5 秒自動清除，簡單可靠

**數值未調整：**
- 初始 gold 100 / wood 6 / ore 4 已足夠立即鑄造所有普通裝備，first-session 流程順暢

### 待實作 / 下一步

---

---

## Phase 12 — 實機驗證與 TestFlight 前收尾（已完成）

**目標：** 確認 first-session 數值合理，整理 Release 前必要設定，封存 TestFlight 穩定性清單。

### 完成項目

| 檔案 | 說明 |
|---|---|
| `project.yml` | ✏️ 新增 `NSHumanReadableCopyright`；`CFBundleDisplayName` 改為「放置英雄」（中文 App 顯示名稱） |
| `Views/BaseView.swift` | ✏️ 開發模式 Section + `addShortTestTask()` 以 `#if DEBUG` 包裹；Release / TestFlight build 完全隱藏 |
| `CHECKLIST.md` | 🆕 TestFlight 實機驗證清單（A–J 共 40 項）；涵蓋採集 / 鑄造 / 地下城 / 角色 / 商人 / 離線結算 / 穩定性 / 上傳前核查 |

### 數值平衡分析（無需修改）

首次登入初始戰力計算（裝備破舊短劍）：
```
ATK = 5 + 12 = 17、DEF = 3、HP = 20
Power = 17×2 + 3×1.5 + 20×1 = 58
```
荒野邊境 勝率（recommendedPower=50）：
```
ratio = 58/50 = 1.16
winRate = 0.50 + 0.40 × tanh(2×0.16) ≈ 0.62 → 約 62%
```
結論：初始勝率適中，不會太難也不會秒過。初始素材（木材 6、礦石 4）足夠立即鑄造普通防具（木材 4 + 礦石 3 + 金幣 10），不需額外等待採集。升到 Lv.2 需 200 金幣，需先透過地下城賺取，形成「出征 → 升級 → 更強 → 解鎖新區域」的正向循環。**AppConstants.swift 數值無需調整。**

### 關鍵決策

**`#if DEBUG` 而非 footer 說明：**
- 舊做法：Section 永遠顯示，footer 提示「正式版將移除」→ 玩家在 TestFlight 仍看到開發按鈕，體驗不佳
- 新做法：`#if DEBUG` 完全移除，Release / TestFlight build 乾淨無開發工具；Debug build（模擬器 / 直接部署）仍可使用
- `addShortTestTask()` 同樣包在 `#if DEBUG`，避免 Release build 出現 dead code

**App 顯示名稱改中文：**
- `CFBundleDisplayName: "放置英雄"` — 與遊戲定位（中文 idle RPG）一致，App 圖示下方顯示中文
- Bundle ID / 內部 target name 維持英文（`com.lowhaijer.IdleBattleRPG`）

**CHECKLIST.md 設計原則：**
- 以使用者行為路徑（採集 → 鑄造 → 冒險 → 角色 → 商人）排列，而非技術模組
- 每項皆有具體預期結果，驗證者不需看程式碼就能判斷通過/失敗
- J 區「上傳前核查」對應 project.yml / Info.plist 設定，避免送審被退回

---

## MVP 完成狀態

所有 Phase 1–12 已實作完成，MVP 主要循環可正常運作，可進入 TestFlight：

- ✅ Phase 1  資料地基
- ✅ Phase 2  Service 層
- ✅ Phase 3  任務掃描骨架
- ✅ Phase 4  正式 Tab 容器
- ✅ Phase 5  任務收下與獎勵入帳
- ✅ Phase 6  NPC 任務建立 UI
- ✅ Phase 7  確定性 RNG 與地下城結算
- ✅ Phase 8  角色系統（升級 / 屬性點 / 裝備切換）
- ✅ Phase 9  即時倒數與前台自動結算
- ✅ Phase 10 商人系統
- ✅ Phase 11 Onboarding 與 MVP 收尾
- ✅ Phase 12 實機驗證與 TestFlight 前收尾

### TestFlight 上傳步驟

1. `xcodegen generate`（確保 `.xcodeproj` 是最新）
2. Xcode → Product → Archive（確認 Scheme 為 Release）
3. Distribute App → TestFlight & App Store → 上傳
4. App Store Connect → 設定測試說明（貼上 `CHECKLIST.md §已知限制` 內容）
5. 邀請測試員，完成 `CHECKLIST.md` 全部勾選

### 後續 V2 可選工作

- 推播通知（任務完成時提醒）
- iCloud 備份 / 跨裝置同步
- 好友排行榜
- 裝備強化系統
- NPC 升級 / 解鎖更多 NPC
- 第二貨幣（鑽石）
- 商人每日刷新

（詳見 MVP_SPEC_FINAL.md §12）

---

## V2-1 進度總覽

> 詳細工單內容見 [`tickets/V2-1/`](tickets/V2-1/)

| Ticket | 標題 | 狀態 | commit |
|---|---|---|---|
| 01 | 地下城靜態資料正式化 | ✅ 完成 | `c8ab784` |
| 02 | 區域素材 SwiftData 正式化 | ✅ 完成 | `a7da9df` |
| 03 | 地下城推進狀態模型 | ✅ 完成 | `a7da9df` |
| 04 | AdventureView 重構 | ✅ 完成 | — |
| 05 | CharacterView 4 部位裝備槽 | ✅ 完成 | — |
| 06 | V2-1 鑄造配方與 CraftSheet 擴充 | ✅ 完成 | — |
| 07 | 首通裝備解鎖邏輯 | ✅ 完成 | — |
| 08 | Boss 武器浮動數值 Farming | ✅ 完成 | — |
| 09 | 數值平衡 | ✅ 完成（數學分析版）| — |

---

## V2-1 — Ticket 01：地下城靜態資料正式化（已完成）

> 詳細內容見 [tickets/V2-1/ticket-01-dungeon-static-data.md](tickets/V2-1/ticket-01-dungeon-static-data.md)

**目標：** 依照 `V2_1_DUNGEON_PROGRESSION_SPEC.md` 正式定義 3 區域 × 4 樓層的靜態資料、12 種區域素材、新 `offhand` 裝備部位、12 件套裝裝備。

### 完成項目摘要

- `DungeonRegionDef` / `DungeonFloorDef` 靜態資料（3 區域 × 4 樓層）
- `MaterialType` 新增 12 個區域素材 enum case
- `EquipmentDef` 新增 `.offhand` 部位；12 件套裝裝備
- V1 `DungeonAreaDef` 維持不動，bridge no-op 確保現有功能不受影響
```

區域與樓層對應：

| 區域 | 樓層 | 解鎖部位 | 建議戰力 |
|---|---|---|---|
---

## V2-1 — Ticket 02：區域素材 SwiftData 正式化（已完成）

> 詳細內容見 [tickets/V2-1/ticket-02-material-inventory.md](tickets/V2-1/ticket-02-material-inventory.md)

**目標：** 打通 12 種區域素材的完整資料鏈（可存 / 可結算 / 可入帳 / 可顯示）。

### 完成項目摘要

- `MaterialInventoryModel` 新增 12 個 SwiftData 欄位，移除 bridge no-op
- `TaskModel` 新增 12 個 `result*` 欄位；`resultAmount(of:)` / `setResult(_:of:)` 統一操作
- `DungeonSettlementEngine` 新增 `settle(task:floor:)` V2-1 路徑（V1 路徑保留）
- `TaskClaimService` / `SettlementViewModel` 改為迭代 `MaterialType.allCases`

---

## V2-1 — Ticket 03：地下城推進狀態模型（已完成）

> 詳細內容見 [tickets/V2-1/ticket-03-dungeon-progression-model.md](tickets/V2-1/ticket-03-dungeon-progression-model.md)

**目標：** 建立地下城首通 / 解鎖 / 推進的長期狀態資料層。

### 完成項目摘要

- `DungeonProgressionModel`（SwiftData 單例）+ Repository + Service 三層建立
- 解鎖規則：wildland 預設解鎖 → Boss 首通解鎖下一區 → 前一層首通解鎖下一層
- `SettlementService` 結算後自動呼叫 `markDungeonProgression()`
- `AppState` 公開 `progressionService`；`AdventureViewModel` 新增 5 個查詢方法

---

## V2-1 — Ticket 04：AdventureView 重構（已完成）

> 詳細內容見 [tickets/V2-1/ticket-04-adventure-view-refactor.md](tickets/V2-1/ticket-04-adventure-view-refactor.md)

**目標：** 將冒險頁改為 V2-1 樓層結構，接入 DungeonProgressionService，顯示區域 / 樓層推進狀態。

### 完成項目摘要

- `DungeonFloorDef: Identifiable` + `DungeonFloorDef.find(key:)` 靜態方法（DungeonRegionDef.swift）
- `TaskCreationService.createDungeonFloorTask()`：V2-1 floor key 任務建立入口
- `AdventureViewModel.startDungeonFloor()` + `activeDungeonName()`：支援 V1/V2-1 雙路徑
- `AdventureView` 全面重構：3 個區域卡片（展開/收合）× 4 層樓，未解鎖灰化並顯示條件
- `FloorDetailSheet`（private struct）：掉落表、戰力評估、首通解鎖預覽、時長 Picker、出發按鈕

---

## V3-1 — 玩家累計統計（已完成）

**目標：** 記錄玩家的長期累計數據，顯示在角色頁。

### 完成項目

- `PlayerStateModel` 新增 5 個統計欄位：`totalGoldEarned`、`totalBattlesWon`、`totalBattlesLost`、`totalItemsCrafted`、`highestPowerReached`
- `TaskClaimService.claimAllCompleted()` 收下任務時同步累計金幣 / 勝敗場 / 鑄造件數
- `AppState.updateHighestPower()` 每秒 timer tick 時更新歷史最高戰力
- `CharacterView` 角色頁底部新增「累計統計」Section（5 行數據）

---

## V3-2 — 移除連續出征功能（已完成）

**目標：** 移除自動出征（auto-dispatch）機制，永久不保留。

### 完成項目

- 移除 `PlayerStateModel` 中 `autoDispatchEnabled`、`autoDispatchFloorKey`、`autoDispatchDuration` 欄位
- 移除 `AppState.tryAutoDispatch()` 方法
- 移除 `AdventureView` 中 auto-dispatch Banner UI
- 移除 contextMenu `.repeatDispatch` 選項

---

## V3-3 — 裝備比較 Diff（已完成）

**目標：** 背包列表與裝備選擇 Sheet 顯示「換裝後屬性差異」。

### 完成項目

- `StatDiff` struct（top-level）：atk / def / hp 差值 + power 差值計算
- `CharacterViewModel.equipDiff(candidate:equipped:)` 純計算方法
- `EquipmentModel` 新增 `totalAtk` / `totalDef` / `totalHp` 別名
- `CharacterView` 背包列表每行顯示 diff badge（綠色 ▲ / 紅色 ▼）
- `EquipSelectSheet` 每行顯示完整屬性 + diff badge

---

## V3-4 — Dev 工具修正 + 採集時長縮放（已完成）

**目標：** 修正 Dev 快速完成任務的行為，並讓採集輸出隨時長等比縮放。

### 完成項目

- `BaseView.devExpireAllTasks()` 修正：同時將 `startedAt` 和 `endsAt` 往前平移，保留原始 duration，確保採集 / 地下城結算得到正確的回合數與戰鬥場數
- `SettlementService.fillGatherResults()` 改為 cycle-based 縮放：`cycles = floor(actualDuration / shortestDuration)`，每回合獨立 RNG 後加總
- `GatherLocationDef.shortestDuration` 改為獨立欄位（900s = 15 分鐘），與 `durationOptions[0]` 解耦
- `GatherLocationDef.durationOptions` 同步冒險選項（15分 / 1小時 / 12小時）

---

## 正式數值調整（已完成）

- `AppConstants.DungeonDuration.all` 移除 1 分鐘測試選項，正式為 `[15分, 1小時, 12小時]`
- V1 鑄造時間更新為正式值：普通飾品 5分 / 武器 8分 / 防具 10分；精良飾品 12分 / 武器 15分 / 防具 20分
- `NpcUpgradeService` bug 修正：素材扣除改用 `deduct()` 而非 `add(-n)`
- 實機測試全部通過（34 項，E1 因改為 EXP 升級系統而 N/A）

---

## 目前狀態

全部 46 張 ticket ✅ 完成，實機測試通過。
下一步：討論新玩法方向，確認後規劃 V4 tickets。
