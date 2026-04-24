// MaterialType.swift
// 遊戲中所有素材類型定義
// 靜態資料，不進 SwiftData
//
// V1 通用素材（5 種）：採集或地下城掉落，作為鑄造基礎用料
// V2-1 區域素材（12 種）：各地下城樓層專屬掉落，對應區域裝備製作
// V4-3 沉落王城素材（4 種）：第四區域專屬掉落
// V7-4 種子（4 種）+ 農作物品質變體（12 種，4 種農作物 × 普通/高級/頂級）

import Foundation

enum MaterialType: String, CaseIterable, Codable {

    // MARK: - V1 通用素材

    case wood            = "wood"
    case ore             = "ore"
    case hide            = "hide"
    case crystalShard    = "crystal_shard"
    case ancientFragment = "ancient_fragment"

    // MARK: - V2-1 荒野邊境素材

    case oldPostBadge       = "old_post_badge"        // 舊哨徽片（殘木前哨）
    case driedHideBundle    = "dried_hide_bundle"     // 風乾獸皮束（獸痕荒徑）
    case splitHornBone      = "split_horn_bone"       // 裂角繫骨（掠影交界）
    case riftFangRoyalBadge = "rift_fang_royal_badge" // 裂牙王徽（Boss 特材）

    // MARK: - V2-1 廢棄礦坑素材

    case mineLampCopperClip = "mine_lamp_copper_clip" // 礦燈銅扣（殘軌礦道）
    case tunnelIronClip     = "tunnel_iron_clip"      // 坑道鐵扣（支架裂層）
    case veinStoneSlab      = "vein_stone_slab"       // 脈石承片（沉脈深坑）
    case stoneSwallowCore   = "stone_swallow_core"    // 吞岩甲核（Boss 特材）

    // MARK: - V2-1 古代遺跡素材

    case relicSealRing         = "relic_seal_ring"          // 殘印石環（破階外庭）
    case oathInscriptionShard  = "oath_inscription_shard"   // 誓紋碑片（斷碑迴廊）
    case foreShrineClip        = "fore_shrine_clip"         // 前殿儀扣（守誓前殿）
    case ancientKingCore       = "ancient_king_core"        // 古王儀核（Boss 特材）

    // MARK: - V4-3 沉落王城素材

    case sunkenRuneShard       = "sunken_rune_shard"        // 沉紋碎片（沉塔入口 F1）
    case abyssalCrystalDrop    = "abyssal_crystal_drop"     // 深淵晶滴（溺殿迴廊 F2）
    case drownedCrownFragment  = "drowned_crown_fragment"   // 溺冕殘片（王室深淵 F3）
    case sunkenKingSeal        = "sunken_king_seal"         // 沉王印璽（Boss 特材 F4）

    // MARK: - V7-1 採集專屬素材

    case ancientWood  = "ancient_wood"   // 古木材（伐木工高階地點）
    case refinedOre   = "refined_ore"    // 精煉礦石（採礦工高階地點）
    case herb         = "herb"           // 草藥（採藥師）
    case spiritHerb   = "spirit_herb"    // 靈草（採藥師高階地點）
    case freshFish    = "fresh_fish"     // 鮮魚（漁夫）
    case abyssFish    = "abyss_fish"     // 深淵魚（漁夫高階地點）

    // MARK: - V7-4 種子（農田消耗輸入）

    case wheatSeed       = "wheat_seed"        // 小麥種子（商人購買）
    case vegetableSeed   = "vegetable_seed"    // 蔬菜種子（商人購買）
    case fruitSeed       = "fruit_seed"        // 果實種子（地下城掉落）
    case spiritGrainSeed = "spirit_grain_seed" // 靈穗種子（地下城掉落）

    // MARK: - V7-4 農作物（4 種 × 3 品質）

    case wheat            = "wheat"             // 小麥（普通）
    case wheatHigh        = "wheat_high"        // ★小麥（高級）
    case wheatTop         = "wheat_top"         // ✦小麥（頂級）

    case vegetable        = "vegetable"         // 蔬菜（普通）
    case vegetableHigh    = "vegetable_high"    // ★蔬菜（高級）
    case vegetableTop     = "vegetable_top"     // ✦蔬菜（頂級）

    case fruit            = "fruit"             // 果實（普通）
    case fruitHigh        = "fruit_high"        // ★果實（高級）
    case fruitTop         = "fruit_top"         // ✦果實（頂級）

    case spiritGrain      = "spirit_grain"      // 靈穗（普通）
    case spiritGrainHigh  = "spirit_grain_high" // ★靈穗（高級）
    case spiritGrainTop   = "spirit_grain_top"  // ✦靈穗（頂級）

    // MARK: - 顯示名稱

