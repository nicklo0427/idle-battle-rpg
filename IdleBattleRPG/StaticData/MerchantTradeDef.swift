// MerchantTradeDef.swift
// 商人固定兌換清單（單向，無套利）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 兌換方向

enum TradeReceive {
    case gold(Int)
    case material(MaterialType, Int)
}

// MARK: - 分類

enum TradeCategory {
    case basicMaterial   // V1 通用素材 → 金幣
    case areaMaterial    // V2-1 區域素材 → 金幣
    case gatherMaterial  // V7-1 採集專屬素材 → 金幣
    case cropSell        // V7-4 農作物出售 → 金幣
}

// MARK: - 兌換項目定義

struct MerchantTradeDef {
    let key: String
    let giveMaterial: MaterialType
    let giveAmount: Int
    let receive: TradeReceive
    let category: TradeCategory

    var displayName: String {
        switch receive {
        case .gold(let amount):
            return "\(giveMaterial.icon) \(giveMaterial.displayName) ×\(giveAmount) → 💰 金幣 ×\(amount)"
        case .material(let mat, let amount):
            return "\(giveMaterial.icon) \(giveMaterial.displayName) ×\(giveAmount) → \(mat.icon) \(mat.displayName) ×\(amount)"
        }
    }
}

// MARK: - 靜態資料
// 設計原則：
//   素材 → 金幣（出售多餘素材）
//   金幣 → 稀有素材（補給用，高單價，不划算當主要來源）
//   不設計「素材 ↔ 素材」雙向兌換（防循環套利）

extension MerchantTradeDef {

