// NpcUpgradeDef.swift
// NPC 效率升級系統靜態規則：等級上限、各 NPC 升級成本、採集 bonus、鑄造縮短倍率
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - NPC 種類

enum NpcKind: String, CaseIterable {
    case woodcutter   // 伐木工
    case miner        // 採礦工
    case blacksmith
    case herbalist    // 採藥師
    case fisherman    // 漁夫
    case chef         // 廚師（V7-3）
    case farmer       // 農夫（V7-4）
    case pharmacist   // 製藥師（V7-4）
}

// MARK: - 升級成本定義

struct NpcUpgradeCostDef {
    /// 從此 Tier 升到下一 Tier（0→1, 1→2, 2→3）
    let fromTier:      Int
    let expCost:       Int
    let materialCosts: [(MaterialType, Int)]   // 可為空陣列
    let goldCost:      Int
}

// MARK: - NPC 升級靜態規則

enum NpcUpgradeDef {

    /// 升級等級上限（Tier 0 到 Tier 3）
    static let maxTier = 3

    // MARK: 伐木工升級成本（EXP + 木材 + 金幣）
    //
    // Tier 1：入門門檻低，消耗自身採集的木材
    // Tier 2：需要更多累積，木材量翻倍
    // Tier 3：需要一定採集時數

