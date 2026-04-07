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
// V2-1 Ticket 02：
//   ✅ 12 個區域素材 result 欄位已納入 accumulateMaterials()
//   ✅ MaterialInventoryModel.add() 支援全部 17 種素材，直接統一呼叫
//
// V2-1 Ticket 08：
//   ✅ dungeon Boss 武器掉落（resultCraftedEquipKey + resultRolledAtk）→ EquipmentModel 插入背包

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

        let playerDesc = FetchDescriptor<PlayerStateModel>()
        let player = (try? context.fetch(playerDesc))?.first

        var totalGold      = 0
        var materials      = [MaterialType: Int]()
        var equipmentCount = 0

        for task in completed {
            totalGold += task.resultGold
            accumulateMaterials(from: task, player: player, into: &materials)

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

            // dungeon Boss 武器掉落（Ticket 08）：建立浮動 ATK 版本裝備
            if task.kind == .dungeon, let key = task.resultCraftedEquipKey,
               let def = EquipmentDef.find(key: key) {
                let rolledAtk = task.resultRolledAtk
                let newEquip = EquipmentModel(
                    defKey: def.key, slot: def.slot,
                    rarity: def.rarity, isEquipped: false,
                    rolledAtk: rolledAtk
                )
                context.insert(newEquip)
                equipmentCount += 1
            }
        }

        let totalExp = completed.reduce(0) { $0 + $1.resultExp }
        if totalExp > 0 { creditExp(totalExp) }

        creditGold(totalGold)
        creditMaterials(materials)

        // 統計追蹤
        if let player {
            player.totalGoldEarned += totalGold
            for task in completed {
                if task.kind == .dungeon {
                    player.totalBattlesWon  += task.resultBattlesWon  ?? 0
                    player.totalBattlesLost += task.resultBattlesLost ?? 0
                }
                if task.resultCraftedEquipKey != nil {
                    player.totalItemsCrafted += 1
                }
            }
        }

        for task in completed {
            context.delete(task)
        }

        repository.save()

        print("[TaskClaimService] 收下 \(completed.count) 筆，金幣 +\(totalGold)，素材 \(materials)")
        return ClaimResult(
            goldGained:      totalGold,
            materialsGained: materials,
            equipmentsAdded: equipmentCount,
            tasksDeleted:    completed.count
        )
    }

    // MARK: - Private helpers

    /// 從任務 result* 欄位彙整所有素材（V1 + V2-1 全 17 種）。
    /// 採集任務依採集者 tier 對每種有產出的素材加 bonus（不修改 result* 欄位）。
    private func accumulateMaterials(from task: TaskModel, player: PlayerStateModel?, into materials: inout [MaterialType: Int]) {
        let bonus: Int
        if task.kind == .gather, let player {
            bonus = NpcUpgradeDef.gatherBonus(tier: player.tier(for: task.actorKey))
        } else {
            bonus = 0
        }

        for mat in MaterialType.allCases {
            let amount = task.resultAmount(of: mat)
            guard amount > 0 else { continue }
            materials[mat, default: 0] += amount + bonus
        }
    }

    private func creditExp(_ amount: Int) {
        guard amount > 0 else { return }
        let descriptor = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(descriptor))?.first else { return }
        player.heroExp += amount
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
