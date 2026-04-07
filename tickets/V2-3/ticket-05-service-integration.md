# V2-3 Ticket 05：TaskCreationService / SettlementService 整合

**狀態：** ✅ 完成

**依賴：** Ticket 02（PlayerStateModel 欄位）、Ticket 03（NpcUpgradeService）

---

## 目標

將 NPC 升級效果接入核心任務流程：
1. **鑄造師**：建立鑄造任務時，依 `blacksmithTier` 縮短 `endsAt`
2. **採集者**：結算入帳時，依採集者 tier 對每種素材加上 bonus

---

## 修改一：TaskCreationService — 鑄造時間縮短

**檔案：** `IdleBattleRPG/Services/TaskCreationService.swift`

在 `createCraft()` 計算任務時長的位置，套用鑄造倍率：

```swift
// 修改前（示意）
let durationSec = recipe.durationSeconds

// 修改後
let multiplier   = NpcUpgradeDef.craftDurationMultiplier(tier: player.blacksmithTier)
let durationSec  = max(30, Int(Double(recipe.durationSeconds) * multiplier))
```

- `max(30, ...)` 確保時長不低於 30 秒（新手加速保底 floor）
- 首次鑄造加速（`hasUsedFirstCraftBoost`）的 `durationOverride: 30` 邏輯不受影響（override 優先）

---

## 修改二：SettlementService — 採集入帳加成

**檔案：** `IdleBattleRPG/Services/SettlementService.swift`

在 `commitResults()` 處理採集任務素材入帳的區段，加入 bonus：

```swift
// 只對 .gather 任務加 bonus
if task.kind == .gather {
    let bonus = NpcUpgradeDef.gatherBonus(tier: player.tier(for: task.actorKey))
    // 對所有非零的素材結果各加 bonus
    if task.resultWood        > 0 { inventory.wood        += bonus }
    if task.resultOre         > 0 { inventory.ore         += bonus }
    if task.resultHide        > 0 { inventory.hide        += bonus }
    if task.resultCrystalShard   > 0 { inventory.crystalShard   += bonus }
    if task.resultAncientFragment > 0 { inventory.ancientFragment += bonus }
    // V2-1 新素材同理
}
```

> **重要設計決策**：`TaskModel` 的 `result*` 欄位**不修改**（保持確定性 RNG 的 source of truth）。bonus 只在入帳（commitResults）時計算並加入庫存，不寫回 TaskModel。

### 加成對象說明

- 採集任務通常只含一種主素材，但有些地點可能有次要素材
- 對「所有 > 0 的素材欄位」各加 bonus，確保行為一致，不需查 GatherLocationDef

---

## 影響範圍

| 檔案 | 動作 | 說明 |
|---|---|---|
| `Services/TaskCreationService.swift` | ✏️ 修改 | 鑄造時長計算套用 craftDurationMultiplier |
| `Services/SettlementService.swift` | ✏️ 修改 | 採集入帳加 gatherBonus |

---

## 驗收標準

- [ ] 鑄造師 Tier 0 時鑄造時長與原本相同
- [ ] 鑄造師 Tier 1（×0.85）：60 分鐘配方 → 51 分鐘；30 秒 floor 有效
- [ ] 鑄造師 Tier 3（×0.65）：60 分鐘配方 → 39 分鐘
- [ ] 首次鑄造加速（30 秒）不受 Tier 影響（durationOverride 覆蓋整個 endsAt）
- [ ] 採集者 Tier 0 時入帳素材量與原本相同
- [ ] 採集者 Tier 2 時，每種有產出的素材各 +2
- [ ] `TaskModel.result*` 欄位未被修改（debugger 驗證）
- [ ] 現有地下城結算無回歸
