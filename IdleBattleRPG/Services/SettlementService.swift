// SettlementService.swift
// 任務結算服務
//
// 責任：
//   scanAndSettle()  — 找出所有「inProgress + 已到期」的任務，
//                      填入獎勵結果欄位，並標記為 completed。
//
// Phase 7 結算邏輯：
//   ✅ gather  — 確定性 RNG（DeterministicRNG，seed = startedAt.bitPattern XOR taskId.hashValue）
//   ✅ craft   — resultCraftedEquipKey 在任務建立時已填入，此處不再更動
//   ✅ dungeon — 委派 DungeonSettlementEngine（確定性 RNG，勝率公式正式接入）
//
// 注意：獎勵「入帳」（寫入玩家資料）由 TaskClaimService 負責，
//       SettlementService 只負責「計算結果並標記 completed」。

import Foundation
import SwiftData

struct SettlementService {

    let context: ModelContext
    private let repository: TaskRepository

    init(context: ModelContext) {
        self.context    = context
        self.repository = TaskRepository(context: context)
    }

    // MARK: - 掃描並結算

    /// 掃描所有已到期的進行中任務，填入結果，標記為 completed，統一 save。
    @discardableResult
    func scanAndSettle(now: Date = .now) -> [TaskModel] {
        let due = repository.fetchDueTasks(now: now)
        guard !due.isEmpty else { return [] }

        for task in due {
            markCompleted(task)
        }
        repository.save()

        print("[SettlementService] 已結算 \(due.count) 筆: \(due.map { String($0.id.uuidString.prefix(8)) })")
        return due
    }

    // MARK: - Private

    private func markCompleted(_ task: TaskModel) {
        // 先填入結果再改狀態，確保資料一致
        switch task.kind {
        case .gather:  fillGatherResults(task)
        case .craft:   break   // resultCraftedEquipKey 在建立時已填入
        case .dungeon: fillDungeonResults(task)
        }
        task.status = .completed
    }

    // MARK: - Gather 結算（確定性 RNG）

    private func fillGatherResults(_ task: TaskModel) {
        guard let def = GatherLocationDef.find(key: task.definitionKey) else {
            print("[SettlementService] 找不到採集地點定義: \(task.definitionKey)")
            return
        }

        var rng    = DeterministicRNG(task: task)
        let amount = rng.nextInt(in: def.outputRange)

        switch def.outputMaterial {
        case .wood:            task.resultWood            = amount
        case .ore:             task.resultOre             = amount
        case .hide:            task.resultHide            = amount
        case .crystalShard:    task.resultCrystalShard    = amount
        case .ancientFragment: task.resultAncientFragment = amount
        }
    }

    // MARK: - Dungeon 結算（委派 DungeonSettlementEngine）

    private func fillDungeonResults(_ task: TaskModel) {
        guard let area = DungeonAreaDef.find(key: task.definitionKey) else {
            print("[SettlementService] 找不到地下城定義: \(task.definitionKey)")
            return
        }

        let result = DungeonSettlementEngine.settle(task: task, area: area)

        task.resultGold            = result.gold
        task.resultHide            = result.hide
        task.resultCrystalShard    = result.crystalShard
        task.resultAncientFragment = result.ancientFragment
        task.resultBattlesWon      = result.battlesWon
        task.resultBattlesLost     = result.battlesLost
    }
}
