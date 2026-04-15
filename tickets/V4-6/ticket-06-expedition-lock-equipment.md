# Ticket T06 — 出征中鎖定換裝

## 問題
英雄出征中仍可切換裝備，雖然 `snapshotPower` 在出發時已固定，但規則上不應允許。

## 解法
英雄出征中（有進行中的 `.dungeon` 任務），禁止切換裝備、卸除裝備、強化裝備。
裝備槽顯示鎖頭 + "出征中" 字樣；tap 無反應。

## 修改的檔案

### `IdleBattleRPG/Views/CharacterView.swift`
1. 新增 `@Query private var tasks: [TaskModel]`
2. 新增 `isOnExpedition: Bool` 計算屬性
3. `equippedSlotRow`:
   - 出征中：顯示 `lock.fill` + "出征中" badge，隱藏強化/卸除按鈕
   - `onTapGesture` 加守衛：`guard !isOnExpedition else { return }`

## 驗證
- 出征中，裝備槽顯示鎖頭圖示和「出征中」文字
- 出征中，點擊裝備槽無任何反應
- 出征結束後，正常操作恢復
