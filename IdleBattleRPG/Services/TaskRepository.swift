// TaskRepository.swift
// TaskModel 薄層 CRUD
//
// 責任：TaskModel 的查詢、插入、刪除，以及常用篩選快取方法。
// 不含業務邏輯、不含驗證，純粹的資料存取層。
// 業務邏輯由 TaskCreationService / SettlementService 負責。

import Foundation
import SwiftData

struct TaskRepository {

    let context: ModelContext

    // MARK: - 查詢

    func fetchAll() -> [TaskModel] {
        let descriptor = FetchDescriptor<TaskModel>(
            sortBy: [SortDescriptor(\.startedAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchInProgress() -> [TaskModel] {
        fetchAll().filter { $0.status == .inProgress }
    }

    func fetchCompleted() -> [TaskModel] {
        fetchAll().filter { $0.status == .completed }
    }

    /// 回傳所有「進行中且已到期」的任務，供 SettlementService 掃描用
    func fetchDueTasks(now: Date = .now) -> [TaskModel] {
        fetchInProgress().filter { $0.endsAt <= now }
    }

    // MARK: - 寫入

    func insert(_ task: TaskModel) {
        context.insert(task)
        save()
    }

    func delete(_ task: TaskModel) {
        context.delete(task)
        save()
    }

    /// 將目前 context 中的所有變更持久化
    func save() {
        try? context.save()
    }
}
