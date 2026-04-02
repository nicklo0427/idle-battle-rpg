// TaskClaimService.swift
// 任務收下與獎勵入帳服務
//
// 責任：
//   1. 讀取所有 status == .completed 的任務
//   2. 讀取各任務的 result* 欄位，將獎勵加入 PlayerState / MaterialInventory
//   3. craft 任務：建立 EquipmentModel 並加入背包
//   4. 將已處理的任務全部刪除
//   5. 統一一次 save()
//
// Phase 5 範圍：
//   ✅ gather 任務 — 素材 / 金幣入帳
//   ✅ craft 任務  — 裝備進背包（resultCraftedEquipKey 已在建立時填入）
//   ✅ dungeon 任務 — 金幣入帳（resultGold；Phase 5 RNG 尚未實作故值為 0）
//   ❌ 不做完整掉落 RNG（Phase 6+）
//   ❌ 不做裝備強化（V2）

import Foundation
import SwiftData

// MARK: - ClaimResult（Value Type，供 UI 顯示用）

struct ClaimResult {
    let goldGained: Int
    let materialsGained: [MaterialType: Int]
    let equipmentsAdded: Int
    let tasksDeleted: Int

    var isEmpty: Bool { goldGained == 0 && materialsGained.isEmpty && equipmentsAdded == 0 }

    /// 供 SettlementViewModel 轉換成顯示行
    var rewardLines: [String] {
        var lines: [String] = []
        if goldGained > 0 { lines.append("💰 金幣 +\(goldGained)") }
        for mat in MaterialType.allCases {
            if let amt = materialsGained[mat], amt > 0 {
                lines.append("\(mat.icon) \(mat.displayName) +\(amt)")
            }
        }
        if equipmentsAdded > 0 { lines.append("🗡 新裝備 ×\(equipmentsAdded)") }
        return lines
    }
}

// MARK: - TaskClaimService

struct TaskClaimService {

    let context: ModelContext
    private let repository: TaskRepository

    init(context: ModelContext) {
        self.context    = context
        self.repository = TaskRepository(context: context)
    }

    // MARK: - 收下全部已完成任務

    /// 一次收下所有 completed 任務，入帳所有獎勵，刪除任務，統一 save。
    @discardableResult
    func claimAllCompleted() -> ClaimResult {
        let completed = repository.fetchCompleted()
        guard !completed.isEmpty else {
            return ClaimResult(goldGained: 0, materialsGained: [:], equipmentsAdded: 0, tasksDeleted: 0)
        }

        // 聚合所有獎勵
        var totalGold      = 0
        var materials      = [MaterialType: Int]()
        var equipmentCount = 0

        for task in completed {
            totalGold += task.resultGold
            accumulateMaterials(from: task, into: &materials)

            // craft 任務：建立裝備並插入背包
            if task.kind == .craft, let key = task.resultCraftedEquipKey,
               let def = EquipmentDef.find(key: key) {
                let newEquip = EquipmentModel(
                    defKey: def.key, slot: def.slot,
                    rarity: def.rarity, isEquipped: false
                )
                context.insert(newEquip)
                equipmentCount += 1
            }
        }

        // 寫入 PlayerState（金幣）
        creditGold(totalGold)

        // 寫入 MaterialInventory（素材）
        creditMaterials(materials)

        // 刪除所有已收下任務
        for task in completed {
            context.delete(task)
        }

        repository.save()

        print("[TaskClaimService] 收下 \(completed.count) 筆，金幣 +\(totalGold)，素材 \(materials)")
        return ClaimResult(
            goldGained:       totalGold,
            materialsGained:  materials,
            equipmentsAdded:  equipmentCount,
            tasksDeleted:     completed.count
        )
    }

    // MARK: - Private helpers

    private func accumulateMaterials(from task: TaskModel, into materials: inout [MaterialType: Int]) {
        func add(_ value: Int, _ type: MaterialType) {
            guard value > 0 else { return }
            materials[type, default: 0] += value
        }
        add(task.resultWood,            .wood)
        add(task.resultOre,             .ore)
        add(task.resultHide,            .hide)
        add(task.resultCrystalShard,    .crystalShard)
        add(task.resultAncientFragment, .ancientFragment)
    }

    private func creditGold(_ amount: Int) {
        guard amount > 0 else { return }
        let descriptor = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(descriptor))?.first else { return }
        player.gold += amount
    }

    private func creditMaterials(_ materials: [MaterialType: Int]) {
        guard !materials.isEmpty else { return }
        let descriptor = FetchDescriptor<MaterialInventoryModel>()
        guard let inventory = (try? context.fetch(descriptor))?.first else { return }
        for (material, amount) in materials {
            inventory.add(amount, of: material)
        }
    }
}
