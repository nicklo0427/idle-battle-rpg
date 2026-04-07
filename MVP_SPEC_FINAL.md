# MVP_SPEC_FINAL.md

> 版本：1.0
> 狀態：⚠️ 歷史文件 — V1 MVP 已完成，目前進入 V4 規劃。此文件僅供參考。
> 現行開發狀態請見：`PROGRESS.md` 與 `CLAUDE.md`

---

## 1. 專案定位

一款 iOS 放置 RPG。玩家扮演一名冒險者，利用生活空檔安排英雄出征、派遣採集者蒐集素材、委託鑄造師打造裝備，讓自己越來越強。

**MVP 是純本地單機遊戲**，無後端、無帳號系統、無社交功能。

**平台：** iOS 17+，Swift / SwiftUI / SwiftData

---

## 2. 核心玩法與核心循環

### 設計核心

玩家在真實生活的空檔打開遊戲，安排任務後關掉，過一段時間回來看結果、累積成長。

### 核心循環

```
打開 App → 基地畫面
├── 派採集者去採集（AFK，2~3 小時）→ 帶回素材
├── 委派鑄造師打造裝備（AFK，10~45 分鐘）→ 裝備完成進背包
└── 玩家出征地下城（AFK，15 分 / 1 小時 / 8 小時）→ 獸皮、金幣

結算：回來 App 時，一張總結算卡顯示所有完成任務的結果

成長路徑：
  素材 + 金幣 → 鑄造師打裝備 → 裝備提升戰力
  → 挑戰更深的地下城 → 更稀有素材 → 更好的裝備
```

---

## 3. MVP 系統範圍

### 包含

| 系統 | 說明 |
|---|---|
| 基地畫面 | 核心主頁，顯示所有 NPC 狀態 |
| 採集系統 | 採集者 ×2，選地點→AFK→素材 |
| 鑄造系統 | 鑄造師 ×1，選配方→AFK→裝備 |
| 商人商店 | 固定兌換清單（單向，無套利） |
| 地下城系統 | 3 個區域，AFK 出征，確定性 RNG 結算 |
| 英雄成長 | 裝備欄 3 部位 + 屬性點分配 |
| 英雄升級 | 純金幣升級，最高 10 級，每級 +3 屬性點 |
| 經濟系統 | 1 種貨幣（金幣）+ 5 種素材 |
| 總結算卡 | 合併顯示所有完成任務，一次收下 |
| Onboarding | 3 步驟 highlight（採集者→鑄造師→冒險） |
| 新手保護 | 首件鑄造 30 秒 / 首次出征 30 秒 + 5 場 |

### 不在 MVP 內（V2）

- 後端、API、帳號系統
- Apple Sign In
- 好友系統、非同步組隊
- 裝備強化系統
- NPC 升級 / 招募更多 NPC
- 第二貨幣（鑽石）
- 推播通知
- 圖鑑 / 成就系統
- 商人每日刷新

---

## 4. 已定案的數值與規則

### 玩家初始狀態

| 項目 | 數值 |
|---|---|
| 初始金幣 | 100 |
| 初始木材 | 6 |
| 初始礦石 | 4 |
| 初始裝備 | 破舊短劍 ×1（預裝） |
| 其他素材 | 0 |

### 素材系統（5 種）

| 素材 | 主要來源 | 用途 |
|---|---|---|
| 木材 | 採集者（森林，2 小時）| 初級配方 |
| 礦石 | 採集者（礦坑，3 小時）| 初級配方 |
| 獸皮 | 地下城區域 1 掉落 | 皮革類裝備 |
| 魔晶石 | 地下城區域 2+ 掉落 | 中階配方 |
| 古代碎片 | 地下城區域 3 掉落 | 高階配方 |

### 裝備系統（3 部位 × 2 稀有度 = 6 個配方）

| 部位 | 主加成 |
|---|---|
| 武器 | ATK |
| 防具 | DEF + HP（單一版本）|
| 飾品 | 混合屬性 |

**稀有度：** 普通 / 精良
**裝備強化：** 不在 MVP 範圍

### 鑄造等待時間

| 配方 | 時間 |
|---|---|
| 普通武器 | 10 分鐘 |
| 普通防具 | 15 分鐘 |
| 普通飾品 | 20 分鐘 |
| 精良武器 | 30 分鐘 |
| 精良防具 | 40 分鐘 |
| 精良飾品 | 45 分鐘 |

