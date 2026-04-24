// SettlementService.swift
// 任務結算服務
//
// 責任：
//   scanAndSettle()  — 找出所有「inProgress + 已到期」的任務，
//                      填入獎勵結果欄位（非 dungeon），並標記為 completed。
//
// 結算邏輯：
//   ✅ gather  — 確定性 RNG（DeterministicRNG，seed = startedAt.bitPattern XOR taskId.hashValue）
//   ✅ craft   — resultCraftedEquipKey 在任務建立時已填入，此處不再更動
//   ✅ dungeon — V6-3 T01 起：只標記 battlePending = true，戰鬥結果由 DungeonBattleSheet 即時計算
//               （原 DungeonSettlementEngine / markDungeonProgression 移至 DungeonBattleSheet）
//
// 注意：獎勵「入帳」（寫入玩家資料）由 TaskClaimService / DungeonBattleSheet 負責，
//       SettlementService 只負責「計算非戰鬥結果並標記 completed」。

import Foundation
import SwiftData

struct SettlementService {

    let context: ModelContext
    private let repository: TaskRepository
    private let progressionService: DungeonProgressionService

    init(context: ModelContext) {
        self.context            = context
        self.repository         = TaskRepository(context: context)
        self.progressionService = DungeonProgressionService(context: context)
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
        switch task.kind {
        case .gather:  fillGatherResults(task)
        case .craft:   break   // resultCraftedEquipKey 在建立時已填入
        case .cuisine: break   // resultCuisineKey 在建立時已填入（V7-3）
        case .alchemy: break   // 結果在 TaskClaimService 處理（V7-4）
        case .farming: fillFarmResults(task)  // V7-4 農田任務
        case .dungeon:
            // V6-3 T01：不預算戰鬥結果，改由玩家即時發起（DungeonBattleSheet）
            // fillDungeonResults / markDungeonProgression 移至 DungeonBattleSheet.finalizeBattle()
            task.battlePending = true
        }
        task.status = .completed
    }

    // MARK: - Gather 結算（確定性 RNG）

    private func fillGatherResults(_ task: TaskModel) {
        guard let def = GatherLocationDef.find(key: task.definitionKey) else {
            print("[SettlementService] 找不到採集地點定義: \(task.definitionKey)")
            return
        }

        let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let cycles = max(1, Int(actualDuration) / def.shortestDuration)

        var rng    = DeterministicRNG(task: task)
        var amount = 0
        for _ in 0..<cycles {
            amount += rng.nextInt(in: def.outputRange)
        }

        // 隨機事件（V7-1 T03）：同一 rng 繼續 roll，保持確定性
        let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
        let rareNode  = GathererSkillNodeDef.nodes(for: task.actorKey).first { $0.rareChancePerPoint > 0 }
        let rareLevel = rareNode.map { player?.skillLevel(nodeKey: $0.key, actorKey: task.actorKey) ?? 0 } ?? 0
        let rareBonus = rareLevel * 5          // 每點 +5%
        let threshold = max(75, 90 - rareBonus) // 最低降至 75%（稀有系最高 25%）

        let roll = rng.nextInt(in: 0...99)
        switch roll {
        case 0 ..< threshold:
            task.gatherEventKey = nil
        case threshold ..< (threshold + 6):
            task.gatherEventKey = "bumper_harvest"
            amount *= 2
        case (threshold + 6) ..< (threshold + 9):
            task.gatherEventKey = "rare_find"
        default:
            task.gatherEventKey = "gold_vein"
            task.resultGold    += rng.nextInt(in: 30...100)
        }

        task.setResult(amount, of: def.outputMaterial)
    }

    // MARK: - Farm 結算（V7-4，確定性 RNG）

