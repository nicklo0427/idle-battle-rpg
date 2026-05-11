// TaskClaimServiceTests.swift
// 驗證任務收下時的裝備入庫行為

import XCTest
import SwiftData
@testable import IdleBattleRPG

@MainActor
final class TaskClaimServiceTests: XCTestCase {

    func test_claimTutorialCraft_addsStarterWeaponUnequipped() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let player = PlayerStateModel(
            gold: 100,
            heroLevel: 1,
            availableStatPoints: 0,
            atkPoints: 5,
            defPoints: 3,
            hpPoints: 20,
            lastOpenedAt: Date(),
            onboardingStep: 3
        )
        context.insert(player)
        context.insert(completedCraftTask(
            definitionKey: "tutorial_craft",
            actorKey: AppConstants.Actor.blacksmith,
            equipmentKey: "rusty_sword"
        ))
        try context.save()

        let result = TaskClaimService(context: context).claimAllCompleted()
        let equipment = try context.fetch(FetchDescriptor<EquipmentModel>())
        let tasks = try context.fetch(FetchDescriptor<TaskModel>())

        XCTAssertEqual(result.equipmentsAdded, 1)
        XCTAssertEqual(result.tasksDeleted, 1)
        XCTAssertEqual(equipment.count, 1)
        XCTAssertEqual(equipment.first?.defKey, "rusty_sword")
        XCTAssertEqual(equipment.first?.slot, .weapon)
        XCTAssertEqual(equipment.first?.isEquipped, false)
        XCTAssertTrue(tasks.isEmpty)
    }

    func test_claimTutorialArmor_addsArmorUnequipped() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let player = PlayerStateModel(
            gold: 100,
            heroLevel: 1,
            availableStatPoints: 0,
            atkPoints: 5,
            defPoints: 3,
            hpPoints: 20,
            lastOpenedAt: Date(),
            onboardingStep: 8
        )
        context.insert(player)
        context.insert(completedCraftTask(
            definitionKey: "tutorial_armor",
            actorKey: AppConstants.Actor.tailor,
            equipmentKey: "wildland_armor"
        ))
        try context.save()

        _ = TaskClaimService(context: context).claimAllCompleted()
        let equipment = try context.fetch(FetchDescriptor<EquipmentModel>())

        XCTAssertEqual(equipment.count, 1)
        XCTAssertEqual(equipment.first?.defKey, "wildland_armor")
        XCTAssertEqual(equipment.first?.slot, .armor)
        XCTAssertEqual(equipment.first?.isEquipped, false)
    }

    func test_claimNormalCraft_addsEquipmentUnequipped() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let player = PlayerStateModel(
            gold: 100,
            heroLevel: 1,
            availableStatPoints: 0,
            atkPoints: 5,
            defPoints: 3,
            hpPoints: 20,
            lastOpenedAt: Date(),
            onboardingStep: 8
        )
        context.insert(player)
        context.insert(completedCraftTask(
            definitionKey: "recipe_common_weapon",
            actorKey: AppConstants.Actor.blacksmith,
            equipmentKey: "common_weapon"
        ))
        try context.save()

        _ = TaskClaimService(context: context).claimAllCompleted()
        let equipment = try context.fetch(FetchDescriptor<EquipmentModel>())

        XCTAssertEqual(equipment.count, 1)
        XCTAssertEqual(equipment.first?.defKey, "common_weapon")
        XCTAssertEqual(equipment.first?.isEquipped, false)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            PlayerStateModel.self,
            MaterialInventoryModel.self,
            ConsumableInventoryModel.self,
            EquipmentModel.self,
            TaskModel.self,
            DungeonProgressionModel.self,
            AchievementProgressModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func completedCraftTask(
        definitionKey: String,
        actorKey: String,
        equipmentKey: String
    ) -> TaskModel {
        TaskModel(
            kind: .craft,
            actorKey: actorKey,
            definitionKey: definitionKey,
            startedAt: Date().addingTimeInterval(-2),
            endsAt: Date().addingTimeInterval(-1),
            status: .completed,
            resultCraftedEquipKey: equipmentKey
        )
    }
}
