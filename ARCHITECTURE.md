# Architecture & Design Decisions

## 目錄
1. [整體架構](#整體架構)
2. [資料模型](#資料模型)
3. [遊戲引擎](#遊戲引擎)
4. [Claude AI 整合](#claude-ai-整合)
5. [畫面結構](#畫面結構)
6. [關鍵設計決策](#關鍵設計決策)

---

## 整體架構

採用 **MVVM** 分層架構，SwiftData 作為持久層，Service 層負責所有邏輯，View 保持純 UI。

```
Views  →  ViewModels  →  Services  →  Models (SwiftData)
                     ↘  StaticData (純 Swift struct，不存 DB)
```

### 為什麼不用 Core Data？
SwiftData 是 iOS 17 的官方繼任者，語法更簡潔，與 SwiftUI 整合更好，沒有理由選舊方案。

---

## 資料模型

所有需要持久化的資料用 `@Model` 標記，SwiftData 自動處理 SQLite。

### GameStateModel — 全域單例
```
gold            → 目前金幣
lastLoginDate   → 上次開啟時間（離線計算起點）
activeZoneId    → 目前戰鬥區域
offlineSummaryPending → 是否有待顯示的離線摘要
isOnboarded     → 是否已輸入 API Key
```

### HeroModel — 每位英雄一筆
```
classKey         → 對應 HeroClassDefinitions 靜態資料
name             → Claude 生成（或預設）
loreText         → Claude 生成，nil 代表尚未生成
baseATK/DEF/HP   → 基礎數值（由職業定義決定）
bonusATK/DEF/HP  → 升級累積加成
isInActiveParty  → 是否在上場隊伍
partySlot        → 隊伍位置 0–2，-1 代表板凳
```

### GeneratedContentModel — Claude 快取
```
cacheKey    → 唯一鍵值，格式如 "hero_lore_<UUID>"
content     → Claude 回傳的文字
generatedAt → 生成時間
```
這是整個 Claude 整合的核心：**每筆內容只生成一次，永久存放。**

### 靜態資料 (StaticData/) — 不存 DB
英雄職業、區域定義、裝備定義都是純 Swift `struct`，不進 SwiftData。
這些資料不會改變，存 DB 只是浪費空間。

---

## 遊戲引擎

### 離線進度計算（OfflineProgressCalculator）

**核心原則：確定性（Deterministic）**

相同輸入永遠產生相同輸出。作法：用 `lastLoginDate` 的 Unix timestamp 作為隨機種子。

```
seed = UInt64(lastLoginDate.timeIntervalSinceReferenceDate)
rng  = SeededRNG(seed: seed)   ← LCG 演算法
```

**為什麼這很重要？**
- 防止玩家調整手機時間重新計算獲得更多獎勵（調時後 seed 不同）
- 可以用固定 seed 寫單元測試，不需要 mock Date

**計算流程：**
```
1. offlineSeconds = min(now - lastLogin,  8小時上限)
2. totalBattles   = offlineSeconds / secondsPerBattle
3. winRate        = clamp(0.10, 0.98, 0.5 + 0.45 * tanh(2 * (teamPower/minPower - 1)))
4. for each battle → rng 決定輸贏 → 計算金幣與掉落
```

**勝率公式 (tanh 曲線)：**
- 0.5× 推薦戰力 → ~20% 勝率（很難打）
- 1.0× 推薦戰力 → 50% 勝率（有挑戰）
- 2.0× 推薦戰力 → ~95% 勝率（輕鬆）
- 永遠不低於 10%（弱隊也有點收穫）

### 升級費用曲線（UpgradeCalculator）

指數曲線，每升一級費用 ×1.18：
```
cost(level) = baseCost × 1.18^(level-1)

ATK: baseCost = 80  (每級 +baseATK×8%)
DEF: baseCost = 60  (每級 +baseDEF×10%)
HP:  baseCost = 40  (每級 +baseHP×12%)
```
約每 4 級費用翻倍，符合 idle 遊戲常見節奏。

---

## Claude AI 整合

### 分層設計

```
ClaudeAPIClient          ← 純 HTTP，只管打 API 和解析回應
    ↓
ClaudePromptBuilder      ← 純函式，組出 prompt 字串
    ↓
ContentGenerationService ← 快取查詢 + 懶生成 + 500ms 批次
    ↓
SwiftData Cache (GeneratedContentModel)
```

### API Key 儲存：Keychain

**絕對不能**放在 Info.plist 或 UserDefaults — `.ipa` 解壓縮後任何人都能讀到。

Keychain 使用 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`：
- 裝置鎖定時無法讀取（安全）
- 解鎖後在背景也能讀取（遊戲正常運作）

### 500ms 批次視窗（Batching）

當玩家開啟英雄列表，多張卡片同時進入畫面，如果每張都立即打 API 會造成大量請求。

解法：收集 500ms 內的所有請求，一次用 `TaskGroup` 並行送出。

```
Hero Card 1 → 加入待發佇列 ─┐
Hero Card 2 → 加入待發佇列  ├→ 等 500ms → 一次並行發出 3 個請求
Hero Card 3 → 加入待發佇列 ─┘
```

### 5 種 Prompt 模板

| 類型 | 最大 Token | 範例 Prompt |
|------|-----------|-------------|
| `heroName` | 20 | "Generate a single fantasy hero name for a warrior. Name only, max 3 words." |
| `heroLore` | 200 | "Write a 2-sentence backstory for {name} the {class}. Max 40 words." |
| `itemFlavor` | 100 | "Write a 1-2 sentence description for a rare item called '{name}'. Max 25 words." |
| `offlineSummary` | 250 | "Narrate 2-3 sentences about heroes who fought in {zone} for {hours}h, won {n} battles." |
| `randomEvent` | 150 | "Generate a short mysterious event for a [{classes}] party in {zone}. Max 30 words." |

### 錯誤處理：降級文字（Fallback）

如果 API 失敗（無網路、Key 無效等），顯示預設文字而非 crash：

```swift
AppConstants.Fallback.heroLore   = "A seasoned warrior whose past is shrouded in mystery..."
AppConstants.Fallback.itemFlavor = "Forged in forgotten fires. Its purpose clear, its origin unknown."
```

---

## 畫面結構

```
ContentView (TabView — 3 個 Tab)
├── Tab 0: 戰鬥 (BattleTabView)
│   ├── 目前區域資訊（名稱、預估金幣/小時）
│   ├── 上場英雄列表 (HeroPartyRow × 3)
│   ├── 戰鬥進度指示（下一場戰鬥倒數）
│   └── 換區 Sheet (ZoneSelectionSheet)
│
├── Tab 1: 英雄 (HeroRosterView)
│   ├── 英雄卡片列表 (HeroCard)
│   │   └── 點開 → HeroDetailView (包含 AI 生成的故事)
│   └── 召喚按鈕（花費 300 金幣）
│
└── Tab 2: 裝備 (EquipmentInventoryView)
    ├── 稀有度篩選
    └── 裝備卡片 → EquipmentDetailView (包含 AI 生成的描述)

彈出 Modal（疊在 ContentView 上）
├── OfflineSummaryModal  — 回到遊戲時顯示
└── RandomEventModal     — 戰鬥中 15% 機率觸發
```

### 非同步 AI 文字的 UX 流程

```
使用者開啟英雄詳情
    ↓
HeroDetailView .task { } 觸發
    ↓
ContentGenerationService.requestContent(for: .heroLore)
    ↓
    ├─ 快取存在 → 立即回傳 ✓
    └─ 快取不存在 → 顯示 AILoadingPlaceholder (shimmer 動畫)
                        ↓
                   Claude API 回傳
                        ↓
                   存入快取 + 顯示文字 ✓
```

---

## 關鍵設計決策

### 1. 為什麼用 XcodeGen？
`.xcodeproj` 是 XML，每次 Xcode 自動修改都會產生大量 git diff 噪音。
`project.yml` 是乾淨的 YAML，git history 清晰可讀。
在 Mac 上執行 `xcodegen generate` 就能產生 `.xcodeproj`（不進 git）。

### 2. 為什麼用 `claude-haiku-4-5` 而非 Sonnet？
遊戲文字生成不需要高度推理能力，Haiku 速度更快（玩家等待時間短）且便宜約 15×。
預估一般玩家每天費用 < $0.005 USD。

### 3. 靜態資料為什麼不放 JSON？
Hero class、Zone、Equipment 的定義在 Swift struct 裡有完整型別安全和 autocomplete。
JSON 需要額外解析層，且在這個規模沒有必要。遊戲資料更新時直接改 Swift 檔即可。

### 4. 為什麼使用 `@Observable` 而非 `ObservableObject`？
iOS 17+ 新 macro，更少樣板程式碼，且提供 property-level 細粒度觀察，
減少不必要的 SwiftUI re-render。

### 5. 離線計算為什麼不用伺服器驗證？
這是 single-player 遊戲，沒有排行榜或多人競爭，
確定性本地計算已足夠防止絕大部分作弊行為，不需要後端成本。
