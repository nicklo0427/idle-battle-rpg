// DatabaseSeeder.swift
// 首次啟動時建立初始資料
// 負責：PlayerStateModel、MaterialInventoryModel、初始裝備（破舊短劍）、DungeonProgressionModel
// 之後每次啟動只驗證是否已存在，不重複建立

import Foundation
import SwiftData

struct DatabaseSeeder {

    /// 若 DB 中尚無玩家資料，建立初始資料
    /// 三個 sub-seeder 各自 insert，最後統一 save 一次，避免部分寫入的問題
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        seedPlayerState(context: context)
        seedMaterialInventory(context: context)
        seedConsumableInventory(context: context)
        seedStartingEquipment(context: context)
        seedDungeonProgression(context: context)
        backfillTalentPoints(context: context)
        backfillSkillPoints(context: context)

        do {
            try context.save()
        } catch {
            print("[DatabaseSeeder] save failed: \(error)")
        }
    }

    // MARK: - Private

    @MainActor
    private static func seedPlayerState(context: ModelContext) {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let player = PlayerStateModel(
            gold:                     AppConstants.Initial.gold,
            heroLevel:                1,
            availableStatPoints:      0,
            atkPoints:                5,
            defPoints:                3,
            hpPoints:                 20,
            lastOpenedAt:             .now,
            hasUsedFirstCraftBoost:   false,
            hasUsedFirstDungeonBoost: false,
            onboardingStep:           0
        )
        context.insert(player)
    }

    @MainActor
    private static func seedMaterialInventory(context: ModelContext) {
        let descriptor = FetchDescriptor<MaterialInventoryModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let inventory = MaterialInventoryModel(
            wood:            AppConstants.Initial.wood,
            ore:             AppConstants.Initial.ore,
            hide:            0,
            crystalShard:    0,
            ancientFragment: 0
        )
        context.insert(inventory)
    }

    @MainActor
    private static func seedConsumableInventory(context: ModelContext) {
        let descriptor = FetchDescriptor<ConsumableInventoryModel>()
        guard (try? context.fetch(descriptor))?.isEmpty != false else { return }
        context.insert(ConsumableInventoryModel())
    }

    @MainActor
    private static func seedDungeonProgression(context: ModelContext) {
        let descriptor = FetchDescriptor<DungeonProgressionModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        // 初始狀態：第一區（wildland）預設解鎖，無任何首通紀錄
        let progression = DungeonProgressionModel(
            clearedFloorKeysJSON:   "[]",
            unlockedRegionKeysJSON: "[\"wildland\"]"
        )
        context.insert(progression)
    }

    /// 舊存檔補發天賦點：investedTalentKeysRaw 為空且 level > 1 時，按等級補發（幂等）
    @MainActor
    private static func backfillTalentPoints(context: ModelContext) {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(descriptor))?.first else { return }
        guard player.investedTalentKeysRaw.isEmpty,
              player.availableTalentPoints == 0,
              player.heroLevel > 1 else { return }
        player.availableTalentPoints = player.heroLevel - 1
    }

    /// 舊存檔補發技能點：skillLevelsRaw 為空且 level > 1 時，按等級補發（幂等）
    @MainActor
    private static func backfillSkillPoints(context: ModelContext) {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(descriptor))?.first else { return }
        guard player.skillLevelsRaw.isEmpty,
              player.availableSkillPoints == 0,
              player.heroLevel > 1 else { return }
        player.availableSkillPoints = player.heroLevel - 1
    }

    @MainActor
    private static func seedStartingEquipment(context: ModelContext) {
        let descriptor = FetchDescriptor<EquipmentModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        guard let def = EquipmentDef.find(key: AppConstants.Initial.startingWeaponKey) else {
            assertionFailure("Starting weapon def not found: \(AppConstants.Initial.startingWeaponKey)")
            return
        }

        let sword = EquipmentModel(
            defKey:     def.key,
            slot:       def.slot,
            rarity:     def.rarity,
            isEquipped: true
        )
        context.insert(sword)
    }
}