    static let woodcutterCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:  60, materialCosts: [(.wood, 10)], goldCost:  300),
        .init(fromTier: 1, expCost: 180, materialCosts: [(.wood, 20)], goldCost:  800),
        .init(fromTier: 2, expCost: 450, materialCosts: [(.wood, 40)], goldCost: 1800),
    ]

    // MARK: 採礦工升級成本（EXP + 礦石 + 金幣）
    //
    // 與伐木工對稱設計，素材需求對應職業專長

    static let minerCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:  60, materialCosts: [(.ore, 10)], goldCost:  300),
        .init(fromTier: 1, expCost: 180, materialCosts: [(.ore, 20)], goldCost:  800),
        .init(fromTier: 2, expCost: 450, materialCosts: [(.ore, 40)], goldCost: 1800),
    ]

    // MARK: 採藥師升級成本（EXP + 草藥 + 金幣）

    static let herbalistCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:  60, materialCosts: [(.herb, 10)], goldCost:  300),
        .init(fromTier: 1, expCost: 180, materialCosts: [(.herb, 20)], goldCost:  800),
        .init(fromTier: 2, expCost: 450, materialCosts: [(.herb, 40)], goldCost: 1800),
    ]

    // MARK: 漁夫升級成本（EXP + 鮮魚 + 金幣）

    static let fishermanCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:  60, materialCosts: [(.freshFish, 10)], goldCost:  300),
        .init(fromTier: 1, expCost: 180, materialCosts: [(.freshFish, 20)], goldCost:  800),
        .init(fromTier: 2, expCost: 450, materialCosts: [(.freshFish, 40)], goldCost: 1800),
    ]

    // MARK: 鑄造師升級成本（EXP + 素材 + 金幣）

    static let blacksmithCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:   80, materialCosts: [(.ore,             10)], goldCost:  400),
        .init(fromTier: 1, expCost:  250, materialCosts: [(.crystalShard,     5)], goldCost: 1200),
        .init(fromTier: 2, expCost:  700, materialCosts: [(.ancientFragment,  3)], goldCost: 2500),
        // V8-1：第 4 階，需沉沒之城 Boss 素材
        .init(fromTier: 3, expCost: 2000, materialCosts: [(.sunkenKingSeal,   3)], goldCost: 8000),
    ]

    // MARK: 廚師升級成本（EXP + 魚類素材 + 金幣）
    //
    // 廚師 Tier 縮短烹飪時間（複用 craftDurationMultiplier）：
    // Tier 0：1.0x，Tier 1：0.85x，Tier 2：0.75x，Tier 3：0.65x

    static let chefCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost:  80, materialCosts: [(.freshFish, 20)],                          goldCost:  400),
        .init(fromTier: 1, expCost: 250, materialCosts: [(.abyssFish, 10)],                          goldCost:  800),
        .init(fromTier: 2, expCost: 700, materialCosts: [(.abyssFish, 20), (.spiritHerb, 10)],       goldCost: 1500),
    ]

    // MARK: 農夫升級成本（V7-4）
    //
    // Tier 升級解鎖新農田（availablePlots = tier + 1）並提升頂級作物機率
    // 升級素材使用種子，強化農田玩法的循環感

    static let farmerCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost: 100, materialCosts: [(.wheatSeed, 5)],                              goldCost:  300),
        .init(fromTier: 1, expCost: 300, materialCosts: [(.vegetableSeed, 5), (.fruitSeed, 1)],         goldCost:  700),
        .init(fromTier: 2, expCost: 800, materialCosts: [(.fruitSeed, 3), (.spiritGrainSeed, 2)],       goldCost: 1500),
    ]

    // MARK: 製藥師升級成本（V7-4）
    //
    // 製藥師 Tier 縮短釀製時間（複用 craftDurationMultiplier）

    static let pharmacistCosts: [NpcUpgradeCostDef] = [
        .init(fromTier: 0, expCost: 120, materialCosts: [(.herb, 20)],                           goldCost:  500),
        .init(fromTier: 1, expCost: 350, materialCosts: [(.spiritHerb, 10)],                     goldCost: 1000),
        .init(fromTier: 2, expCost: 900, materialCosts: [(.spiritHerb, 20), (.wheat, 10)],       goldCost: 2000),
    ]

    // MARK: 採集者每 Tier 加成
    //
    // Tier 0：+0（基礎）
    // Tier 1：+1 每種素材（固定值，加在 RNG 結果後入帳）
    // Tier 2：+2 每種素材
    // Tier 3：+3 每種素材
    //
    // 效益：採集任務（30 分）木材基準 6 件，Tier 3 +3 等效縮短採集週期 33%~50%
    // 若 +3 不夠感受：改為 +5；若過強：改為 +2

    static func gatherBonus(tier: Int) -> Int {
        max(0, tier)
    }

    // MARK: 鑄造師每 Tier 縮短倍率
    //
    // Tier 0：1.00（不縮短）
    // Tier 1：0.85（縮短 15%）
    // Tier 2：0.75（縮短 25%）
    // Tier 3：0.65（縮短 35%）
    // Tier 4：0.55（縮短 45%）V8-1
    // 下限 30 秒（TaskCreationService 的 max(30, ...) 保護）

    private static let craftMultipliers: [Double] = [1.0, 0.85, 0.75, 0.65, 0.55]

    static func craftDurationMultiplier(tier: Int) -> Double {
        guard tier >= 0, tier < craftMultipliers.count else { return 1.0 }
        return craftMultipliers[tier]
    }

    // MARK: - 便利查詢

    /// 從 `fromTier` 升一級的完整成本；超出範圍時回傳 `nil`
    static func upgradeCost(npcKind: NpcKind, fromTier: Int) -> NpcUpgradeCostDef? {
        switch npcKind {
        case .woodcutter:  return woodcutterCosts.first  { $0.fromTier == fromTier }
        case .miner:       return minerCosts.first        { $0.fromTier == fromTier }
        case .blacksmith:  return blacksmithCosts.first  { $0.fromTier == fromTier }
        case .herbalist:   return herbalistCosts.first   { $0.fromTier == fromTier }
        case .fisherman:   return fishermanCosts.first   { $0.fromTier == fromTier }
        case .chef:        return chefCosts.first        { $0.fromTier == fromTier }
        case .farmer:      return farmerCosts.first      { $0.fromTier == fromTier }
        case .pharmacist:  return pharmacistCosts.first  { $0.fromTier == fromTier }
        }
    }
}
