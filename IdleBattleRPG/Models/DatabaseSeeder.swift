// DatabaseSeeder.swift
// 首次啟動時建立初始資料
// 負責：PlayerStateModel、MaterialInventoryModel、初始裝備（破舊短劍）
// 之後每次啟動只驗證是否已存在，不重複建立

import Foundation
import SwiftData

struct DatabaseSeeder {

    /// 若 DB 中尚無玩家資料，建立初始資料
    /// 應在 App 啟動時（主 container 已就緒後）呼叫一次
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        seedPlayerState(context: context)
        seedMaterialInventory(context: context)
        seedStartingEquipment(context: context)
    }

    // MARK: - Private

    @MainActor
    private static func seedPlayerState(context: ModelContext) {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let player = PlayerStateModel(
            gold:                    AppConstants.Initial.gold,
            heroLevel:               1,
            availableStatPoints:     0,
            atkPoints:               5,
            defPoints:               3,
            hpPoints:                20,
            lastOpenedAt:            .now,
            hasUsedFirstCraftBoost:  false,
            hasUsedFirstDungeonBoost: false,
            onboardingStep:          0
        )
        context.insert(player)
        save(context)
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
        save(context)
    }

    @MainActor
    private static func seedStartingEquipment(context: ModelContext) {
        // 只在沒有任何裝備時才 seed
        let descriptor = FetchDescriptor<EquipmentModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        guard let def = EquipmentDef.find(key: AppConstants.Initial.startingWeaponKey) else {
            assertionFailure("Starting weapon def not found: \(AppConstants.Initial.startingWeaponKey)")
            return
        }

        // 破舊短劍預設已裝備
        let sword = EquipmentModel(
            defKey:     def.key,
            slot:       def.slot,
            rarity:     def.rarity,
            isEquipped: true
        )
        context.insert(sword)
        save(context)
    }

    @MainActor
    private static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[DatabaseSeeder] save failed: \(error)")
        }
    }
}