    static let all: [MerchantTradeDef] = [

        // ── V1 通用素材出售（素材 → 金幣）──────────────────────────────────
        MerchantTradeDef(
            key:          "sell_wood",
            giveMaterial: .wood,
            giveAmount:   10,
            receive:      .gold(30),
            category:     .basicMaterial
        ),
        MerchantTradeDef(
            key:          "sell_ore",
            giveMaterial: .ore,
            giveAmount:   10,
            receive:      .gold(40),
            category:     .basicMaterial
        ),
        MerchantTradeDef(
            key:          "sell_hide",
            giveMaterial: .hide,
            giveAmount:   5,
            receive:      .gold(50),
            category:     .basicMaterial
        ),
        MerchantTradeDef(
            key:          "sell_crystal_shard",
            giveMaterial: .crystalShard,
            giveAmount:   3,
            receive:      .gold(80),
            category:     .basicMaterial
        ),

        // ── V2-1 區域素材出售（素材 → 金幣）──────────────────────────────────
        // 荒野邊境
        MerchantTradeDef(
            key:          "sell_old_post_badge",
            giveMaterial: .oldPostBadge,
            giveAmount:   3,
            receive:      .gold(30),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_dried_hide_bundle",
            giveMaterial: .driedHideBundle,
            giveAmount:   3,
            receive:      .gold(30),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_split_horn_bone",
            giveMaterial: .splitHornBone,
            giveAmount:   3,
            receive:      .gold(30),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_rift_fang_royal_badge",
            giveMaterial: .riftFangRoyalBadge,
            giveAmount:   1,
            receive:      .gold(120),
            category:     .areaMaterial
        ),
        // 廢棄礦坑
        MerchantTradeDef(
            key:          "sell_mine_lamp_copper_clip",
            giveMaterial: .mineLampCopperClip,
            giveAmount:   3,
            receive:      .gold(40),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_tunnel_iron_clip",
            giveMaterial: .tunnelIronClip,
            giveAmount:   3,
            receive:      .gold(40),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_vein_stone_slab",
            giveMaterial: .veinStoneSlab,
            giveAmount:   3,
            receive:      .gold(40),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_stone_swallow_core",
            giveMaterial: .stoneSwallowCore,
            giveAmount:   1,
            receive:      .gold(150),
            category:     .areaMaterial
        ),
        // 深淵遺跡
        MerchantTradeDef(
            key:          "sell_relic_seal_ring",
            giveMaterial: .relicSealRing,
            giveAmount:   3,
            receive:      .gold(50),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_oath_inscription_shard",
            giveMaterial: .oathInscriptionShard,
            giveAmount:   3,
            receive:      .gold(50),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_fore_shrine_clip",
            giveMaterial: .foreShrineClip,
            giveAmount:   3,
            receive:      .gold(50),
            category:     .areaMaterial
        ),
        MerchantTradeDef(
            key:          "sell_ancient_king_core",
            giveMaterial: .ancientKingCore,
            giveAmount:   1,
            receive:      .gold(200),
            category:     .areaMaterial
        ),

        // ── V7-1 採集素材出售（素材 → 金幣）──────────────────────────────────

        MerchantTradeDef(
            key:          "sell_herb",
            giveMaterial: .herb,
            giveAmount:   10,
            receive:      .gold(35),
            category:     .gatherMaterial
        ),
        MerchantTradeDef(
            key:          "sell_fresh_fish",
            giveMaterial: .freshFish,
            giveAmount:   10,
            receive:      .gold(35),
            category:     .gatherMaterial
        ),
        MerchantTradeDef(
            key:          "sell_ancient_wood",
            giveMaterial: .ancientWood,
            giveAmount:   5,
            receive:      .gold(60),
            category:     .gatherMaterial
        ),
        MerchantTradeDef(
            key:          "sell_refined_ore",
            giveMaterial: .refinedOre,
            giveAmount:   5,
            receive:      .gold(60),
            category:     .gatherMaterial
        ),
        MerchantTradeDef(
            key:          "sell_spirit_herb",
            giveMaterial: .spiritHerb,
            giveAmount:   3,
            receive:      .gold(80),
            category:     .gatherMaterial
        ),
        MerchantTradeDef(
            key:          "sell_abyss_fish",
            giveMaterial: .abyssFish,
            giveAmount:   3,
            receive:      .gold(80),
            category:     .gatherMaterial
        ),

        // ── V7-4 農作物出售（農作物 → 金幣）────────────────────────────────
        // 普通品質：10 金/顆
        MerchantTradeDef(key: "sell_wheat",         giveMaterial: .wheat,        giveAmount: 1, receive: .gold(10), category: .cropSell),
        MerchantTradeDef(key: "sell_vegetable",     giveMaterial: .vegetable,    giveAmount: 1, receive: .gold(10), category: .cropSell),
        MerchantTradeDef(key: "sell_fruit",         giveMaterial: .fruit,        giveAmount: 1, receive: .gold(10), category: .cropSell),
        MerchantTradeDef(key: "sell_spirit_grain",  giveMaterial: .spiritGrain,  giveAmount: 1, receive: .gold(10), category: .cropSell),
        // 高級品質：25 金/顆
        MerchantTradeDef(key: "sell_wheat_high",        giveMaterial: .wheatHigh,       giveAmount: 1, receive: .gold(25), category: .cropSell),
        MerchantTradeDef(key: "sell_vegetable_high",    giveMaterial: .vegetableHigh,   giveAmount: 1, receive: .gold(25), category: .cropSell),
        MerchantTradeDef(key: "sell_fruit_high",        giveMaterial: .fruitHigh,       giveAmount: 1, receive: .gold(25), category: .cropSell),
        MerchantTradeDef(key: "sell_spirit_grain_high", giveMaterial: .spiritGrainHigh, giveAmount: 1, receive: .gold(25), category: .cropSell),
        // 頂級品質：60 金/顆
        MerchantTradeDef(key: "sell_wheat_top",         giveMaterial: .wheatTop,        giveAmount: 1, receive: .gold(60), category: .cropSell),
        MerchantTradeDef(key: "sell_vegetable_top",     giveMaterial: .vegetableTop,    giveAmount: 1, receive: .gold(60), category: .cropSell),
        MerchantTradeDef(key: "sell_fruit_top",         giveMaterial: .fruitTop,        giveAmount: 1, receive: .gold(60), category: .cropSell),
        MerchantTradeDef(key: "sell_spirit_grain_top",  giveMaterial: .spiritGrainTop,  giveAmount: 1, receive: .gold(60), category: .cropSell),
    ]

    /// 農作物出售列表（V7-4）
    static var cropSell: [MerchantTradeDef] {
        all.filter { $0.category == .cropSell }
    }

    /// 補給選項（金幣 → 稀有素材）——獨立清單，避免誤用出售邏輯
    static let goldTrades: [(key: String, goldCost: Int, receiveMaterial: MaterialType, receiveAmount: Int)] = [
        ("buy_ancient_fragment", 800,  .ancientFragment, 1),
        ("buy_spirit_herb",      400,  .spiritHerb,      1),
        ("buy_abyss_fish",       400,  .abyssFish,       1),
        // V7-4 種子補給（商人只賣最基礎兩種，其餘靠地下城掉落）
        ("buy_wheat_seed",       80,   .wheatSeed,       3),
        ("buy_vegetable_seed",   120,  .vegetableSeed,   3),
    ]

    static func find(key: String) -> MerchantTradeDef? {
        all.first { $0.key == key }
    }
}
