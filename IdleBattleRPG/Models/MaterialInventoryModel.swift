// MaterialInventoryModel.swift
// 玩家素材庫存的持久化模型（全域單例）

import Foundation
import SwiftData

@Model
final class MaterialInventoryModel {

    var wood: Int
    var ore: Int
    var hide: Int
    var crystalShard: Int
    var ancientFragment: Int

    init(
        wood: Int = AppConstants.Initial.wood,
        ore: Int = AppConstants.Initial.ore,
        hide: Int = 0,
        crystalShard: Int = 0,
        ancientFragment: Int = 0
    ) {
        self.wood            = wood
        self.ore             = ore
        self.hide            = hide
        self.crystalShard    = crystalShard
        self.ancientFragment = ancientFragment
    }

    // MARK: - 便利存取（依 MaterialType 讀寫）

    func amount(of material: MaterialType) -> Int {
        switch material {
        case .wood:            return wood
        case .ore:             return ore
        case .hide:            return hide
        case .crystalShard:    return crystalShard
        case .ancientFragment: return ancientFragment
        // V2-1 區域素材：Ticket 02 新增 SwiftData 欄位前，暫回傳 0
        case .oldPostBadge, .driedHideBundle, .splitHornBone, .riftFangRoyalBadge,
             .mineLampCopperClip, .tunnelIronClip, .veinStoneSlab, .stoneSwallowCore,
             .relicSealRing, .oathInscriptionShard, .foreShrineClip, .ancientKingCore:
            return 0
        }
    }

    func add(_ amount: Int, of material: MaterialType) {
        switch material {
        case .wood:            wood            += amount
        case .ore:             ore             += amount
        case .hide:            hide            += amount
        case .crystalShard:    crystalShard    += amount
        case .ancientFragment: ancientFragment += amount
        // V2-1 區域素材：Ticket 02 新增 SwiftData 欄位前，暫為 no-op
        case .oldPostBadge, .driedHideBundle, .splitHornBone, .riftFangRoyalBadge,
             .mineLampCopperClip, .tunnelIronClip, .veinStoneSlab, .stoneSwallowCore,
             .relicSealRing, .oathInscriptionShard, .foreShrineClip, .ancientKingCore:
            break
        }
    }

    /// 嘗試扣除素材，若不足回傳 false
    @discardableResult
    func deduct(_ amount: Int, of material: MaterialType) -> Bool {
        let current = self.amount(of: material)
        guard current >= amount else { return false }
        switch material {
        case .wood:            wood            -= amount
        case .ore:             ore             -= amount
        case .hide:            hide            -= amount
        case .crystalShard:    crystalShard    -= amount
        case .ancientFragment: ancientFragment -= amount
        // V2-1 區域素材：Ticket 02 新增 SwiftData 欄位前，暫為 no-op（amount 已驗為 0，guard 會攔截）
        case .oldPostBadge, .driedHideBundle, .splitHornBone, .riftFangRoyalBadge,
             .mineLampCopperClip, .tunnelIronClip, .veinStoneSlab, .stoneSwallowCore,
             .relicSealRing, .oathInscriptionShard, .foreShrineClip, .ancientKingCore:
            break
        }
        return true
    }
}