    private func fillFarmResults(_ task: TaskModel) {
        guard let seedType = MaterialType(rawValue: task.definitionKey) else {
            print("[SettlementService] 無法識別種子類型: \(task.definitionKey)")
            return
        }

        // 農夫 Tier 決定品質機率（上限 3）
        let tier = min(
            (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first?.gatherer5Tier ?? 0,
            3
        )

        // 品質門檻（roll 值，由小到大：頂級 < 高級分界 < 1.0）
        let topThreshold:  [Double] = [0.02, 0.06, 0.12, 0.18]
        let highThreshold: [Double] = [0.20, 0.30, 0.40, 0.50]  // top + high 累計

        var rng = DeterministicRNG(task: task)
        let baseYield = 4

        for _ in 0..<baseYield {
            let roll   = rng.nextDouble()
            let isTop  = roll < topThreshold[tier]
            let isHigh = !isTop && roll < highThreshold[tier]

            switch seedType {
            case .wheatSeed:
                if isTop        { task.resultWheatTop  += 1 }
                else if isHigh  { task.resultWheatHigh += 1 }
                else            { task.resultWheat     += 1 }
            case .vegetableSeed:
                if isTop        { task.resultVegetableTop  += 1 }
                else if isHigh  { task.resultVegetableHigh += 1 }
                else            { task.resultVegetable     += 1 }
            case .fruitSeed:
                if isTop        { task.resultFruitTop  += 1 }
                else if isHigh  { task.resultFruitHigh += 1 }
                else            { task.resultFruit     += 1 }
            case .spiritGrainSeed:
                if isTop        { task.resultSpiritGrainTop  += 1 }
                else if isHigh  { task.resultSpiritGrainHigh += 1 }
                else            { task.resultSpiritGrain     += 1 }
            default:
                // 非種子類型不應出現在農田任務中
                break
            }
        }
    }

    // MARK: - Dungeon 結算（V1 + V2-1 雙路徑）

    private func fillDungeonResults(_ task: TaskModel) {
        // V1 路徑：definitionKey = DungeonAreaDef.key（e.g. "wildland"）
        if let area = DungeonAreaDef.find(key: task.definitionKey) {
            let result = DungeonSettlementEngine.settle(task: task, area: area)
            task.resultGold            = result.gold
            task.resultHide            = result.hide
            task.resultCrystalShard    = result.crystalShard
            task.resultAncientFragment = result.ancientFragment
            task.resultBattlesWon      = result.battlesWon
            task.resultBattlesLost     = result.battlesLost
            return
        }

        // V2-1 路徑：definitionKey = DungeonFloorDef.key（e.g. "wildland_floor_1"）
        let allFloors = DungeonRegionDef.all.flatMap { $0.floors }
        if let floor = allFloors.first(where: { $0.key == task.definitionKey }) {
            let result = DungeonSettlementEngine.settle(task: task, floor: floor)
            task.resultGold        = result.gold
            task.resultBattlesWon  = result.battlesWon
            task.resultBattlesLost = result.battlesLost
            // 寫入區域素材（利用 TaskModel 的泛型 setter）
            for (material, amount) in result.materials {
                task.setResult(amount, of: material)
            }
            task.resultExp         = result.exp
            // Boss 武器掉落（Ticket 08）
            if let bossWeapon = result.rolledBossWeapon {
                task.resultCraftedEquipKey = bossWeapon.equipKey
                task.resultRolledAtk       = bossWeapon.atk
            }
            return
        }

        print("[SettlementService] 找不到地下城定義: \(task.definitionKey)")
    }

    // MARK: - V2-1 推進標記（Ticket 03 / Ticket 07）

    /// 若任務的 definitionKey 對應到 V2-1 DungeonFloorDef，則標記該樓層首通。
    /// V1 任務（DungeonAreaDef key）自動略過，冪等。
    /// Ticket 07：若本次為首通，將 floor.key 寫入 task.resultFirstClearedFloorKey，
    ///            供 SettlementViewModel 在結算 Sheet 顯示解鎖提示。
    private func markDungeonProgression(_ task: TaskModel) {
        let allFloors = DungeonRegionDef.all.flatMap { $0.floors }
        guard let floor = allFloors.first(where: { $0.key == task.definitionKey }) else { return }

        // 首通前快照：若已是首通，標記後不重複顯示解鎖提示
        let wasCleared = progressionService.isFloorCleared(
            regionKey:  floor.regionKey,
            floorIndex: floor.floorIndex
        )

        progressionService.markFloorCleared(
            regionKey:  floor.regionKey,
            floorIndex: floor.floorIndex
        )

        // 本次才是首通 → 記錄 floor key 以觸發結算 Sheet 解鎖行
        if !wasCleared {
            task.resultFirstClearedFloorKey = floor.key
        }
    }
}