### 地下城

| 區域 | 解鎖條件 | 主要產出 |
|---|---|---|
| 荒野邊境 | 初始（推薦戰力 50）| 獸皮、金幣 |
| 廢棄礦坑 | 戰力 ≥ 150 | 魔晶石、金幣 |
| 深淵遺跡 | 戰力 ≥ 400 | 古代碎片、金幣 |

**時長選項：** 15 分鐘 / 1 小時 / 8 小時
**離線上限：** 8 小時
**秒數換場次：** 每 60 秒一場戰鬥

### 英雄成長

```
戰力 = ATK × 2 + DEF × 1.5 + HP × 1

勝率 = clamp(10%, 95%, 50% + 40% × tanh(2 × (戰力 / 推薦戰力 - 1)))

升級費用：純金幣（不消耗素材）
每升一級：+3 屬性點，自由分配 ATK / DEF / HP
英雄等級上限：10
```

### 地下城結算規則

- **勝場：** 全額素材 + 金幣
- **敗場：** 20% 安慰金幣，無素材
- **確定性 RNG seed：** `UInt64(startedAt) XOR taskId.hashValue`
- **戰力快照：** 用出發當下的 `snapshotPower`，不用結算時的當前戰力

### 商人（固定兌換，單向，無套利）

- 出售方向：素材 → 金幣（木材 / 礦石 / 獸皮 / 魔晶石）
- 補給方向：金幣 → 古代碎片（單價高，非主要來源）
- **不設計：** 素材 ↔ 素材 雙向兌換（防循環套利）
- **不設計：** 金幣 → 基礎素材（木材 / 礦石 / 獸皮 只能靠採集或地下城）

### 新手保護機制（生涯各一次）

| 機制 | 觸發條件 | 效果 |
|---|---|---|
| 首件鑄造特快 | 生涯第一次委派鑄造 | 30 秒完成，顯示「✨ 首次鍛造特快！」|
| 首次出征特快 | 生涯第一次出征（選 15 分鐘）| 30 秒完成，固定 5 場戰鬥，保底 gold > 0 |

---

## 5. First-Session 體驗設計

目標：約 2.5 分鐘內讓玩家完成第一個完整循環。

```
[0:00]  基地畫面 → Highlight 採集者
[0:30]  派採集者出發（森林 + 礦坑，背景計時）
        → Highlight 鑄造師
[1:00]  委派鑄造師打普通防具（✨ 30 秒特快）
        → Highlight 冒險入口
[1:30]  切到冒險頁，裝上防具（戰力提升）
[2:00]  選荒野邊境，15 分鐘（⚡ 30 秒特快）出發
[2:30]  總結算卡彈出 ← 第一個完整循環完成
```

**時長 Chip 預設邏輯：**
- 首次出征前：預設選中「15 分鐘」
- 首次出征後：預設改為「1 小時」

---

## 6. UI 結構

### 導航結構

底部 3 個 Tab：**基地 / 冒險 / 角色**

背包合併進角色 Tab（Segment Control 切換：裝備 / 背包）

### 各頁面要點

**Tab 1：基地**
- 常駐資訊：金幣、英雄出征狀態
- NPC 列表：採集者 ×2、鑄造師 ×1、商人 ×1
- 各 NPC 顯示：狀態（任務中 / 閒置）、倒計時
- 點擊閒置 NPC → 對應 Sheet

**Tab 2：冒險**
- 3 張區域卡片（全展開，不折疊）
- 每張顯示：區域名、推薦戰力、勝率進度條、掉落預覽
- 時長 Chip（15 分 / 1 小時 / 8 小時）直接在卡片內選擇，無另開 Sheet
- 出征中：倒計時進度條，出發按鈕 disabled

**Tab 3：角色**
- 預設進入：裝備 Segment（固定，不記憶上次狀態）
- 裝備 Segment：3 個裝備欄 + ATK/DEF/HP 屬性 + 屬性點分配 + 升級按鈕
- 背包 Segment：5 種素材數量 + 未裝備裝備列表

### Sheet / Modal 清單

| 名稱 | 觸發 | 說明 |
|---|---|---|
| 採集派遣 Sheet | 點閒置採集者 | 選地點 → 出發 |
| 鑄造配方 Sheet | 點閒置鑄造師 | 選配方 → 委派（素材不足 disabled）|
| 商店 Sheet | 點商人 | 固定兌換清單 |
| 裝備選擇 Sheet | 點裝備欄 | 從背包選同部位裝備 |
| 總結算 Modal | App 回前景且有完成任務 | 合併顯示所有完成任務，一次收下 |

