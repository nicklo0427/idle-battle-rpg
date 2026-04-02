// AdventureViewModel.swift
// 冒險頁面的展示協調 ViewModel
//
// 責任：
//   - 根據英雄戰力判斷地下城區域是否解鎖，並提供頁面所需的顯示資訊。
//   - 查詢玩家目前是否在地下城中。
//   - 建立地下城任務（委派給 TaskCreationService）。
//   - 不查詢 SwiftData，不寫入，純粹做資料轉換與業務協調。
//
// Phase 6 補充：dungeonTask 查詢、startDungeon 建立入口

import Foundation
import SwiftData

@Observable
final class AdventureViewModel {

    // MARK: - 地下城解鎖判斷

    /// 返回所有地下城區域
    func allAreas() -> [DungeonAreaDef] {
        DungeonAreaDef.all
    }

    /// 根據英雄當前戰力，判斷指定地下城是否可進入
    func isAccessible(_ area: DungeonAreaDef, heroStats: HeroStats?) -> Bool {
        if area.requiredPower == 0 { return true }
        guard let stats = heroStats else { return false }
        return stats.power >= area.requiredPower
    }

    /// 解鎖門檻文字（顯示用）
    func lockLabel(for area: DungeonAreaDef) -> String {
        area.requiredPower == 0 ? "初始解鎖" : "需戰力 \(area.requiredPower)"
    }

    // MARK: - 地下城任務狀態

    /// 玩家目前進行中的地下城任務（nil = 英雄閒置）
    func dungeonTask(from tasks: [TaskModel]) -> TaskModel? {
        tasks.first { $0.kind == .dungeon && $0.actorKey == AppConstants.Actor.player && $0.status == .inProgress }
    }

    /// 玩家目前進行的地下城任務對應的區域定義
    func currentArea(from tasks: [TaskModel]) -> DungeonAreaDef? {
        guard let task = dungeonTask(from: tasks) else { return nil }
        return DungeonAreaDef.find(key: task.definitionKey)
    }

    // MARK: - 任務建立委派（View 傳入 context，ViewModel 建 Service 執行）

    /// 建立地下城任務
    @discardableResult
    func startDungeon(
        areaKey: String,
        durationSeconds: Int,
        heroStats: HeroStats,
        context: ModelContext
    ) -> Result<Void, TaskCreationError> {
        do {
            try TaskCreationService(context: context).createDungeonTask(
                areaKey: areaKey,
                durationSeconds: durationSeconds,
                heroStats: heroStats
            )
            return .success(())
        } catch let e as TaskCreationError {
            return .failure(e)
        } catch {
            return .failure(.areaNotFound("unknown"))
        }
    }
}
