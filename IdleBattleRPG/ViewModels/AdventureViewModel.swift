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
// V2-1 Ticket 03 補充：progression 查詢方法（isRegionUnlocked / isFloorUnlocked 等）

import Foundation
import SwiftData

@Observable
final class AdventureViewModel {

    // MARK: - V1：地下城解鎖判斷（DungeonAreaDef，供現有 AdventureView 使用）

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

    // MARK: - V2-1：區域推進查詢（DungeonRegionDef，接收 progressionService）
    //
    // 設計原則：ViewModel 不持有 Service，由 View 從 AppState 取得 progressionService 後
    // 以參數形式傳入，保持 ViewModel 輕薄且可測試。

    /// 所有 V2-1 區域定義（永遠可見，但不一定可挑戰）
    func allRegions() -> [DungeonRegionDef] {
        DungeonRegionDef.all
    }

    /// 指定區域是否已解鎖（可挑戰）
    func isRegionUnlocked(_ regionKey: String, service: DungeonProgressionService) -> Bool {
        service.isRegionUnlocked(regionKey)
    }

    /// 指定區域是否已完成（Boss 層首通）
    func isRegionCompleted(_ regionKey: String, service: DungeonProgressionService) -> Bool {
        service.isRegionCompleted(regionKey)
    }

    /// 指定樓層是否可挑戰
    func isFloorUnlocked(regionKey: String, floorIndex: Int, service: DungeonProgressionService) -> Bool {
        service.isFloorUnlocked(regionKey: regionKey, floorIndex: floorIndex)
    }

    /// 指定樓層是否已首通
    func isFloorCleared(regionKey: String, floorIndex: Int, service: DungeonProgressionService) -> Bool {
        service.isFloorCleared(regionKey: regionKey, floorIndex: floorIndex)
    }

    /// Boss 材料是否已見過（等同 Boss 層首通）
    func hasSeenBossMaterial(_ regionKey: String, service: DungeonProgressionService) -> Bool {
        service.hasSeenBossMaterial(regionKey)
    }

    // MARK: - 地下城任務狀態

    /// 玩家目前進行中的地下城任務（nil = 英雄閒置）
    func dungeonTask(from tasks: [TaskModel]) -> TaskModel? {
        tasks.first { $0.kind == .dungeon && $0.actorKey == AppConstants.Actor.player && $0.status == .inProgress }
    }

    /// 當前進行中地下城任務的名稱（支援 V1 area key 和 V2-1 floor key）
    func activeDungeonName(from tasks: [TaskModel]) -> String? {
        guard let task = dungeonTask(from: tasks) else { return nil }
        if let area  = DungeonAreaDef.find(key: task.definitionKey)  { return area.name }
        if let floor = DungeonFloorDef.find(key: task.definitionKey) { return floor.name }
        return nil
    }

    // MARK: - 任務建立委派（View 傳入 context，ViewModel 建 Service 執行）

    /// 建立 V2-1 地下城（樓層）任務
    @discardableResult
    func startDungeonFloor(
        floorKey: String,
        durationSeconds: Int,
        heroStats: HeroStats,
        equippedSkillKeys: [String] = [],  // V6-1
        cuisineKey: String = "",           // V7-4
        potionKey:  String = "",           // V7-4
        context: ModelContext
    ) -> Result<Void, TaskCreationError> {
        do {
            try TaskCreationService(context: context).createDungeonFloorTask(
                floorKey:          floorKey,
                durationSeconds:   durationSeconds,
                heroStats:         heroStats,
                equippedSkillKeys: equippedSkillKeys,
                cuisineKey:        cuisineKey,
                potionKey:         potionKey
            )
            return .success(())
        } catch let e as TaskCreationError {
            return .failure(e)
        } catch {
            return .failure(.areaNotFound("unknown"))
        }
    }
}
