# BRANCHES.md — 分支與工作樹整理

> 本文件記錄目前本機分支狀態與後續整理規則。每次開始較大修改前，先看這裡與 `git status --short --branch`。

---

## 目前分支

| 分支 | 用途 / 狀態 |
|---|---|
| `sit` | 目前主要整合分支，V10 教程 / 資產整理工作多半在這裡累積 |
| `master` | 主要長期基準分支 |
| `claude/agitated-morse-91da38` | 其他 worktree 使用中的 Claude 分支，避免直接切換或刪除 |
| `claude/jovial-keller-a058ca` | 其他 worktree 使用中的 Claude 分支，避免直接切換或刪除 |
| `codex/docs-branch-cleanup` | 本次文件 / 分支整理分支 |

`git branch` 輸出中帶 `+` 的分支代表已被其他 worktree checkout；不要在目前 worktree 直接操作它們。

---

## 目前未提交項目

以下項目在整理開始前已存在，視為既有工作，不要清掉：

- `tickets/V10-1/ticket-05-starter-equipment.md` 有修改，內容是配合 T06 教程調整初始裝備發放時機。
- `tickets/V10-3/` 為新手引導 UX 審查與原生 UI 整合 tickets。
- `IdleBattleRPG/Resources/npc_jeweler.webp`、`npc_tailor.webp`、`npc_weaponsmith.webp` 為新增 NPC 圖。
- `art-assets/generated/` 為美術生成與檢查輸出。
- `.claude/` 為本機 Claude 工作資料。

---

## 分支規則

- 新工作分支預設使用 `codex/` 前綴，除非使用者指定其他命名。
- 文件整理、ticket 補齊、程式功能修改盡量拆不同分支；避免把大量資產生成檔與程式修正混在同一個 commit。
- 在髒工作樹上切分支前，先確認髒檔是否與任務相關；不相關時只記錄，不回復、不刪除。
- 不要操作其他 worktree 正在使用的 `claude/...` 分支。

---

## 常用檢查命令

```bash
git status --short --branch
git branch --list --sort=-committerdate
git log --oneline -8
xcodebuild -project IdleBattleRPG.xcodeproj -scheme IdleBattleRPG -destination 'generic/platform=iOS Simulator' build
```
