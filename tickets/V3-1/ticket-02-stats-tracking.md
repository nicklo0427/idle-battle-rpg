# V3-1 Ticket 02：統計資料追蹤（Service 層埋點）

**狀態：** ✅ 完成

**依賴：** Ticket 01（統計欄位存在）

---

## 目標

在現有 Service 的入帳流程中更新 Ticket 01 新增的統計欄位。
原則：**只在已有 context.save() 的地方順手更新**，不新增額外 save 呼叫。

---

## 修改一：SettlementService.commitResults()

**檔案：** `IdleBattleRPG/Services/SettlementService.swift`

在 `commitResults(task:player:inventory:)` 內，寫入 player 欄位後、`context.save()` 前加入：

```swift
// 統計追蹤
player.totalGoldEarned += task.resultGold

if task.kind == .dungeon {
    player.totalBattlesWon  += task.resultBattlesWon  ?? 0
    player.totalBattlesLost += task.resultBattlesLost ?? 0
}

if task.resultCraftedEquipKey != nil {
    player.totalItemsCrafted += 1
}
```

---

## 修改二：highestPowerReached 更新

**檔案：** `IdleBattleRPG/AppState.swift`

在 `tick` 計時器觸發時（每秒），比對當前戰力並更新歷史最高值：

```swift
// tick handler 內（已有每秒觸發邏輯）
if let player = fetchPlayer(),
   let stats = HeroStatsService.compute(player: player, equipped: fetchEquipped()) {
    if stats.power > player.highestPowerReached {
        player.highestPowerReached = stats.power
        try? modelContext.save()
    }
}
```

> `fetchPlayer()` / `fetchEquipped()` 使用 AppState 內現有的 ModelContext 查詢，
> 與 scanAndSettle() 同樣的查詢方式。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Services/SettlementService.swift` | ✏️ 修改（commitResults 加統計更新） |
| `AppState.swift` | ✏️ 修改（tick handler 加 highestPower 更新） |

---

## 驗收標準

- [ ] 出征 1 場（5 勝 0 敗）→ totalBattlesWon +5，totalGoldEarned += 實際金幣
- [ ] 鑄造完成收下 → totalItemsCrafted +1
- [ ] Boss 武器掉落收下 → totalItemsCrafted +1
- [ ] 裝備新裝備提升戰力 → highestPowerReached 更新（最多 1 秒延遲）
- [ ] Build 無錯誤