---

## 7. 資料模型（v0.2 精簡版）

### 持久化（SwiftData @Model）

**PlayerStateModel（單例）**
```
gold: Int
heroLevel: Int
availableStatPoints: Int
atkPoints: Int
defPoints: Int
hpPoints: Int
lastOpenedAt: Date
hasUsedFirstCraftBoost: Bool
hasUsedFirstDungeonBoost: Bool
onboardingStep: Int          // 0~3，3 = 完成
```

**MaterialInventoryModel（單例）**
```
wood: Int
ore: Int
hide: Int
crystalShard: Int
ancientFragment: Int
```

**EquipmentModel（每件一筆）**
```
defKey: String               // 對應靜態 EquipmentDef
slot: EquipmentSlot          // .weapon / .armor / .accessory
rarity: EquipmentRarity      // .common / .refined
isEquipped: Bool
```

**TaskModel（進行中 + 已完成待結算；玩家收下後刪除）**
```
id: UUID
kind: TaskKind               // .gather / .craft / .dungeon
actorKey: String             // "gatherer_1" / "gatherer_2" / "blacksmith" / "player"
definitionKey: String        // 對應靜態資料 key
startedAt: Date
endsAt: Date
durationOverride: Int?       // 新手特快秒數（nil = 正常時長）
forcedBattles: Int?          // 首次出征固定 5 場（nil = 正常計算）
snapshotPower: Int?          // .dungeon 專用，出發時快照戰力
status: TaskStatus           // .inProgress / .completed

// 結果欄位（inProgress 時全為 0 / nil，completed 後填入）
resultGold: Int
resultWood: Int
resultOre: Int
resultHide: Int
resultCrystalShard: Int
resultAncientFragment: Int
resultBattlesWon: Int?       // .dungeon 專用
resultBattlesLost: Int?      // .dungeon 專用
resultCraftedEquipKey: String? // .craft 專用
```

### 靜態資料（Swift struct，不進 DB）

```
GatherLocationDef    // key / name / durationSeconds / outputMaterial / outputRange
CraftRecipeDef       // key / name / slot / rarity / durationSeconds / requiredMaterials / goldCost / outputEquipmentKey
DungeonAreaDef       // key / name / recommendedPower / dropTable / goldPerBattleRange
EquipmentDef         // key / name / slot / rarity / atkBonus / defBonus / hpBonus
MerchantTradeDef     // key / giveMaterial / giveAmount / receiveGold (or receiveMaterial)
DropTableEntry       // material / dropRate / quantityRange
```

### Value Types（計算用，不存 DB）

```
HeroStats            // totalATK / totalDEF / totalHP / power（每次現算，不快取）
```

---

## 8. 系統規格重點

### App 啟動 / 回前景流程

```
1. 讀取 lastOpenedAt（先讀，不先更新）
2. 撈出 status == .inProgress 且 endsAt <= now 的 TaskModel
3. 對每筆執行結算計算（確定性 RNG），status → .completed，result 欄位填入
4. 更新 lastOpenedAt = now
5. 有 .completed 任務 → 顯示總結算 Modal
   無 → 直接進基地頁
6. 啟動前台 Timer（1 秒），監聽即時到期任務
```

### 地下城結算（確定性 RNG）

```
seed = UInt64(task.startedAt.timeIntervalSinceReferenceDate) XOR UInt64(bitPattern: task.id.hashValue)
actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
totalBattles = task.forcedBattles ?? Int(actualDuration / 60)

winRate = clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (snapshotPower / recommendedPower - 1)))

for each battle:
  if rng.nextDouble() < winRate:
    gold += rng.int(in: goldRange)
    for entry in dropTable: if rng.nextDouble() < entry.rate → material += rng.int(in: entry.range)
  else:
    gold += floor(goldRange.lowerBound × 0.2)

首次出征保底：if resultGold == 0 → resultGold = goldRange.lowerBound
```

### HeroStats 計算

```
totalATK = atkPoints + (武器.atkBonus) + (防具.atkBonus) + (飾品.atkBonus)
totalDEF = defPoints + (武器.defBonus) + (防具.defBonus) + (飾品.defBonus)
totalHP  = hpPoints  + (武器.hpBonus)  + (防具.hpBonus)  + (飾品.hpBonus)
power    = totalATK × 2 + totalDEF × 1.5 + totalHP × 1
```

