# V2-3 Ticket 01：NpcUpgradeDef 靜態資料

**狀態：** ✅ 完成

**依賴：** 無（第一張）

---

## 目標

建立 NPC 升級系統的靜態規則：升級等級上限、各 NPC 各等級的金幣成本、採集者每級加成、鑄造師每級縮短倍率。

---

## 新建檔案

`IdleBattleRPG/StaticData/NpcUpgradeDef.swift`

```swift
// NpcUpgradeDef.swift
// NPC 效率升級系統靜態規則：等級上限、各 NPC 升級成本、採集 bonus、鑄造縮短倍率
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - NPC 種類

enum NpcKind: String, CaseIterable {
    case gatherer
    case blacksmith
}

// MARK: - 升級成本定義

struct NpcUpgradeCostDef {
    /// 從此 Tier 升到下一 Tier（0→1, 1→2, 2→3）
    let fromTier: Int
    let goldCost: Int
}

// MARK: - NPC 升級靜態規則

enum NpcUpgradeDef {

    /// 升級等級上限（Tier 0 到 Tier 3）
    static let maxTier = 3

    // MARK: 採集者升級成本

    static let gathererCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, goldCost:  500),
        .init(fromTier: 1, goldCost: 1200),
        .init(fromTier: 2, goldCost: 2500),
    ]
    // 累計滿升費用：4,200 金幣

    // MARK: 鑄造師升級成本

    static let blacksmithCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, goldCost:  600),
        .init(fromTier: 1, goldCost: 1500),
        .init(fromTier: 2, goldCost: 3000),
    ]
    // 累計滿升費用：5,100 金幣

    // MARK: 採集者每 Tier 加成
    //
    // Tier 0：+0（基礎）
    // Tier 1：+1 每種素材（固定值，加在 RNG 結果後入帳）
    // Tier 2：+2 每種素材
    // Tier 3：+3 每種素材

    static func gatherBonus(tier: Int) -> Int {
        max(0, tier)
    }

    // MARK: 鑄造師每 Tier 縮短倍率
    //
    // Tier 0：1.00（不縮短）
    // Tier 1：0.85（縮短 15%）
    // Tier 2：0.75（縮短 25%）
    // Tier 3：0.65（縮短 35%）

    private static let craftMultipliers: [Double] = [1.0, 0.85, 0.75, 0.65]

    static func craftDurationMultiplier(tier: Int) -> Double {
        guard tier >= 0, tier < craftMultipliers.count else { return 1.0 }
        return craftMultipliers[tier]
    }

    // MARK: - 便利查詢

    /// 從 `fromTier` 升一級所需的金幣；超出範圍時回傳 `nil`
    static func goldCost(npcKind: NpcKind, fromTier: Int) -> Int? {
        let costs = npcKind == .gatherer ? gathererCosts : blacksmithCosts
        return costs.first { $0.fromTier == fromTier }?.goldCost
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `StaticData/NpcUpgradeDef.swift` | ✨ 新建 |

> 建立後需執行 `xcodegen generate` 重新產生 `.xcodeproj`，否則 build 找不到新型別。

---

## 驗收標準

- [ ] 檔案建立，`xcodegen generate` 成功
- [ ] Build 無錯誤
- [ ] `NpcUpgradeDef.goldCost(npcKind: .gatherer, fromTier: 0)` 回傳 `500`
- [ ] `NpcUpgradeDef.goldCost(npcKind: .blacksmith, fromTier: 2)` 回傳 `3000`
- [ ] `NpcUpgradeDef.gatherBonus(tier: 3)` 回傳 `3`
- [ ] `NpcUpgradeDef.craftDurationMultiplier(tier: 1)` 回傳 `0.85`
- [ ] `NpcUpgradeDef.goldCost(npcKind: .gatherer, fromTier: 3)` 回傳 `nil`（已達上限）
