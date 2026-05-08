# V10-2 T04 — NPC 命名重構（移除教程步驟 + 成就解鎖）

## 狀態：✅ 已完成

## 目標

- P4：移除 NpcIntroSection 中的命名輸入步驟，降低教程摩擦感
- OB：命名功能改為教程完成後才解鎖，作為進入完整遊戲的小獎勵

## 設計

### 新行為

**首次開啟 NPC Sheet（hasSeenIntro == false）：**
```
[對話氣泡] NPC 台詞文字
                         [明白了]
```
點「明白了」→ 直接 `markNpcIntroSeen`（無命名步驟）

**教程完成後（onboardingStep >= 8）+ 已看過：**
```
✏️ 修改名字                       現在叫：老鐵
```
點擊 → 顯示文字輸入列 → 確認 / 取消

**其他狀態（未看過 + 教程未完成）：** 不顯示任何內容

### 資料保留

- `npcNamesRaw` / `seenNpcIntroKeysRaw` 欄位保留（命名功能仍可用）
- `npcDisplayName(for:)` 邏輯不變

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Views/NpcIntroSection.swift` | 重寫：移除 `showNaming` + `namingRow`；`明白了` 直接呼叫 `markSeen()`；新增 `namingUnlocked` computed var（`onboardingStep >= 8`）；新增 `renameEntryRow` + `renamingRow` ✅ |

## 驗收

1. 首次開啟 NPC Sheet：顯示對話氣泡，點「明白了」直接關閉（無命名框出現）
2. 教程未完成時：已看過 NPC 的 Sheet 無任何 NpcIntroSection 內容
3. 教程完成後（step >= 8）：已看過 NPC 的 Sheet 顯示「✏️ 修改名字 / 現在叫：xxx」
4. 點「修改名字」→ 輸入框出現 → 確認後名字更新
5. 取消後輸入框收合，名字不變