（空裝備欄的加成為 0）

### 鑄造任務特殊規則

- 素材和金幣在**任務建立時**立即扣除，不在結算時扣
- 鑄造結果是確定的（配方決定輸出），`resultCraftedEquipKey` 在建立時就填入
- 不需要 RNG

---

## 9. 工程分層

```
Views（SwiftUI）
    ↓ 只讀 ViewModel，只呼叫 ViewModel 方法
ViewModels（@Observable）
    ↓ 呼叫 Services，不直接操作 SwiftData
Services（純 Swift class）
    ↓ 讀寫 Models
Models（SwiftData @Model）+ StaticData（Swift struct，不進 DB）
```

### Services 責任切分

| Service | 責任 | ModelContext |
|---|---|---|
| `HeroStatsService` | 純計算，無副作用 | 無（傳入參數）|
| `DungeonSettlementEngine` | 確定性 RNG 計算 | 無（傳入參數）|
| `TaskRepository` | TaskModel CRUD | 建構子注入 |
| `TaskCreationService` | 建立任務 + 扣資源 + 更新 flag | 建構子注入 |
| `SettlementService` | 掃描→計算→寫入→回傳 completed 清單 | 建構子注入 |
| `EquipmentService` | 換裝 / 卸裝 / 查詢裝備欄 | 建構子注入 |
| `MerchantService` | 商店查詢 + 執行兌換（P1）| 建構子注入 |

### AppState 責任（嚴格限縮）

- ScenePhase 監聽（進前台 → 呼叫 SettlementService.scanAndSettle()）
- 前台 Timer（1 秒 tick）
- `shouldShowSettlement: Bool` + `pendingSettlementTasks`
- 讀取 `PlayerStateModel.onboardingStep`

**AppState 不持有任何遊戲內容狀態**（金幣、素材、戰力等都從 SwiftData 現查）

### ViewModel 職責

- `BaseViewModel`：NPC 狀態 + 倒計時 + Sheet 資料準備
- `AdventureViewModel`：區域顯示 + 勝率計算 + 出征操作
- `CharacterViewModel`：英雄屬性 + 裝備 + 屬性點 + 升級 + 背包
- `SettlementViewModel`：**只做 UI 資料轉換**，不含業務邏輯

---

## 10. 實作順序

```
Phase 1（計算核心，建議先寫單元測試）
  1. StaticData 全部定義
  2. 四個 SwiftData @Model
  3. HeroStatsService
  4. DungeonSettlementEngine

Phase 2（任務生命週期，三個獨立檔案）
  5. TaskRepository.swift
  6. TaskCreationService.swift
  7. SettlementService.swift
  8. EquipmentService.swift

Phase 3（全域協調）
  9. AppState
  10. SettlementViewModel + 總結算 Modal（優先，驗證結算流程）

Phase 4（Views）
  11. 基地 Tab + 採集 Sheet + 鑄造 Sheet
  12. 冒險 Tab
  13. 角色 Tab（裝備 + 背包 Segment）
  14. 裝備選擇 Sheet

Phase 5（P0.5：first-session 收尾）
  15. Onboarding 3 步驟 highlight
  16. 首次特快說明文字（鑄造 + 出征）
  17. 採集 / 鑄造完成輕量 toast

Phase 6（P1）
  18. MerchantService + 商店 Sheet
  19. 數值平衡調整
```

---

## 11. 開發原則

- 先做能跑的，再做好看的
- 靜態資料（StaticData）是遊戲平衡的唯一來源
- 確定性 RNG：相同輸入永遠產生相同結果
- 嚴守 MVP 邊界：任何「可以加」的功能，先確認是否必要
- Services 不依賴 View 層
- 計算核心（HeroStatsService、DungeonSettlementEngine）無副作用、可單元測試

---

## 12. V2 功能清單（明確不在 MVP）

- 後端 / Apple Sign In / 帳號系統
- 好友系統 / 非同步組隊
- 裝備強化 / 鑑定
- NPC 升級 / 招募更多 NPC
- 第二貨幣（鑽石）
- 推播通知
- 商人每日刷新
- 圖鑑 / 成就系統
- 多語言 / 本地化
- Android 版本
