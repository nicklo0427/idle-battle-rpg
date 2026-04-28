// MerchantService.swift
// 商人交易服務
//
// 責任：
//   executeSellTrade(tradeKey:)  — 素材 → 金幣（MerchantTradeDef.all）
//   executeBuyTrade(tradeKey:)   — 金幣 → 稀有素材（MerchantTradeDef.goldTrades）
//
// 設計原則（MVP 規格）：
//   - 固定價格、單向、不對稱，無套利循環
//   - 不做刷新、不做隨機商品
//   - 扣除與入帳在同一 context.save() 內（原子）
//   - 資源不足時回傳 .failure，不寫入任何資料

import Foundation
import SwiftData

// MARK: - 錯誤類型

enum MerchantTradeError: Error {
    case tradeNotFound
    case noPlayer
    case noInventory
    case insufficientMaterial(MaterialType, have: Int, need: Int)
    case insufficientGold(have: Int, need: Int)

    var message: String {
        switch self {
        case .tradeNotFound:
            return "找不到此交易項目"
        case .noPlayer, .noInventory:
            return "找不到玩家資料，請重新啟動 App"
        case let .insufficientMaterial(mat, have, need):
            return "\(mat.displayName) 不足（需要 \(need)，擁有 \(have)）"
        case let .insufficientGold(have, need):
            return "金幣不足（需要 \(need)，擁有 \(have)）"
        }
    }
}

// MARK: - MerchantService

struct MerchantService {

    let context: ModelContext

    // MARK: - 賣出（素材 → 金幣）

    /// 執行出售交易：扣素材、加金幣。
    /// 依 MerchantTradeDef.all 查詢，資源不足回傳 .failure。
    @discardableResult
    func executeSellTrade(tradeKey: String) -> Result<Void, MerchantTradeError> {
        guard let trade = MerchantTradeDef.find(key: tradeKey) else {
            return .failure(.tradeNotFound)
        }
        guard let player = fetchPlayer() else { return .failure(.noPlayer) }
        guard let inv    = fetchInventory() else { return .failure(.noInventory) }

        let have = inv.amount(of: trade.giveMaterial)
        guard have >= trade.giveAmount else {
            return .failure(.insufficientMaterial(trade.giveMaterial, have: have, need: trade.giveAmount))
        }

        guard case .gold(let goldReceived) = trade.receive else {
            return .failure(.tradeNotFound)
        }

        // 原子寫入
        inv.deduct(trade.giveAmount, of: trade.giveMaterial)
        player.gold += goldReceived
        save()

        print("[MerchantService] 賣出 \(trade.giveMaterial.displayName) ×\(trade.giveAmount) → 金幣 +\(goldReceived)")
        return .success(())
    }

    // MARK: - 購買（金幣 → 稀有素材）

    /// 執行購買交易：扣金幣、加稀有素材。
    /// 依 MerchantTradeDef.goldTrades 查詢，資源不足回傳 .failure。
    @discardableResult
    func executeBuyTrade(tradeKey: String) -> Result<Void, MerchantTradeError> {
        guard let trade = MerchantTradeDef.goldTrades.first(where: { $0.key == tradeKey }) else {
            return .failure(.tradeNotFound)
        }
        guard let player = fetchPlayer() else { return .failure(.noPlayer) }
        guard let inv    = fetchInventory() else { return .failure(.noInventory) }

        guard player.gold >= trade.goldCost else {
            return .failure(.insufficientGold(have: player.gold, need: trade.goldCost))
        }

        // 原子寫入
        player.gold -= trade.goldCost
        inv.add(trade.receiveAmount, of: trade.receiveMaterial)
        save()

        print("[MerchantService] 購買 \(trade.receiveMaterial.displayName) ×\(trade.receiveAmount) → 金幣 -\(trade.goldCost)")
        return .success(())
    }

    // MARK: - 多批次賣出（確認 Sheet 使用）

