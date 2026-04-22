// NpcUpgradeService.swift
// NPC 效率升級業務邏輯：驗證 tier 上限、驗證並扣除 EXP + 素材 + 金幣、遞增 tier

import Foundation
import SwiftData

// MARK: - 錯誤類型

enum NpcUpgradeError: Error {
    case alreadyMaxTier
    case insufficientExp(required: Int, have: Int)
    case insufficientMaterial(material: MaterialType, required: Int, have: Int)
    case insufficientGold(required: Int, have: Int)

    var message: String {
        switch self {
        case .alreadyMaxTier:
            return "已達升級上限"
        case let .insufficientExp(required, have):
            return "EXP 不足（需要 \(required)，擁有 \(have)）"
        case let .insufficientMaterial(material, required, have):
            return "\(material.displayName) 不足（需要 \(required)，擁有 \(have)）"
        case let .insufficientGold(required, have):
            return "金幣不足（需要 \(required)，擁有 \(have)）"
        }
    }
}

// MARK: - NpcUpgradeService

struct NpcUpgradeService {
    let context: ModelContext

    /// 升級指定 NPC（三重驗證 + 原子扣除）
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

        guard let cost = NpcUpgradeDef.upgradeCost(npcKind: npcKind, fromTier: currentTier) else {
            return .failure(.alreadyMaxTier)
        }

        // 驗證 EXP
        guard player.heroExp >= cost.expCost else {
            return .failure(.insufficientExp(required: cost.expCost, have: player.heroExp))
        }

        // 驗證素材
        let inventory = fetchInventory()
        for (mat, required) in cost.materialCosts {
            let have = inventory?.amount(of: mat) ?? 0
            guard have >= required else {
                return .failure(.insufficientMaterial(material: mat, required: required, have: have))
            }
        }

        // 驗證金幣
        guard player.gold >= cost.goldCost else {
            return .failure(.insufficientGold(required: cost.goldCost, have: player.gold))
        }

        // 原子扣除
        player.heroExp -= cost.expCost
        player.gold    -= cost.goldCost
        for (mat, required) in cost.materialCosts {
            inventory?.deduct(required, of: mat)
        }

        // 遞增 Tier
        switch actorKey {
        case "gatherer_1": player.gatherer1Tier  += 1
        case "gatherer_2": player.gatherer2Tier  += 1
        case "blacksmith":  player.blacksmithTier += 1
        case "gatherer_3": player.gatherer3Tier  += 1
        case "gatherer_4": player.gatherer4Tier  += 1
        default: break
        }

        // 採集者升 Tier 獲得技能點（V7-1 T02）
        switch actorKey {
        case "gatherer_1": player.gatherer1SkillPoints += 1
        case "gatherer_2": player.gatherer2SkillPoints += 1
        case "gatherer_3": player.gatherer3SkillPoints += 1
        case "gatherer_4": player.gatherer4SkillPoints += 1
        default: break
        }

        try? context.save()
        return .success(())
    }

    // MARK: - 便利查詢

    /// 下一次升級完整成本；`nil` 表示已達上限
    func nextUpgradeCost(npcKind: NpcKind, actorKey: String, player: PlayerStateModel) -> NpcUpgradeCostDef? {
        let tier = player.tier(for: actorKey)
        guard tier < NpcUpgradeDef.maxTier else { return nil }
        return NpcUpgradeDef.upgradeCost(npcKind: npcKind, fromTier: tier)
    }

    // MARK: - Private

    private func fetchInventory() -> MaterialInventoryModel? {
        let descriptor = FetchDescriptor<MaterialInventoryModel>()
        return (try? context.fetch(descriptor))?.first
    }
}