    var displayName: String {
        switch self {
        // V1
        case .wood:                  return "木材"
        case .ore:                   return "礦石"
        case .hide:                  return "獸皮"
        case .crystalShard:          return "魔晶石"
        case .ancientFragment:       return "古代碎片"
        // 荒野邊境
        case .oldPostBadge:          return "舊哨徽片"
        case .driedHideBundle:       return "風乾獸皮束"
        case .splitHornBone:         return "裂角繫骨"
        case .riftFangRoyalBadge:    return "裂牙王徽"
        // 廢棄礦坑
        case .mineLampCopperClip:    return "礦燈銅扣"
        case .tunnelIronClip:        return "坑道鐵扣"
        case .veinStoneSlab:         return "脈石承片"
        case .stoneSwallowCore:      return "吞岩甲核"
        // 古代遺跡
        case .relicSealRing:         return "殘印石環"
        case .oathInscriptionShard:  return "誓紋碑片"
        case .foreShrineClip:        return "前殿儀扣"
        case .ancientKingCore:       return "古王儀核"
        // 沉落王城
        case .sunkenRuneShard:       return "沉紋碎片"
        case .abyssalCrystalDrop:    return "深淵晶滴"
        case .drownedCrownFragment:  return "溺冕殘片"
        case .sunkenKingSeal:        return "沉王印璽"
        // V7-1
        case .ancientWood:           return "古木材"
        case .refinedOre:            return "精煉礦石"
        case .herb:                  return "草藥"
        case .spiritHerb:            return "靈草"
        case .freshFish:             return "鮮魚"
        case .abyssFish:             return "深淵魚"
        // V7-4 種子
        case .wheatSeed:             return "小麥種子"
        case .vegetableSeed:         return "蔬菜種子"
        case .fruitSeed:             return "果實種子"
        case .spiritGrainSeed:       return "靈穗種子"
        // V7-4 農作物
        case .wheat:                 return "小麥"
        case .wheatHigh:             return "★小麥"
        case .wheatTop:              return "✦小麥"
        case .vegetable:             return "蔬菜"
        case .vegetableHigh:         return "★蔬菜"
        case .vegetableTop:          return "✦蔬菜"
        case .fruit:                 return "果實"
        case .fruitHigh:             return "★果實"
        case .fruitTop:              return "✦果實"
        case .spiritGrain:           return "靈穗"
        case .spiritGrainHigh:       return "★靈穗"
        case .spiritGrainTop:        return "✦靈穗"
        }
    }

    // MARK: - 圖示

    var icon: String {
        switch self {
        // V1
        case .wood:                  return "🪵"
        case .ore:                   return "🪨"
        case .hide:                  return "🐾"
        case .crystalShard:          return "💎"
        case .ancientFragment:       return "🔮"
        // 荒野邊境
        case .oldPostBadge:          return "🏷️"
        case .driedHideBundle:       return "🎗️"
        case .splitHornBone:         return "🦴"
        case .riftFangRoyalBadge:    return "👑"
        // 廢棄礦坑
        case .mineLampCopperClip:    return "🔦"
        case .tunnelIronClip:        return "🔧"
        case .veinStoneSlab:         return "🧱"
        case .stoneSwallowCore:      return "💀"
        // 古代遺跡
        case .relicSealRing:         return "💍"
        case .oathInscriptionShard:  return "📜"
        case .foreShrineClip:        return "⚜️"
        case .ancientKingCore:       return "🌟"
        // 沉落王城
        case .sunkenRuneShard:       return "🪬"
        case .abyssalCrystalDrop:    return "🔵"
        case .drownedCrownFragment:  return "🫧"
        case .sunkenKingSeal:        return "🔮"
        // V7-1
        case .ancientWood:           return "🌳"
        case .refinedOre:            return "⚙️"
        case .herb:                  return "🌿"
        case .spiritHerb:            return "🍃"
        case .freshFish:             return "🐟"
        case .abyssFish:             return "🦑"
        // V7-4 種子
        case .wheatSeed:             return "🌱"
        case .vegetableSeed:         return "🌱"
        case .fruitSeed:             return "🌱"
        case .spiritGrainSeed:       return "🌱"
        // V7-4 農作物（普通/高級/頂級共用同一 emoji，靠 displayName 前綴區分）
        case .wheat, .wheatHigh, .wheatTop:             return "🌾"
        case .vegetable, .vegetableHigh, .vegetableTop: return "🥦"
        case .fruit, .fruitHigh, .fruitTop:             return "🍎"
        case .spiritGrain, .spiritGrainHigh, .spiritGrainTop: return "🌿"
        }
    }

    // MARK: - 分類輔助

    /// 是否為地下城區域專屬素材（V2-1 新增）
    var isRegionMaterial: Bool {
        switch self {
        case .wood, .ore, .hide, .crystalShard, .ancientFragment:
            return false
        default:
            return true
        }
    }

    /// 是否為 Boss 特材
    var isBossMaterial: Bool {
        switch self {
        case .riftFangRoyalBadge, .stoneSwallowCore, .ancientKingCore, .sunkenKingSeal:
            return true
        default:
            return false
        }
    }
}
