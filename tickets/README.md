# tickets/README.md — Ticket 索引

> `tickets/` 只放版本規劃與驗收紀錄，不放長篇總覽。專案總覽看 `README.md`，歷史開發紀錄看 `PROGRESS.md`。

---

## 目錄狀態

| 目錄 | 狀態 | 主題 |
|---|---|---|
| `V8-1/` | ✅ 完成 | 裝備稀有度擴充、稀有 / 史詩配方、強化上限 |
| `V8-2/` | ✅ 大多完成 | 農場重構、生產者技能、商人 UX、本地通知 |
| `V8-3/` | ✅ 完成 | Lv.30、進階技能、戰場統計、個人最佳、地區主題重設計 |
| `V9-1/` | ✅ 完成 | 視覺資產盤點、怪物圖、基地圖、冒險 UI polish、角色 icon |
| `V9-2/` | ✅ 完成 | 基地 NPC grid、裝備 / 背包 grid、冒險區域卡 spacing |
| `V10-1/` | ✅ 完成 | 開場敘事、英雄命名、職業背景、NPC 首次對話、裝備導引 |
| `V10-2/` | ✅ 完成 | 教程速度、提示 banner、職業戰力預覽、NPC 命名、菁英戰、裁縫師調整 |
| `V10-3/` | ✅ 完成 | 教程 UX 審查、移除重複 banner、引導按鈕整合原生 UI |
| `future/` | 📋 後續 | 多戰鬥系統、SVG 素材圖示等未排期想法 |

---

## 目前焦點

V10-3 是當前最新工作面：

- `ticket-01-tutorial-ux-audit.md`：列出 step 0–7 的 UX 問題。
- `ticket-02-remove-duplicate-banner.md`：移除 AdventureView step 4 重複橫幅。
- `ticket-03-step5-navigation-button.md`：step 5 導航按鈕決策，現況採用 onAppear 自動推進方向。
- `ticket-04-merge-tutorial-into-native-ui.md`：將 step 0 / 2 / 6 / 7 的引導按鈕整合進正常 UI。

---

## 寫票格式

每張 ticket 建議包含：

- `狀態`：待實作 / 進行中 / 已完成 / 延後。
- `目標`：一句話說明玩家或工程收益。
- `設計`：資料流、UI 行為、服務層責任。
- `修改檔案`：列出預期或實際變動。
- `驗收`：用可操作步驟描述，不只寫「看起來正常」。

---

## 文件整理規則

- 完成票據後，將 `狀態` 更新，不一定要搬移檔案。
- 版本總結寫在 `PROGRESS.md`，ticket 細節留在各 ticket 檔。
- 若 ticket 和程式實作不一致，以程式碼為準，並補一段「實作後調整」說明。
