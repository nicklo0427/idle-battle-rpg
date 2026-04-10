// IdleBattleRPGApp.swift
// App 入口：建立 SwiftData ModelContainer，執行首次 seeding

import SwiftUI
import SwiftData

@main
struct IdleBattleRPGApp: App {

    let container: ModelContainer

    init() {
        let schema = Schema([
            PlayerStateModel.self,
            MaterialInventoryModel.self,
            EquipmentModel.self,
            TaskModel.self,
            DungeonProgressionModel.self,
            AchievementProgressModel.self
        ])
        let config = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Schema 有異動（例如新增欄位）導致舊 Store 無法載入。
            // 開發階段：直接刪除舊 Store 並重建；DatabaseSeeder 會重新 seed。
            Self.deleteStore(at: config.url)
            do {
                container = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer even after wiping store: \(error)")
            }
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

    // MARK: - Store 清理

    /// 刪除指定 URL 的 SQLite 檔案（含 -shm / -wal journal 檔）
    private static func deleteStore(at url: URL) {
        let fm   = FileManager.default
        let base = url.deletingPathExtension().path
        let ext  = url.pathExtension                // "store"
        for suffix in [ext, "\(ext)-shm", "\(ext)-wal"] {
            try? fm.removeItem(atPath: "\(base).\(suffix)")
        }
    }
}
