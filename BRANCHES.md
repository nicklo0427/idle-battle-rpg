# BRANCHES.md — 分支與工作樹規則

> 本文件記錄分支用途與固定工作流。每次開始較大修改前，先看這裡與 `git status --short --branch`。

---

## 目前分支

| 分支 | 用途 / 狀態 |
|---|---|
| `master` | 唯一長期基準分支；所有新工作分支都從最新 `master` 拉出 |
| `sit` | SIT 驗收分支；需要時從 `master` 重新建立，可刪除重建 |
| `origin/master` | 遠端長期基準分支 |
| `origin/sit` | 遠端 SIT 驗收分支，應與本機 `sit` 同步 |

`git branch` 輸出中帶 `+` 的分支代表已被其他 worktree checkout；不要在目前 worktree 直接操作它們。

---

## 固定分支流程

- **新功能 / 修 bug / 文件整理一律從最新 `master` 拉分支**，不要從 `sit` 或其他功能分支開始。
- `sit` 只用於整合驗收。SIT 驗收完成後，先 fast-forward / merge 回 `master`，再視需要重建新的 `sit`。
- 不使用 force push 更新 `master`。除非使用者明確要求，也不要 force push `sit`。

開始新工作：

```bash
git fetch origin --prune
git switch master
git pull --ff-only origin master
git switch -c codex/<short-task-name>
```

刷新 SIT：

```bash
git fetch origin --prune
git switch master
git pull --ff-only origin master
git branch -D sit
git push origin --delete sit
git switch -c sit master
git push -u origin sit
```

---

## 協作規則

- 新工作分支預設使用 `codex/` 前綴，除非使用者指定其他命名。
- Claude 工作分支建議使用 `claude/` 前綴，但同樣必須從最新 `master` 拉出。
- 文件整理、ticket 補齊、程式功能修改盡量拆不同分支；避免把大量資產生成檔與程式修正混在同一個 commit。
- 在髒工作樹上切分支前，先確認髒檔是否與任務相關；不相關時只記錄，不回復、不刪除。
- 不要操作其他 worktree 正在使用的 `claude/...` 分支。
- `.claude/`、`art-assets/generated/` 是本機暫存 / 生成輸出，已在 `.gitignore`，不要提交。

---

## 常用檢查命令

```bash
git status --short --branch
git branch --list --sort=-committerdate
git log --oneline -8
git merge-base --is-ancestor master sit
xcodebuild -project IdleBattleRPG.xcodeproj -scheme IdleBattleRPG -destination 'generic/platform=iOS Simulator' build
```
