// IdleBattleRPGApp.swift
// App 入口：建立 SwiftData ModelContainer，執行首次 seeding

import SwiftUI
import SwiftData

@main
struct IdleBattleRPGApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for:
                    PlayerStateModel.self,
                    MaterialInventoryModel.self,
                    EquipmentModel.self,
                    TaskModel.self,
                    DungeonProgressionModel.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // 首次啟動 seeding（@MainActor，非 async，不需 await）
                    DatabaseSeeder.seedIfNeeded(
                        context: container.mainContext
                    )
                }
        }
        .modelContainer(container)
    }
}
