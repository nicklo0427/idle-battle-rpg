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
// V2-1 Ticket 02 新增：
//   ✅ dungeon V2-1 路徑 — 若 definitionKey 對應 DungeonFloorDef，
//                          使用 settle(task:floor:) 並寫入 12 個區域素材 result 欄位
//
// V2-1 Ticket 03 新增：
//   ✅ dungeon — 若為 V2-1 floor 任務，結算後標記樓層首通（DungeonProgressionService）
//
// V2-1 Ticket 07 新增：
//   ✅ dungeon — 首通時將 floor.key 寫入 task.resultFirstClearedFloorKey（SettlementSheet 解鎖提示用）
//
// V2-1 Ticket 08 新增：
//   ✅ dungeon Boss 層 — battlesWon >= 1 時寫入 resultCraftedEquipKey + resultRolledAtk（浮動 ATK）
//
// 注意：獎勵「入帳」（寫入玩家資料）由 TaskClaimService 負責，
//       SettlementService 只負責「計算結果並標記 completed」。

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
        case .dungeon:
            fillDungeonResults(task)
            markDungeonProgression(task)
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

        switch def.outputMaterial {
        case .wood:            task.resultWood            = amount
        case .ore:             task.resultOre             = amount
        case .hide:            task.resultHide            = amount
        case .crystalShard:    task.resultCrystalShard    = amount
        case .ancientFragment: task.resultAncientFragment = amount
        // V2-1 區域素材：採集地點不會輸出這些素材，此 case 不會觸發
        case .oldPostBadge, .driedHideBundle, .splitHornBone, .riftFangRoyalBadge,
             .mineLampCopperClip, .tunnelIronClip, .veinStoneSlab, .stoneSwallowCore,
             .relicSealRing, .oathInscriptionShard, .foreShrineClip, .ancientKingCore:
            break
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
