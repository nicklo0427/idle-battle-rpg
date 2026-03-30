# Idle Battle RPG

A minimalist AFK idle battle game for iOS, powered by Claude AI for generating hero lore, item descriptions, and battle narratives.

---

## 概覽 Overview

玩家組建一支英雄隊伍，讓英雄自動在地圖區域戰鬥（AFK），離線時也持續累積金幣與裝備。
Claude AI 負責生成每位英雄的背景故事、道具描述，以及回到遊戲時的「你不在時發生了什麼」敘事。

---

## 核心玩法

| 系統 | 說明 |
|------|------|
| AFK 戰鬥 | 英雄自動在選定區域戰鬥，離線最多累積 8 小時成果 |
| 資源收集 | 戰鬥勝利獲得金幣與隨機裝備掉落 |
| 英雄管理 | 最多 3 位英雄上場，可升級屬性（ATK / DEF / HP） |
| Claude AI | 生成英雄名稱、背景故事、道具描述、離線摘要敘事 |
| 裝備系統 | 20+ 件裝備，3 種稀有度（Common / Rare / Epic） |

---

## Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Persistence**: SwiftData (iOS 17+)
- **Networking**: URLSession + async/await
- **AI**: Claude API (`claude-haiku-4-5-20251001`)
- **Secret Storage**: iOS Keychain (API key)
- **Minimum iOS**: 17.0

---

## 快速開始 Quick Start

### 前置需求

- macOS 14+ (Sonoma)
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Anthropic API Key（[取得](https://console.anthropic.com/)）

### 設定步驟

```bash
# 1. Clone 專案
git clone https://github.com/Nick-Wants-To-Be-A-Billionair/idle-battle-rpg.git
cd idle-battle-rpg

# 2. 產生 Xcode 專案
xcodegen generate

# 3. 用 Xcode 開啟
open IdleBattleRPG.xcodeproj
```

在 Xcode 中按 ▶ Run，第一次啟動時 App 會要求輸入你的 Anthropic API Key，存入 Keychain 後即可遊玩。

> **注意**：API Key 只在第一次輸入時儲存到 Keychain，之後重開 App 不需要重新輸入。

---

## 專案結構

```
idle-battle-rpg/
├── project.yml                    ← XcodeGen 設定（產生 .xcodeproj 用）
├── README.md
├── ARCHITECTURE.md                ← 架構與設計決策說明
└── IdleBattleRPG/
    ├── IdleBattleRPGApp.swift     ← @main 入口
    ├── AppConstants.swift         ← 所有遊戲數值（集中管理）
    ├── Models/                    ← SwiftData 資料模型
    ├── StaticData/                ← 靜態遊戲資料（英雄職業、區域、裝備）
    ├── Services/
    │   ├── Game/                  ← 遊戲邏輯（離線計算、戰鬥、升級）
    │   └── AI/                   ← Claude API 整合
    ├── ViewModels/                ← @Observable ViewModels
    ├── Views/                     ← SwiftUI 畫面
    └── Tests/                     ← 離線計算單元測試
```

詳細架構說明請見 [ARCHITECTURE.md](ARCHITECTURE.md)。

---

## Claude AI 在遊戲中的角色

Claude 只在以下 5 種情況呼叫 API，所有結果**永久快取**，不重複生成：

| 時機 | 內容 | 快取 Key |
|------|------|----------|
| 獲得新英雄 | 生成英雄名稱 | `hero_name_<UUID>` |
| 首次開啟英雄詳情 | 生成英雄背景故事 | `hero_lore_<UUID>` |
| 首次開啟道具詳情 | 生成道具描述 | `item_flavor_<defKey>` |
| 回到遊戲（離線 >5 分鐘） | 生成「你不在時...」摘要 | `offline_<dateStr>` |
| 戰鬥中隨機觸發（15%） | 生成隨機事件 | 不快取（每次隨機） |

### API 費用估算

使用 `claude-haiku-4-5-20251001`，一般玩家每天預估呼叫 5–15 次，
費用約 **$0.001–$0.005 USD/天**（極低成本）。

---

## 遊戲平衡數值

| 參數 | 數值 |
|------|------|
| 離線上限 | 8 小時 |
| 勝率（等同區域推薦戰力）| 50% |
| 勝率（2 倍推薦戰力）| ~95% |
| 勝率下限（再弱也有）| 10% |
| 升級費用倍率 | 1.18× per level |
| 召喚新英雄費用 | 300 金幣 |

---

## Roadmap

- [x] Phase 1：專案架構 + 靜態資料
- [x] Phase 2：離線計算引擎（確定性 RNG）
- [x] Phase 3：Claude API 整合（懶載入 + 快取）
- [ ] Phase 4：核心 SwiftUI 畫面
- [ ] Phase 5：裝備系統 + 隨機事件
- [ ] Phase 6：平衡測試 + 上架準備
