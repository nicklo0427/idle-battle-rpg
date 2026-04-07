# V3-1 Ticket 01：PlayerStateModel 統計欄位

**狀態：** ✅ 完成

**依賴：** 無（第一張）

---

## 目標

玩家目前沒有任何累積統計資料，無法知道自己總共打了幾場、賺了多少金幣。
本 ticket 在 PlayerStateModel 加入 5 個統計欄位，作為後續統計 UI 的資料來源。

---

## 修改檔案

`IdleBattleRPG/Models/PlayerStateModel.swift`

### 新增欄位（SwiftData @Attribute，初始值 0）

```swift
// MARK: - 累計統計
var totalGoldEarned: Int = 0      // 累計獲得金幣（採集 / 地下城 / 任何入帳來源）
var totalBattlesWon: Int = 0      // 累計地下城勝場
var totalBattlesLost: Int = 0     // 累計地下城敗場
var totalItemsCrafted: Int = 0    // 累計裝備獲得件數（鑄造 + Boss 武器掉落）
var highestPowerReached: Int = 0  // 歷史最高英雄戰力
```

> ⚠️ SwiftData 新增欄位會自動做輕量 migration（有預設值即可），無需手動 migration plan。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Models/PlayerStateModel.swift` | ✏️ 修改（新增 5 個欄位） |

---

## 驗收標準

- [ ] 5 個欄位存在於 PlayerStateModel
- [ ] 初始值皆為 0
- [ ] App 首次啟動（資料庫已存在）不 crash（SwiftData migration 正常）
- [ ] Build 無錯誤
