// MaterialInventoryModel.swift
// 玩家素材庫存的持久化模型（全域單例）
//
// V1 通用素材（5 種）：wood / ore / hide / crystalShard / ancientFragment
// V2-1 區域素材（12 種）：3 區域 × 4 樓層，各樓層對應一種專屬素材
// V4-3 沉落王城素材（4 種）：第四區域 4 樓層

import Foundation
import SwiftData

@Model
final class MaterialInventoryModel {

    // MARK: - V1 通用素材

    var wood:            Int
    var ore:             Int
    var hide:            Int
    var crystalShard:    Int
    var ancientFragment: Int

    // MARK: - V2-1 荒野邊境素材

    var oldPostBadge:       Int   // 舊哨徽片（殘木前哨 F1）
    var driedHideBundle:    Int   // 風乾獸皮束（獸痕荒徑 F2）
    var splitHornBone:      Int   // 裂角繫骨（掠影交界 F3）
    var riftFangRoyalBadge: Int   // 裂牙王徽（Boss 特材 F4）

    // MARK: - V2-1 廢棄礦坑素材

    var mineLampCopperClip: Int   // 礦燈銅扣（殘軌礦道 F1）
    var tunnelIronClip:     Int   // 坑道鐵扣（支架裂層 F2）
    var veinStoneSlab:      Int   // 脈石承片（沉脈深坑 F3）
    var stoneSwallowCore:   Int   // 吞岩甲核（Boss 特材 F4）

    // MARK: - V2-1 古代遺跡素材

    var relicSealRing:        Int   // 殘印石環（破階外庭 F1）
    var oathInscriptionShard: Int   // 誓紋碑片（斷碑迴廊 F2）
    var foreShrineClip:       Int   // 前殿儀扣（守誓前殿 F3）
    var ancientKingCore:      Int   // 古王儀核（Boss 特材 F4）

    // MARK: - V4-3 沉落王城素材

    var sunkenRuneShard:      Int   // 沉紋碎片（沉塔入口 F1）
    var abyssalCrystalDrop:   Int   // 深淵晶滴（溺殿迴廊 F2）
    var drownedCrownFragment: Int   // 溺冕殘片（王室深淵 F3）
    var sunkenKingSeal:       Int   // 沉王印璽（Boss 特材 F4）

    // MARK: - V7-1 採集專屬素材

    var ancientWood:  Int = 0
    var refinedOre:   Int = 0
    var herb:         Int = 0
    var spiritHerb:   Int = 0
    var freshFish:    Int = 0
    var abyssFish:    Int = 0

    // MARK: - Init

    init(
        wood:            Int = AppConstants.Initial.wood,
        ore:             Int = AppConstants.Initial.ore,
        hide:            Int = 0,
        crystalShard:    Int = 0,
        ancientFragment: Int = 0,
        // V2-1 全部預設 0
        oldPostBadge:       Int = 0,
        driedHideBundle:    Int = 0,
        splitHornBone:      Int = 0,
        riftFangRoyalBadge: Int = 0,
        mineLampCopperClip: Int = 0,
        tunnelIronClip:     Int = 0,
        veinStoneSlab:      Int = 0,
        stoneSwallowCore:   Int = 0,
        relicSealRing:        Int = 0,
        oathInscriptionShard: Int = 0,
        foreShrineClip:       Int = 0,
        ancientKingCore:      Int = 0,
        // V4-3 全部預設 0
        sunkenRuneShard:      Int = 0,
        abyssalCrystalDrop:   Int = 0,
        drownedCrownFragment: Int = 0,
        sunkenKingSeal:       Int = 0
    ) {
        self.wood            = wood
        self.ore             = ore
        self.hide            = hide
        self.crystalShard    = crystalShard
        self.ancientFragment = ancientFragment

        self.oldPostBadge       = oldPostBadge
        self.driedHideBundle    = driedHideBundle
        self.splitHornBone      = splitHornBone
        self.riftFangRoyalBadge = riftFangRoyalBadge

        self.mineLampCopperClip = mineLampCopperClip
        self.tunnelIronClip     = tunnelIronClip
        self.veinStoneSlab      = veinStoneSlab
        self.stoneSwallowCore   = stoneSwallowCore

        self.relicSealRing        = relicSealRing
        self.oathInscriptionShard = oathInscriptionShard
        self.foreShrineClip       = foreShrineClip
        self.ancientKingCore      = ancientKingCore

        self.sunkenRuneShard      = sunkenRuneShard
        self.abyssalCrystalDrop   = abyssalCrystalDrop
        self.drownedCrownFragment = drownedCrownFragment
        self.sunkenKingSeal       = sunkenKingSeal
    }

    // MARK: - 便利存取（依 MaterialType 讀寫）