    /// 賣出 N 批次（原子）。times 必須 >= 1。
    @discardableResult
    func executeSellTrade(tradeKey: String, times: Int) -> Result<Void, MerchantTradeError> {
        guard times >= 1 else { return .success(()) }
        guard let trade = MerchantTradeDef.find(key: tradeKey) else {
            return .failure(.tradeNotFound)
        }
        guard let player = fetchPlayer() else { return .failure(.noPlayer) }
        guard let inv    = fetchInventory() else { return .failure(.noInventory) }

        let totalGive = trade.giveAmount * times
        let have = inv.amount(of: trade.giveMaterial)
        guard have >= totalGive else {
            return .failure(.insufficientMaterial(trade.giveMaterial, have: have, need: totalGive))
        }
        guard case .gold(let goldPerBatch) = trade.receive else {
            return .failure(.tradeNotFound)
        }

        inv.deduct(totalGive, of: trade.giveMaterial)
        player.gold += goldPerBatch * times
        save()
        return .success(())
    }

    // MARK: - 多批次購買（確認 Sheet 使用）

    /// 購買 N 次（原子）。times 必須 >= 1。
    @discardableResult
    func executeBuyTrade(tradeKey: String, times: Int) -> Result<Void, MerchantTradeError> {
        guard times >= 1 else { return .success(()) }
        guard let trade = MerchantTradeDef.goldTrades.first(where: { $0.key == tradeKey }) else {
            return .failure(.tradeNotFound)
        }
        guard let player = fetchPlayer() else { return .failure(.noPlayer) }
        guard let inv    = fetchInventory() else { return .failure(.noInventory) }

        let totalCost = trade.goldCost * times
        guard player.gold >= totalCost else {
            return .failure(.insufficientGold(have: player.gold, need: totalCost))
        }

        player.gold -= totalCost
        inv.add(trade.receiveAmount * times, of: trade.receiveMaterial)
        save()
        return .success(())
    }

    // MARK: - 全賣（一次清空可負擔的最大批次）

    /// 將目前庫存中符合批次要求的最多次數一次賣出，回傳實際執行批次數。
    /// 例：持有 25 木材，批次 10 → 執行 2 次，賣出 20 木材，剩 5。
    @discardableResult
    func executeMaxSellTrade(tradeKey: String) -> Result<Int, MerchantTradeError> {
        guard let trade = MerchantTradeDef.find(key: tradeKey) else {
            return .failure(.tradeNotFound)
        }
        guard let player = fetchPlayer() else { return .failure(.noPlayer) }
        guard let inv    = fetchInventory() else { return .failure(.noInventory) }

        let owned = inv.amount(of: trade.giveMaterial)
        let times = owned / trade.giveAmount
        guard times > 0 else {
            return .failure(.insufficientMaterial(trade.giveMaterial, have: owned, need: trade.giveAmount))
        }
        guard case .gold(let goldPerBatch) = trade.receive else {
            return .failure(.tradeNotFound)
        }

        // 計算總量後一次扣除、一次入帳、一次 save（原子）
        inv.deduct(trade.giveAmount * times, of: trade.giveMaterial)
        player.gold += goldPerBatch * times
        save()

        print("[MerchantService] 全賣 \(trade.giveMaterial.displayName) ×\(trade.giveAmount * times) → 金幣 +\(goldPerBatch * times)（\(times) 批）")
        return .success(times)
    }

    // MARK: - 便利查詢（供 UI 預先判斷是否可負擔）

    func canAffordSell(tradeKey: String, inventory: MaterialInventoryModel?) -> Bool {
        guard let inv   = inventory,
              let trade = MerchantTradeDef.find(key: tradeKey) else { return false }
        return inv.amount(of: trade.giveMaterial) >= trade.giveAmount
    }

    func canAffordBuy(tradeKey: String, player: PlayerStateModel?) -> Bool {
        guard let player = player,
              let trade  = MerchantTradeDef.goldTrades.first(where: { $0.key == tradeKey }) else { return false }
        return player.gold >= trade.goldCost
    }

    // MARK: - Private

    private func fetchPlayer() -> PlayerStateModel? {
        (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
    }

    private func fetchInventory() -> MaterialInventoryModel? {
        (try? context.fetch(FetchDescriptor<MaterialInventoryModel>()))?.first
    }

    private func save() {
        try? context.save()
    }
}
