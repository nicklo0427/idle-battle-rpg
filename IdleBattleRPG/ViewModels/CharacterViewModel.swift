// CharacterViewModel.swift
// 角色頁面的展示協調 ViewModel
//
// 責任：
//   - 將 View 的 @Query 結果轉換成 UI 所需的展示資料
//   - 委派業務操作給對應的 Service（不含業務邏輯）
//   - 升級 / 屬性點 → CharacterProgressionService
//   - 裝備切換     → EquipmentService
//   - 戰力計算     → HeroStatsService

import Foundation
import SwiftData

@Observable
final class CharacterViewModel {

    // MARK: - 英雄屬性（計算）

    func heroStats(player: PlayerStateModel?, equipped: [EquipmentModel]) -> HeroStats? {
        guard let player else { return nil }
        return HeroStatsService.compute(player: player, equipped: equipped)
    }

    // MARK: - 裝備分類

    func equippedItems(from equipment: [EquipmentModel]) -> [EquipmentModel] {
        equipment.filter { $0.isEquipped }
    }

    func unequippedItems(from equipment: [EquipmentModel]) -> [EquipmentModel] {
        equipment.filter { !$0.isEquipped }
    }

    /// 指定部位的背包（未裝備）裝備
    func unequippedItems(slot: EquipmentSlot, from equipment: [EquipmentModel]) -> [EquipmentModel] {
        equipment.filter { !$0.isEquipped && $0.slot == slot }
    }

    func equippedCount(from equipment: [EquipmentModel]) -> Int {
        equippedItems(from: equipment).count
    }

    // MARK: - 升級輔助

    /// 下一級費用（若已滿級回傳 nil）
    func nextLevelCost(player: PlayerStateModel?) -> Int? {
        guard let player,
              player.heroLevel < AppConstants.Game.heroMaxLevel else { return nil }
        return AppConstants.UpgradeCost.gold(toLevel: player.heroLevel + 1)
    }

    func isMaxLevel(player: PlayerStateModel?) -> Bool {
        guard let player else { return false }
        return player.heroLevel >= AppConstants.Game.heroMaxLevel
    }

    // MARK: - 升級操作（委派 CharacterProgressionService）

    /// 回傳 nil = 成功；非 nil = 失敗訊息
    func levelUp(player: PlayerStateModel, context: ModelContext) -> String? {
        let result = CharacterProgressionService(context: context).levelUp(player: player)
        switch result {
        case .success:               return nil
        case .failure(let error):    return error.message
        }
    }

    // MARK: - 屬性點分配（委派 CharacterProgressionService）

    func allocatePoint(to stat: StatType, player: PlayerStateModel, context: ModelContext) {
        CharacterProgressionService(context: context).allocatePoint(to: stat, player: player)
    }

    // MARK: - 裝備切換（委派 EquipmentService）

    func equip(_ item: EquipmentModel, context: ModelContext) {
        EquipmentService(context: context).equip(item)
    }

    func unequip(_ item: EquipmentModel, context: ModelContext) {
        EquipmentService(context: context).unequip(item)
    }
}