    func amount(of material: MaterialType) -> Int {
        switch material {
        // V1
        case .wood:            return wood
        case .ore:             return ore
        case .hide:            return hide
        case .crystalShard:    return crystalShard
        case .ancientFragment: return ancientFragment
        // 荒野邊境
        case .oldPostBadge:       return oldPostBadge
        case .driedHideBundle:    return driedHideBundle
        case .splitHornBone:      return splitHornBone
        case .riftFangRoyalBadge: return riftFangRoyalBadge
        // 廢棄礦坑
        case .mineLampCopperClip: return mineLampCopperClip
        case .tunnelIronClip:     return tunnelIronClip
        case .veinStoneSlab:      return veinStoneSlab
        case .stoneSwallowCore:   return stoneSwallowCore
        // 古代遺跡
        case .relicSealRing:        return relicSealRing
        case .oathInscriptionShard: return oathInscriptionShard
        case .foreShrineClip:       return foreShrineClip
        case .ancientKingCore:      return ancientKingCore
        // 沉落王城
        case .sunkenRuneShard:      return sunkenRuneShard
        case .abyssalCrystalDrop:   return abyssalCrystalDrop
        case .drownedCrownFragment: return drownedCrownFragment
        case .sunkenKingSeal:       return sunkenKingSeal
        // V7-1
        case .ancientWood:  return ancientWood
        case .refinedOre:   return refinedOre
        case .herb:         return herb
        case .spiritHerb:   return spiritHerb
        case .freshFish:    return freshFish
        case .abyssFish:    return abyssFish
        }
    }

    func add(_ amount: Int, of material: MaterialType) {
        switch material {
        // V1
        case .wood:            wood            += amount
        case .ore:             ore             += amount
        case .hide:            hide            += amount
        case .crystalShard:    crystalShard    += amount
        case .ancientFragment: ancientFragment += amount
        // 荒野邊境
        case .oldPostBadge:       oldPostBadge       += amount
        case .driedHideBundle:    driedHideBundle    += amount
        case .splitHornBone:      splitHornBone      += amount
        case .riftFangRoyalBadge: riftFangRoyalBadge += amount
        // 廢棄礦坑
        case .mineLampCopperClip: mineLampCopperClip += amount
        case .tunnelIronClip:     tunnelIronClip     += amount
        case .veinStoneSlab:      veinStoneSlab      += amount
        case .stoneSwallowCore:   stoneSwallowCore   += amount
        // 古代遺跡
        case .relicSealRing:        relicSealRing        += amount
        case .oathInscriptionShard: oathInscriptionShard += amount
        case .foreShrineClip:       foreShrineClip       += amount
        case .ancientKingCore:      ancientKingCore      += amount
        // 沉落王城
        case .sunkenRuneShard:      sunkenRuneShard      += amount
        case .abyssalCrystalDrop:   abyssalCrystalDrop   += amount
        case .drownedCrownFragment: drownedCrownFragment += amount
        case .sunkenKingSeal:       sunkenKingSeal       += amount
        // V7-1
        case .ancientWood:  ancientWood  += amount
        case .refinedOre:   refinedOre   += amount
        case .herb:         herb         += amount
        case .spiritHerb:   spiritHerb   += amount
        case .freshFish:    freshFish    += amount
        case .abyssFish:    abyssFish    += amount
        }
    }

    /// 嘗試扣除素材，若不足回傳 false
    @discardableResult
    func deduct(_ amount: Int, of material: MaterialType) -> Bool {
        let current = self.amount(of: material)
        guard current >= amount else { return false }
        switch material {
        // V1
        case .wood:            wood            -= amount
        case .ore:             ore             -= amount
        case .hide:            hide            -= amount
        case .crystalShard:    crystalShard    -= amount
        case .ancientFragment: ancientFragment -= amount
        // 荒野邊境
        case .oldPostBadge:       oldPostBadge       -= amount
        case .driedHideBundle:    driedHideBundle    -= amount
        case .splitHornBone:      splitHornBone      -= amount
        case .riftFangRoyalBadge: riftFangRoyalBadge -= amount
        // 廢棄礦坑
        case .mineLampCopperClip: mineLampCopperClip -= amount
        case .tunnelIronClip:     tunnelIronClip     -= amount
        case .veinStoneSlab:      veinStoneSlab      -= amount
        case .stoneSwallowCore:   stoneSwallowCore   -= amount
        // 古代遺跡
        case .relicSealRing:        relicSealRing        -= amount
        case .oathInscriptionShard: oathInscriptionShard -= amount
        case .foreShrineClip:       foreShrineClip       -= amount
        case .ancientKingCore:      ancientKingCore      -= amount
        // 沉落王城
        case .sunkenRuneShard:      sunkenRuneShard      -= amount
        case .abyssalCrystalDrop:   abyssalCrystalDrop   -= amount
        case .drownedCrownFragment: drownedCrownFragment -= amount
        case .sunkenKingSeal:       sunkenKingSeal       -= amount
        // V7-1
        case .ancientWood:  ancientWood  -= amount
        case .refinedOre:   refinedOre   -= amount
        case .herb:         herb         -= amount
        case .spiritHerb:   spiritHerb   -= amount
        case .freshFish:    freshFish    -= amount
        case .abyssFish:    abyssFish    -= amount
        }
        return true
    }
}
