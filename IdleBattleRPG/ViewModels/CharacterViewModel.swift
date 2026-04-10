// CharacterViewModel.swift
// 角色頁面的展示協調 ViewModel
//
// 責任：
//   - 將 View 的 @Query 結果轉換成 UI 所需的展示資料
//   - 委派業務操作給對應的 Service（不含業務邏輯）
//   - 升級 / 屬性點 → CharacterProgressionService
//   - 裝備切換     → EquipmentService
//   - 戰力計算     → HeroStatsService
//   - 強化 / 拆解  → EnhancementService（V2-2）

import Foundation
import SwiftData

// MARK: - StatDiff

struct StatDiff {
    let atk: Int
    let def: Int
    let hp:  Int
    /// 戰力差（使用標準公式）
    var power: Int { atk * 2 + Int(Double(def) * 1.5) + hp }
    var hasAnyChange: Bool { atk != 0 || def != 0 || hp != 0 }
}

// MARK: - CharacterViewModel

@Observable
final class CharacterViewModel {

    // MARK: - Pending 屬性點（暫存，尚未寫入 SwiftData）

    var pendingAtk: Int = 0
    var pendingDef: Int = 0
    var pendingHp:  Int = 0
    var pendingAgi: Int = 0
    var pendingDex: Int = 0

    var hasPendingAllocations: Bool {
        pendingAtk > 0 || pendingDef > 0 || pendingHp > 0 || pendingAgi > 0 || pendingDex > 0
    }

    func remainingPendingPoints(player: PlayerStateModel?) -> Int {
        (player?.availableStatPoints ?? 0)
            - pendingAtk - pendingDef - pendingHp - pendingAgi - pendingDex
    }

    func addPendingPoint(to stat: StatType, player: PlayerStateModel?) {
        guard remainingPendingPoints(player: player) > 0 else { return }
        switch stat {
        case .atk: pendingAtk += 1
        case .def: pendingDef += 1
        case .hp:  pendingHp  += 1
        case .agi: pendingAgi += 1
        case .dex: pendingDex += 1
        }
    }

    func commitAllocations(player: PlayerStateModel, context: ModelContext) {
        CharacterProgressionService(context: context).commitAllocations(
            player:   player,
            atkDelta: pendingAtk, defDelta: pendingDef, hpDelta: pendingHp,
            agiDelta: pendingAgi, dexDelta: pendingDex
        )
        cancelAllocations()
    }

    func cancelAllocations() {
        pendingAtk = 0; pendingDef = 0; pendingHp = 0
        pendingAgi = 0; pendingDex = 0
    }

    func resetAllStats(player: PlayerStateModel, context: ModelContext) {
        CharacterProgressionService(context: context).resetAllStats(player: player)
        cancelAllocations()
    }

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

    /// 升至下一級所需 EXP（若已滿級回傳 nil）
    func nextLevelExpRequired(player: PlayerStateModel?) -> Int? {
        guard let player,
              player.heroLevel < AppConstants.Game.heroMaxLevel else { return nil }
        return AppConstants.ExpThreshold.required(toLevel: player.heroLevel + 1)
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

    // MARK: - 換裝差值

    /// 換上 candidate 後相對於同部位已裝備裝備的屬性差值（正 = 提升，負 = 下降）
    func equipDiff(
        candidate: EquipmentModel,
        equipped: [EquipmentModel]
    ) -> StatDiff {
        let current = equipped.first { $0.slot == candidate.slot && $0.isEquipped }
        return StatDiff(
            atk: candidate.totalAtk - (current?.totalAtk ?? 0),
            def: candidate.totalDef - (current?.totalDef ?? 0),
            hp:  candidate.totalHp  - (current?.totalHp  ?? 0)
        )
    }

    // MARK: - 強化 / 拆解（委派 EnhancementService，V2-2）

    /// 強化裝備；回傳 nil = 成功，非 nil = 失敗訊息
    func enhance(equipment: EquipmentModel, player: PlayerStateModel, context: ModelContext) -> String? {
        switch EnhancementService(context: context).enhance(equipment: equipment, player: player) {
        case .success:            return nil
        case .failure(let error): return error.message
        }
    }

    /// 拆解裝備；回傳 nil = 成功，非 nil = 失敗訊息
    func disassemble(equipment: EquipmentModel, player: PlayerStateModel, context: ModelContext) -> String? {
        switch EnhancementService(context: context).disassemble(equipment: equipment, player: player) {
        case .success:            return nil
        case .failure(let error): return error.message
        }
    }
}
