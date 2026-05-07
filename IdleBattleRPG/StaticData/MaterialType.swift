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

    case oldPostBadge       = "old_post_badge"        // 收成勳章（穀倉前道）
    case driedHideBundle    = "dried_hide_bundle"     // 野豬獠牙（荒廢農舍）
    case splitHornBone      = "split_horn_bone"       // 倉庫鎖片（豐收穀倉）
    case riftFangRoyalBadge = "rift_fang_royal_badge" // 農神印記（Boss 特材）

    // MARK: - V2-1 廢棄礦坑素材

    case mineLampCopperClip = "mine_lamp_copper_clip" // 精靈羽毛（林道入口）
    case tunnelIronClip     = "tunnel_iron_clip"      // 古樹皮塊（古樹迷宮）
    case veinStoneSlab      = "vein_stone_slab"       // 腐化木紋板（幽暗深處）
    case stoneSwallowCore   = "stone_swallow_core"    // 千年樹心（Boss 特材）

    // MARK: - V2-1 古代遺跡素材

    case relicSealRing         = "relic_seal_ring"          // 部落圖騰（草原邊緣）
    case oathInscriptionShard  = "oath_inscription_shard"   // 破碎戰旗（遊牧廢營）
    case foreShrineClip        = "fore_shrine_clip"         // 鐵蹄護符（衝突前線）
    case ancientKingCore       = "ancient_king_core"        // 草原王核（Boss 特材）

    // MARK: - V4-3 沉落王城素材

    case sunkenRuneShard       = "sunken_rune_shard"        // 沙漠符文石（沙丘入口 F1）
    case abyssalCrystalDrop    = "abyssal_crystal_drop"     // 熱焰水晶（沙暴迴廊 F2）
    case drownedCrownFragment  = "drowned_crown_fragment"   // 法老封印片（法老深墓 F3）
    case sunkenKingSeal        = "sunken_king_seal"         // 法老王璽（Boss 特材 F4）

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
        // 金穗之野（農場）
        case .oldPostBadge:          return "收成勳章"
        case .driedHideBundle:       return "野豬獠牙"
        case .splitHornBone:         return "倉庫鎖片"
        case .riftFangRoyalBadge:    return "農神印記"
        // 暮色古林（森林）
        case .mineLampCopperClip:    return "精靈羽毛"
        case .tunnelIronClip:        return "古樹皮塊"
        case .veinStoneSlab:         return "腐化木紋板"
        case .stoneSwallowCore:      return "千年樹心"
        // 血色曠野（草原）
        case .relicSealRing:         return "部落圖騰"
        case .oathInscriptionShard:  return "破碎戰旗"
        case .foreShrineClip:        return "鐵蹄護符"
        case .ancientKingCore:       return "草原王核"
        // 烈焰沙海（沙漠）
        case .sunkenRuneShard:       return "沙漠符文石"
        case .abyssalCrystalDrop:    return "熱焰水晶"
        case .drownedCrownFragment:  return "法老封印片"
        case .sunkenKingSeal:        return "法老王璽"
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
        // 金穗之野（農場）
        case .oldPostBadge:          return "🌾"
        case .driedHideBundle:       return "🐗"
        case .splitHornBone:         return "🗝️"
        case .riftFangRoyalBadge:    return "🌻"
        // 暮色古林（森林）
        case .mineLampCopperClip:    return "🪶"
        case .tunnelIronClip:        return "🌳"
        case .veinStoneSlab:         return "🍃"
        case .stoneSwallowCore:      return "🖤"
        // 血色曠野（草原）
        case .relicSealRing:         return "🔮"
        case .oathInscriptionShard:  return "🚩"
        case .foreShrineClip:        return "⚜️"
        case .ancientKingCore:       return "🟡"
        // 烈焰沙海（沙漠）
        case .sunkenRuneShard:       return "🟠"
        case .abyssalCrystalDrop:    return "🔶"
        case .drownedCrownFragment:  return "🏺"
        case .sunkenKingSeal:        return "👁️"
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
