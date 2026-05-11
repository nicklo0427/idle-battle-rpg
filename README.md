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

## 文件地圖

| 文件 | 用途 |
|---|---|
| `README.md` | 專案總覽、快速開始、目前主要系統 |
| `AGENTS.md` | Codex 協作規則與目前開發狀態 |
| `CLAUDE.md` | Claude / Claude Code 協作規則 |
| `PROGRESS.md` | 版本開發紀錄與重要決策 |
| `BRANCHES.md` | 分支 / worktree 現況與整理規則 |
| `tickets/README.md` | tickets 目錄索引與版本狀態 |
| `art-assets/` | 美術方向、生成 prompt、產物檢查紀錄 |

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
- 升級：累積 EXP 自動升級，每級 +3 屬性點，上限 Lv.30
- Tab badge 提示未分配屬性點

### NPC

| NPC | 功能 |
|---|---|
| 採集者 × 4 | 木材 / 礦石 / 草藥 / 漁獲採集，可升級與投入採集技能 |
| 農夫 | 種田 → AFK → 收穫農作物（三品質）|
| 鑄造師 | 武器製作，可升級與投入生產技能 |
| 鍛造學徒 | 副手製作 |
| 裁縫師 | 防具製作 |
| 飾品師 | 飾品製作 |
| 廚師 | AFK 烹飪料理，作為出征消耗品 |
| 製藥師 | AFK 煉製藥水，作為出征消耗品 |
| 商人 | 固定兌換商店（素材 / 種子 / 農作物 / 金幣）|

### 素材（43 種）
- 通用：木材、礦石、獸皮、魔晶石、古代碎片
- 地下城區域素材：4 區 × 4 種
- 採集專屬素材：古木材、精煉礦石、草藥、靈草、鮮魚、深淵魚
- 農場：4 種種子 + 4 種農作物 × 3 品質

### 地下城（4 區 × 4 層）

| 區域 | 解鎖條件 | 主色調 |
|---|---|---|
| 金穗之野 | 初始解鎖 | 農地 / 橙色 |
| 暮色古林 | 通關金穗之野 Boss | 森林 / 綠色 |
| 血色曠野 | 通關暮色古林 Boss | 草原 / 紅色 |
| 烈焰沙海 | 通關血色曠野 Boss | 沙海 / 金色 |

每區 4 層（F1–F3 普通層 + F4 Boss 層），首通各層解鎖對應裝備配方。
每層設有**地區菁英**，擊敗後解鎖下一層並獲得額外獎勵。

### 出征
- 時長：15 分鐘 / 1 小時 / 12 小時（自選）
- 離線上限：12 小時
- 勝率公式：`clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (ratio − 1)))`
- 目前戰鬥結算核心已演進為完整 ATB 模擬；勝率公式保留給部分 UI 預覽與相容路徑

### 其他系統
- **職業 / 技能 / 天賦**：4 職業，主動技能、技能升階、天賦路線
- **裝備強化**：金幣消耗，最高 +8，可拆解回收部分費用
- **裝備比較 Diff**：換裝前 ATK / DEF / HP 差值預覽
- **即時戰鬥播放**：任務完成後進入 battlePending，玩家觀看 ATB 戰鬥後再收獎
- **成就系統**：10 個成就，條件涵蓋戰鬥、鑄造、金幣、地下城首通、等級上限
- **新手敘事 / 教程**：開場敘事、英雄命名、職業選擇、原生 UI 引導

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
| V6-1 | ✅ | 職業系統 + 主動技能 |
| V6-2 | ✅ | 技能升階 + CharacterView 重構 |
| V6-3 | ✅ | 地下城即時戰鬥播放 |
| V6-4 | ✅ | 高等內容、菁英戰鬥、天賦樹 |
| V7-1 | ✅ | 採集系統擴充 |
| V7-3 | ✅ | 廚師 NPC + 料理系統 |
| V7-4 | ✅ | 農夫 / 消耗品 / 製藥師 + 商人更新 |
| V8-1 | ✅ | 裝備稀有度擴充 |
| V8-2 | ✅ | 生產者技能效果 + 本地通知 |
| V8-3 | ✅ | Lv.30、進階技能、戰場統計、地區主題重設計 |
| V9-1 | ✅ | 視覺資產盤點與主要 UI polish |
| V9-2 | ✅ | 基地 / 裝備 / 背包 / 冒險頁 layout polish |
| V10-1 | ✅ | 新手敘事體驗 + 命名系統 |
| V10-2 | ✅ | 教程速度、引導文案、菁英戰與 NPC 命名調整 |
| V10-3 | ✅ | 引導 UX 審查與原生 UI 整合收尾 |

詳細開發紀錄見 [PROGRESS.md](PROGRESS.md)。

---

## 測試清單（手動驗收）

> 目前有 XCTest target，但部分測試仍停在舊 API，需要更新。主 app target 已可用 `xcodebuild -project IdleBattleRPG.xcodeproj -scheme IdleBattleRPG -destination 'generic/platform=iOS Simulator' build` 驗證。

### 核心循環

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 1 | 採集者派出採集 → 等待完成 → 結算 | 素材入帳，任務刪除，統計更新 |
| 2 | 教程鑄造初始武器（2 秒）→ 完成 | 職業對應武器 / 副手出現在背包，`onboardingStep` 正確推進 |
| 3 | 教程探索 / 出征完成 → 即時戰鬥 / 結算 | `battlePending` 觸發戰鬥播放，收下後獎勵入帳 |
| 4 | 離線後重開 App → 任務自動結算 | SettlementSheet 彈出，獎勵正確 |
| 5 | 點「收下」 | `TaskModel` 刪除，`PlayerStateModel` 更新，Sheet 消失 |

### 英雄成長

| # | 測試項目 | 預期結果 |
|---|---------|---------|
| 6 | EXP 累積至升級門檻 | 自動升級（不需手動按），`availableStatPoints += 3` |
| 7 | 一次跨多級的 EXP | 全部升完，EXP 剩餘正確 |
| 8 | Lv.30 後繼續獲得 EXP | 停止升級，顯示「已達最高等級」 |
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
