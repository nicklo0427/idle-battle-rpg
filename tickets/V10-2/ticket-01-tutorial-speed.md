# V10-2 T01 — 教程任務加速（2 秒）

## 狀態：✅ 已完成

## 目標

將 4 個教程專用任務的完成時長從 5 秒縮短至 2 秒，保留視覺回饋，減少玩家等待感。

## 設計

- 教程採集、教程鑄造武器、教程探索、教程防具鑄造各 2 秒
- 按鈕文字同步更新（「5 秒」→「2 秒」）
- 視覺 UI 不變（進度條、NPC 卡狀態仍正常顯示）

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Services/TaskCreationService.swift` | `createTutorialGatherTask` / `createTutorialCraftTask` / `createTutorialExploreTask` / `createTutorialArmorTask` 中 `addingTimeInterval(5)` → `addingTimeInterval(2)` ✅ |
| `Views/GathererDetailSheet.swift` | 按鈕文字「5 秒」→「2 秒」 ✅ |
| `Views/CraftSheet.swift` | 按鈕文字「5 秒」→「2 秒」，對話文字同步 ✅ |
| `Views/ArmorSheet.swift` | 按鈕文字「5 秒」→「2 秒」，對話文字同步 ✅ |

## 驗收

1. 重置教程（Dev 工具），確認 4 個教程任務 2 秒內完結
2. 按鈕文字顯示「2 秒」
3. 進度條在 2 秒內正常從 0 跑到滿
