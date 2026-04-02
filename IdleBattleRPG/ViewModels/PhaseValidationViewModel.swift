// PhaseValidationViewModel.swift
// Phase 驗證頁的最薄 ViewModel
//
// 責任：
//   1. 提供 addTestGatherTask()，讓 ContentView 不再直接操作 ModelContext 寫入
//   2. 提供 heroStats(player:equipped:)，讓 ContentView 不自己呼叫計算公式
//
// 這個 ViewModel 故意保持最薄。Phase 4 正式頁面建立後，此檔案可以直接移除。

import Foundation
import SwiftData

@Observable
final class PhaseValidationViewModel {

    private let taskCreationService: TaskCreationService

    init(context: ModelContext) {
        self.taskCreationService = TaskCreationService(context: context)
    }

    // MARK: - 任務操作

    /// 新增一筆採集者 1 的測試採集任務（森林）
    func addTestGatherTask() {
        let loc = GatherLocationDef.all[0]
        try? taskCreationService.createGatherTask(
            actorKey:        AppConstants.Actor.gatherer1,
            locationKey:     loc.key,
            durationSeconds: loc.shortestDuration
        )
    }

    // MARK: - 英雄戰力聚合

    /// 從 View 傳入已查詢的 player / equipped 資料，委派給 HeroStatsService 計算
    func heroStats(player: PlayerStateModel?, equipped: [EquipmentModel]) -> HeroStats? {
        guard let player else { return nil }
        return HeroStatsService.compute(player: player, equipped: equipped)
    }
}
