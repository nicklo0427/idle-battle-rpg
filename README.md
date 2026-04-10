# 放置英雄 — Idle Battle RPG

> 生活空檔（上班前 / 午休 / 睡前）派英雄去地下城 AFK，NPC 採集素材、打造裝備。
> 純本地單機 iOS App，無後端、無帳號、無網路。

---

## Tech Stack

| 項目 | 技術 |
|---|---|
| 語言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 持久化 | SwiftData (iOS 17+) |
| 最低支援 | iOS 17.0 |
| 專案管理 | XcodeGen（`project.yml`，`.xcodeproj` 不進 git）|
| 網路 | 無（純本地）|

---

## 快速開始

```bash
# 1. Clone repo
git clone https://github.com/nicklo0427/idle-battle-rpg.git
cd idle-battle-rpg

# 2. 產生 Xcode 專案（需先安裝 XcodeGen）
brew install xcodegen
xcodegen generate

# 3. 開啟並 Run
open IdleBattleRPG.xcodeproj
```

> `.xcodeproj` 由 XcodeGen 產生，不進版本控制。新增檔案後需重新執行 `xcodegen generate`。

---

## 架構說明

```
Views  →  ViewModels  →  Services  →  Models (SwiftData)
                     ↘  StaticData (純 Swift struct)
```

| 層 | 責任 |
|---|---|
| **Views** | 讀 ViewModel 資料、呼叫 ViewModel 方法，不直接寫 SwiftData |
| **ViewModels** | 組合 Service 資料、管理 UI 狀態，不寫入 SwiftData |
| **Services** | 讀寫 SwiftData、執行業務邏輯計算 |
| **Models** | `@Model` 持有持久化資料，不含任何邏輯 |
| **StaticData** | 純 Swift struct，不進 SwiftData（裝備定義、地下城定義等）|

### AppState 責任（嚴格限縮）
- `ScenePhase` 監聽 → 觸發 `SettlementService.scanAndSettle()`
- 前台 1 秒 Timer（`tick: Date`），View 訂閱用於即時倒數
- 持有所有 Services（注入點）
- **不存任何遊戲狀態**（金幣、素材、戰力皆從 SwiftData 即時查詢）

### 確定性 RNG
```swift
seed = UInt64(task.startedAt.timeIntervalSinceReferenceDate)
     ^ UInt64(bitPattern: task.id.hashValue)
rng  = DeterministicRNG(seed: seed)   // LCG 演算法
```
相同輸入永遠產生相同輸出。結算在 App 回前台時用 seed 重算，不預存結果。

---

## 遊戲系統

### 玩家 / 英雄
- 屬性：ATK / DEF / HP / AGI / DEX
- 戰力公式：`ATK × 2 + DEF × 1.5 + HP × 1`
- 裝備欄：武器 / 副手 / 防具 / 飾品（4 部位）
- 升級：累積 EXP 自動升級，每級 +3 屬性點，上限 Lv.20
- Tab badge 提示未分配屬性點

### NPC

| NPC | 功能 |
|---|---|
| 採集者 × 2 | 選地點 → AFK → 帶回素材，可升級提升效率 |
| 鑄造師 × 1 | 選配方 → AFK → 完成裝備，可升級縮短時間 |
| 商人 × 1 | 固定兌換商店（素材 ↔ 金幣）|

### 素材（21 種）
- 通用：木材、礦石、獸皮、魔晶石、古代碎片
- 荒野邊境（4 種）、廢棄礦坑（4 種）、古代遺跡（4 種）、沉落王城（4 種）

### 地下城（4 區 × 4 層）

| 區域 | 解鎖條件 | 主色調 |
|---|---|---|
| 荒野邊境 | 初始解鎖 | 橙色 |
| 廢棄礦坑 | 通關荒野 Boss | 藍灰 |
| 古代遺跡 | 通關礦坑 Boss | 紫色 |
| 沉落王城 | 通關遺跡 Boss | 靛藍 |

每區 4 層（F1–F3 普通層 + F4 Boss 層），首通各層解鎖對應裝備配方。
每層設有**地區菁英**，擊敗後解鎖下一層並獲得額外獎勵。

### 出征
- 時長：15 分鐘 / 1 小時 / 8 小時（自選）
- 離線上限：8 小時
- 勝率公式：`clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (ratio − 1)))`
- 勝場：全額獎勵；敗場：20% 安慰金幣

### 其他系統
- **裝備強化**：金幣消耗，最高 +5，可拆解回收部分費用
- **裝備比較 Diff**：換裝前 ATK / DEF / HP 差值預覽
- **戰鬥記錄**：結算後可查看每場戰鬥文字記錄（Deterministic 重算，不持久存儲）
- **成就系統**：10 個成就，條件涵蓋戰鬥、鑄造、金幣、地下城首通、等級上限
- **新手加速**：首件鑄造 30 秒、首次出征 30 秒（各一次永久消耗）

---

## 版本紀錄

