// DungeonProgressionRepository.swift
// 地下城推進狀態薄層 CRUD
//
// 責任：DungeonProgressionModel 的查詢與寫入（不含業務邏輯）
//   - fetch()         — 取得單例（可能為 nil，首次啟動前）
//   - fetchOrCreate() — 取得或建立單例
//   - save()          — 持久化變更
//
// 注意：此 Repository 與 TaskRepository 同樣只做 CRUD，
//       判斷邏輯一律在 DungeonProgressionService 中。

import Foundation
import SwiftData

struct DungeonProgressionRepository {

    let context: ModelContext

    // MARK: - 查詢

    /// 取得推進狀態單例。若 DB 中尚無資料（首次啟動前），回傳 nil。
    func fetch() -> DungeonProgressionModel? {
        let descriptor = FetchDescriptor<DungeonProgressionModel>()
        return (try? context.fetch(descriptor))?.first
    }

    /// 取得推進狀態單例。若不存在則建立（含預設值：wildland 已解鎖，無首通紀錄）並立即 save。
    func fetchOrCreate() -> DungeonProgressionModel {
        if let existing = fetch() { return existing }
        let model = DungeonProgressionModel()
        context.insert(model)
        save()
        return model
    }

    // MARK: - 寫入

    func save() {
        try? context.save()
    }
}
