# V2-3 Ticket 03：NpcUpgradeService

**狀態：** ✅ 完成

**依賴：** Ticket 01（NpcUpgradeDef）、Ticket 02（PlayerStateModel 欄位）

---

## 目標

建立 `NpcUpgradeService`，封裝 NPC 升級的驗證與金幣扣除邏輯，並注入至 `AppState`。

---

## 新建檔案

`IdleBattleRPG/Services/NpcUpgradeService.swift`

```swift
// NpcUpgradeService.swift
// NPC 效率升級業務邏輯：驗證 tier 上限、扣除金幣、遞增 tier

import Foundation
import SwiftData

// MARK: - 錯誤類型

enum NpcUpgradeError: Error {
    case alreadyMaxTier
    case insufficientGold

    var message: String {
        switch self {
        case .alreadyMaxTier:    return "已達升級上限"
        case .insufficientGold:  return "金幣不足"
        }
    }
}

// MARK: - NpcUpgradeService

struct NpcUpgradeService {
    let context: ModelContext

    /// 升級指定 NPC
    /// - Parameters:
    ///   - npcKind: `.gatherer` 或 `.blacksmith`
    ///   - actorKey: `"gatherer_1"` / `"gatherer_2"` / `"blacksmith"`
    ///   - player: 玩家狀態（單例）
    @discardableResult
    func upgrade(
        npcKind:  NpcKind,
        actorKey: String,
        player:   PlayerStateModel
    ) -> Result<Void, NpcUpgradeError> {

        let currentTier = player.tier(for: actorKey)

        guard currentTier < NpcUpgradeDef.maxTier else {
            return .failure(.alreadyMaxTier)
        }

        guard let cost = NpcUpgradeDef.goldCost(npcKind: npcKind, fromTier: currentTier) else {
            return .failure(.alreadyMaxTier)
        }

        guard player.gold >= cost else {
            return .failure(.insufficientGold)
        }

        player.gold -= cost

        switch actorKey {
        case "gatherer_1": player.gatherer1Tier += 1
        case "gatherer_2": player.gatherer2Tier += 1
        case "blacksmith":  player.blacksmithTier += 1
        default: break
        }

        try? context.save()
        return .success(())
    }

    // MARK: - 便利查詢

    /// 下一次升級費用；`nil` 表示已達上限
    func nextUpgradeCost(npcKind: NpcKind, actorKey: String, player: PlayerStateModel) -> Int? {
        NpcUpgradeDef.goldCost(npcKind: npcKind, fromTier: player.tier(for: actorKey))
    }
}
```

---

## 修改檔案

`IdleBattleRPG/AppState.swift`

```swift
// 新增屬性
let npcUpgradeService: NpcUpgradeService

// init 中新增
self.npcUpgradeService = NpcUpgradeService(context: context)
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Services/NpcUpgradeService.swift` | ✨ 新建 |
| `AppState.swift` | ✏️ 修改（+1 service）|

> 建立新 `.swift` 檔後需執行 `xcodegen generate`。

---

## 驗收標準

- [ ] 建立後 `xcodegen generate` + build 無錯誤
- [ ] `upgrade()` 在 tier 已達上限時回傳 `.failure(.alreadyMaxTier)`
- [ ] `upgrade()` 在金幣不足時回傳 `.failure(.insufficientGold)`
- [ ] `upgrade()` 成功時扣除金幣、tier +1、`context.save()` 呼叫
- [ ] `AppState` 有 `npcUpgradeService` 屬性
