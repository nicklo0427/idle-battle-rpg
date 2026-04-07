# 放置英雄

iOS 放置 RPG。玩家利用生活空檔派英雄出征地下城、委託採集者蒐集素材、讓鑄造師打造裝備，讓自己越來越強。

**MVP 純本地單機**，無後端、無帳號、無社交。

---

## Tech Stack

| 項目 | 技術 |
|---|---|
| 語言 | Swift 5.9+ |
| UI | SwiftUI |
| 持久化 | SwiftData (iOS 17+) |
| 最低系統 | iOS 17.0 |
| 專案管理 | XcodeGen（`project.yml`） |

> `.xcodeproj` 不進 git，由 XcodeGen 產生。

---

## 快速開始

```bash
# 1. Clone
git clone https://github.com/nicklo0427/idle-battle-rpg.git
cd idle-battle-rpg

# 2. 產生 Xcode 專案
xcodegen generate

# 3. 開啟
open IdleBattleRPG.xcodeproj
```

---

## 專案結構

```
idle-battle-rpg/
├── project.yml                        ← XcodeGen 設定
├── CLAUDE.md                          ← AI 協作說明（給 Claude Code 讀）
├── MVP_SPEC_FINAL.md                  ← MVP 規格（唯一設計事實來源）
├── V2_1_DUNGEON_PROGRESSION_SPEC.md   ← V2-1 規格
├── PROGRESS.md                        ← 開發進度紀錄
├── CHECKLIST.md                       ← TestFlight 實機驗證清單
├── tickets/
│   └── V2-1/                         ← V2-1 工單（Ticket 01–）
└── IdleBattleRPG/
    ├── IdleBattleRPGApp.swift
    ├── AppState.swift
    ├── AppConstants.swift
    ├── Models/                        ← SwiftData @Model
    ├── StaticData/                    ← 純 Swift struct（不進 DB）
    ├── Services/                      ← 業務邏輯 + CRUD
    ├── ViewModels/
    └── Views/
```

---

## 開發進度

| 狀態 | 階段 |
|---|---|
| ✅ 完成 | MVP Phase 1–12（資料層、Service、全部 UI、商人、Onboarding）|
| ✅ 完成 | V2-1 Ticket 01（地下城靜態資料正式化）|
| ✅ 完成 | V2-1 Ticket 02（區域素材 SwiftData 正式化）|
| ✅ 完成 | V2-1 Ticket 03（地下城推進狀態模型）|
| 🔜 待實作 | V2-1 Ticket 04（AdventureView 重構）|
| 🔜 待實作 | V2-1 Ticket 05（CharacterView 4 部位裝備槽）|
| 🔜 待實作 | V2-1 Ticket 06（V2-1 鑄造配方與 CraftSheet 擴充）|
| 🔜 待實作 | V2-1 Ticket 07（首通裝備解鎖邏輯）|
| 🔜 待實作 | V2-1 Ticket 08（Boss 武器浮動數值 Farming）|
| 🔜 待實作 | V2-1 Ticket 09（數值平衡）|

詳細進度見 [PROGRESS.md](PROGRESS.md)，工單內容見 [tickets/V2-1/](tickets/V2-1/)。
