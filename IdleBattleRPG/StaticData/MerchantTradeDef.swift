// MerchantTradeDef.swift
// 商人固定兌換清單（單向，無套利）
// 靜態資料，不進 SwiftData

import Foundation

// MARK: - 兌換方向

enum TradeReceive {
    case gold(Int)
    case material(MaterialType, Int)
}

// MARK: - 兌換項目定義

struct MerchantTradeDef {
    let key: String
    let giveMaterial: MaterialType
    let giveAmount: Int
    let receive: TradeReceive

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

        // ── 出售方向（素材 → 金幣）──────────────────────────────────
        MerchantTradeDef(
            key:          "sell_wood",
            giveMaterial: .wood,
            giveAmount:   10,
            receive:      .gold(30)
        ),
        MerchantTradeDef(
            key:          "sell_ore",
            giveMaterial: .ore,
            giveAmount:   10,
            receive:      .gold(40)
        ),
        MerchantTradeDef(
            key:          "sell_hide",
            giveMaterial: .hide,
            giveAmount:   5,
            receive:      .gold(50)
        ),
        MerchantTradeDef(
            key:          "sell_crystal_shard",
            giveMaterial: .crystalShard,
            giveAmount:   3,
            receive:      .gold(80)
        ),

        // ── 補給方向（金幣 → 稀有素材，需另外以 gold 欄位處理）
        // 這兩筆以 ancientFragment 為目標；UI 顯示時用 giveAmount=0 + key 識別
        // ── 注意：此方向在 MerchantService 以 key 特判，非標準素材對素材交換
    ]

    /// 補給選項（金幣 → 稀有素材）——獨立清單，避免誤用出售邏輯
    static let goldTrades: [(key: String, goldCost: Int, receiveMaterial: MaterialType, receiveAmount: Int)] = [
        ("buy_ancient_fragment", 800, .ancientFragment, 1),
    ]

    static func find(key: String) -> MerchantTradeDef? {
        all.first { $0.key == key }
    }
}