| 版本 | 狀態 | 主要內容 |
|---|---|---|
| V1 MVP | ✅ | 核心循環：採集 / 鑄造 / 出征 / 結算 / 英雄成長 |
| V2-1 | ✅ | 地下城推進（3 區域 × 4 樓層 × Boss）|
| V2-2 | ✅ | 裝備強化系統 |
| V2-3 | ✅ | NPC 效率升級 |
| V2-4 | ✅ | 商人 V2-1 素材、任務進度條、配方預覽 |
| V2-5 | ✅ | EXP 升級系統、採集者專精 |
| V3-1 | ✅ | 玩家累計統計 |
| V3-3 | ✅ | 裝備比較 Diff |
| V3-4 | ✅ | Dev 工具修正、採集時長縮放 |
| V4-1 | ✅ | 戰鬥文字記錄、BattleLogSheet 動畫播放 |
| V4-2 | ✅ | 菁英副本系統（EliteDef + EliteBattleEngine + EliteBattleSheet）|
| V4-3 | ✅ | 英雄等級上限 10→20、自動升級、沉落王城第四區域 |
| V4-4 | ✅ | 成就系統（AchievementDef × 10 + AchievementService）|
| V4-5 | ✅ | 區域差異化色調、SF Symbols pulse 動畫、精良裝備金色視覺 |

詳細開發紀錄見 [PROGRESS.md](PROGRESS.md)。

---

## 測試清單（手動驗收）

> 目前無 XCTest target。純計算層（`HeroStatsService`、`DungeonSettlementEngine`、`DeterministicRNG`）已設計為無副作用，可日後補充單元測試。

### 核心循環

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 1 | 採集者派出採集 → 等待完成 → 結算 | 素材入帳，任務刪除，統計更新 |
| 2 | 鑄造師首件鑄造（特快）→ 30 秒完成 | 裝備出現在背包，`hasUsedFirstCraftBoost = true` |
| 3 | 英雄首次出征（特快）→ 30 秒 / 5 場 | 金幣入帳，`hasUsedFirstDungeonBoost = true` |
| 4 | 離線後重開 App → 任務自動結算 | SettlementSheet 彈出，獎勵正確 |
| 5 | 點「收下」 | `TaskModel` 刪除，`PlayerStateModel` 更新，Sheet 消失 |

### 英雄成長

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 6 | EXP 累積至升級門檻 | 自動升級（不需手動按），`availableStatPoints += 3` |
| 7 | 一次跨多級的 EXP | 全部升完，EXP 剩餘正確 |
| 8 | Lv.20 後繼續獲得 EXP | 停止升級，顯示「已達最高等級」 |
| 9 | `availableStatPoints > 0` | 角色 Tab 右上角顯示 badge |
| 10 | 分配屬性點 → 確認加點 | 戰力更新，badge 消失 |

### 地下城推進

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 11 | 首通荒野邊境 F4 Boss | 解鎖廢棄礦坑，SettlementSheet 顯示解鎖提示 |
| 12 | 首通廢棄礦坑 F4 Boss | 解鎖古代遺跡 |
| 13 | 首通古代遺跡 F4 Boss | 解鎖沉落王城 |
| 14 | 菁英挑戰（戰力足夠）→ 勝利 | 金幣 + 素材入帳，「已擊敗」標記，解鎖下一層 |
| 15 | 菁英挑戰（戰力不足）| 按鈕顯示「戰力不足（需 XXX）」，無法點擊 |
| 16 | 戰鬥記錄播放 | BattleLogSheet 逐行播放，HP 數值正確 |

### 視覺 / V4-5

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 17 | 荒野邊境展開 | 圖示、Boss 圓圈、出征中標籤皆為橙色 |
| 18 | 廢棄礦坑展開 | 皆為藍灰色 |
| 19 | 古代遺跡展開 | 皆為紫色 |
| 20 | 沉落王城展開 | 皆為靛藍色 |
| 21 | 採集者 / 鑄造師任務進行中 | NPC 圖示持續 pulse 脈動 |
| 22 | 出征中 Banner | `map.fill` 圖示持續 pulse 脈動 |
| 23 | 精良裝備顯示 | 名稱 + 稀有度標籤呈金黃色（背包 / 裝備槽 / EquipSelectSheet）|

### 成就系統

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 24 | 首次獲勝 1 場 | 「第一滴血」解鎖，成就頁顯示 ✦ 勾選 |
| 25 | 英雄升至 Lv.20 | 「傳奇英雄」解鎖 |
| 26 | 沉落王城 F4 首通 | 「深淵征服者」解鎖 |
| 27 | 成就頁 Segment | 顯示進度條 X/10 + 全部 10 個成就列表 |

### 沉落王城

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 28 | 通關古代遺跡後查看地下城 | 沉落王城顯示於列表，可展開 |
| 29 | 沉落王城配方（鑄造師）| 通關對應樓層後配方解鎖，可委派鑄造 |
| 30 | 沉落王城 Boss 武器掉落 | ✦ 浮動 ATK 顯示於背包 |

---

## 開發規範

詳見 [CLAUDE.md](CLAUDE.md)。重點摘要：
- **分層架構**：Views 不直接讀 Model，ViewModels 不直接寫 SwiftData
- **計算核心純化**：結算用確定性 RNG，不預存結果
- **靜態資料用 Swift struct**：不要把 StaticData 放進 SwiftData
- **新功能先寫 ticket 再實作**：見 `tickets/` 目錄

---

## 作者

Nick Lo — [@nicklo0427](https://github.com/nicklo0427)
