// TaskCreationService.swift
// 任務建立入口
//
// 責任：建立三種任務的前置驗證與正確欄位填入，然後委派給 TaskRepository 寫入。
//
// 鑄造任務特殊規則：
//   - 素材和金幣在建立時立即扣除（不在結算時扣）
//   - resultCraftedEquipKey 在建立時就填入（配方決定輸出，不需 RNG）
//   - 扣除 + 建立 TaskModel 原子完成（repository.insert 內部統一 save）
//
// 地下城任務特殊規則：
//   - 需傳入英雄戰力快照（snapshotPower），結算時用此值而非當前戰力
//   - 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥

import Foundation
import SwiftData

// MARK: - 錯誤定義

enum TaskCreationError: Error, LocalizedError {
    case locationNotFound(String)
    case recipeNotFound(String)
    case areaNotFound(String)
    case insufficientMaterials
    case insufficientGold
    case actorBusy(String)
    case playerAlreadyInDungeon
    case noPlayerState
    case noInventory

    var errorDescription: String? {
        switch self {
        case .locationNotFound:      return "找不到採集地點"
        case .recipeNotFound:        return "找不到鑄造配方"
        case .areaNotFound:          return "找不到地下城區域"
        case .insufficientMaterials: return "素材不足，無法鑄造"
        case .insufficientGold:      return "金幣不足，無法鑄造"
        case .actorBusy(let key):    return "\(key) 正在執行任務"
        case .playerAlreadyInDungeon: return "英雄已在地下城中"
        case .noPlayerState:         return "找不到玩家資料"
        case .noInventory:           return "找不到素材庫存"
        }
    }
}

// MARK: - TaskCreationService

struct TaskCreationService {

    let context: ModelContext
    private let repository: TaskRepository

    init(context: ModelContext) {
        self.context    = context
        self.repository = TaskRepository(context: context)
    }

    // MARK: - 採集任務

    /// 建立採集任務。
    /// 驗證：地點存在、該採集者目前沒有進行中任務。
    /// durationSeconds：玩家選擇的時長；需屬於 def.durationOptions 之一。
    func createGatherTask(actorKey: String, locationKey: String, durationSeconds: Int) throws {
        guard let def = GatherLocationDef.find(key: locationKey) else {
            throw TaskCreationError.locationNotFound(locationKey)
        }
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == actorKey && $0.kind == .gather }) {
            throw TaskCreationError.actorBusy(actorKey)
        }

        let duration = def.durationOptions.contains(durationSeconds)
            ? durationSeconds
            : def.shortestDuration   // 防呆：不在選項內時退回最短
        let now = Date.now
        let task = TaskModel(
            kind:          .gather,
            actorKey:      actorKey,
            definitionKey: locationKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration))
        )
        repository.insert(task)
    }

    // MARK: - 鑄造任務

    /// 建立鑄造任務。
    /// 驗證：配方存在、鑄造師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材，resultCraftedEquipKey 在建立時填入。
    func createCraftTask(recipeKey: String) throws {
        guard let def = CraftRecipeDef.find(key: recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }

        // 鑄造師是否閒置
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == AppConstants.Actor.blacksmith }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.blacksmith)
        }

        // 讀取玩家與庫存
        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }

        // 驗證資源
        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for req in def.requiredMaterials {
            guard inventory.amount(of: req.material) >= req.amount else {
                throw TaskCreationError.insufficientMaterials
            }
        }

        // 扣除資源
        player.gold -= def.goldCost
        for req in def.requiredMaterials {
            inventory.deduct(req.amount, of: req.material)
        }

        // 首件鑄造特快（30 秒完成，生涯僅一次）
        var durationOverride: Int? = nil
        if !player.hasUsedFirstCraftBoost {
            durationOverride = AppConstants.Game.firstBoostSeconds
            player.hasUsedFirstCraftBoost = true
        }

        let duration: Int
        if let override = durationOverride {
            duration = override
        } else {
            let multiplier = NpcUpgradeDef.craftDurationMultiplier(tier: player.blacksmithTier)
            duration = max(30, Int(Double(def.durationSeconds) * multiplier))
        }
        let now = Date.now
        let task = TaskModel(
            kind:          .craft,
            actorKey:      AppConstants.Actor.blacksmith,
            definitionKey: recipeKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            durationOverride:      durationOverride,
            resultCraftedEquipKey: def.outputEquipmentKey
        )
        // repository.insert 內部呼叫 context.save()，原子儲存扣除+建立
        repository.insert(task)
    }

    // MARK: - 地下城任務

    /// 建立 V2-1 地下城（樓層）任務。
    /// 驗證：樓層存在、玩家目前沒有進行中地下城任務。
    /// 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥。
    func createDungeonFloorTask(floorKey: String, durationSeconds: Int, heroStats: HeroStats) throws {
        guard DungeonFloorDef.find(key: floorKey) != nil else {
            throw TaskCreationError.areaNotFound(floorKey)
        }

        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.kind == .dungeon && $0.actorKey == AppConstants.Actor.player }) {
            throw TaskCreationError.playerAlreadyInDungeon
        }

        let playerDesc = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(playerDesc))?.first else {
            throw TaskCreationError.noPlayerState
        }

        var durationOverride: Int? = nil
        var forcedBattles: Int? = nil
        if !player.hasUsedFirstDungeonBoost && durationSeconds == AppConstants.DungeonDuration.short {
            durationOverride = AppConstants.Game.firstBoostSeconds
            forcedBattles    = AppConstants.Game.forcedBattlesFirstRun
            player.hasUsedFirstDungeonBoost = true
        }

        let duration = durationOverride ?? durationSeconds
        let now = Date.now
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: floorKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            durationOverride: durationOverride,
            forcedBattles:    forcedBattles,
            snapshotPower:    heroStats.power,
            snapshotAgi:      heroStats.totalAGI,
            snapshotDex:      heroStats.totalDEX
        )
        repository.insert(task)
    }

    /// 建立地下城任務（V1 路徑，以 DungeonAreaDef key 為 definitionKey）。
    /// 驗證：區域存在、玩家目前沒有進行中地下城任務。
    /// 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥。
    func createDungeonTask(areaKey: String, durationSeconds: Int, heroStats: HeroStats) throws {
        guard DungeonAreaDef.find(key: areaKey) != nil else {
            throw TaskCreationError.areaNotFound(areaKey)
        }

        // 玩家是否已在地下城
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.kind == .dungeon && $0.actorKey == AppConstants.Actor.player }) {
            throw TaskCreationError.playerAlreadyInDungeon
        }

        // 讀取玩家（檢查首次出征 flag）
        let playerDesc = FetchDescriptor<PlayerStateModel>()
        guard let player = (try? context.fetch(playerDesc))?.first else {
            throw TaskCreationError.noPlayerState
        }

        // 首次出征特快（選 15 分鐘時觸發，生涯僅一次）
        var durationOverride: Int? = nil
        var forcedBattles: Int? = nil
        if !player.hasUsedFirstDungeonBoost && durationSeconds == AppConstants.DungeonDuration.short {
            durationOverride = AppConstants.Game.firstBoostSeconds
            forcedBattles    = AppConstants.Game.forcedBattlesFirstRun
            player.hasUsedFirstDungeonBoost = true
        }

        let duration = durationOverride ?? durationSeconds
        let now = Date.now
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: areaKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            durationOverride: durationOverride,
            forcedBattles:    forcedBattles,
            snapshotPower:    heroStats.power,
            snapshotAgi:      heroStats.totalAGI,
            snapshotDex:      heroStats.totalDEX
        )
        repository.insert(task)
    }
}
