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
    case insufficientConsumable(String)

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
        case .insufficientConsumable: return "消耗品庫存不足"
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

        let baseDuration = def.durationOptions.contains(durationSeconds)
            ? durationSeconds
            : def.shortestDuration   // 防呆：不在選項內時退回最短

        // 採集速度技能縮減（V7-1 T02）
        let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
        let speedNode = GathererSkillNodeDef.nodes(for: actorKey).first { $0.speedReductionPerPoint > 0 }
        let speedLevel = speedNode.map { player?.skillLevel(nodeKey: $0.key, actorKey: actorKey) ?? 0 } ?? 0
        let speedMultiplier = 1.0 - Double(speedLevel) * (speedNode?.speedReductionPerPoint ?? 0)
        let duration = max(60, Int(Double(baseDuration) * speedMultiplier))

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

    // MARK: - 料理任務（V7-3）

    /// 建立料理任務。
    /// 驗證：配方存在、廚師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材，resultCuisineKey 在建立時填入。
    func createCuisineTask(recipeKey: String) throws {
        guard let def = CuisineDef.find(recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }

        // 廚師是否閒置
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == AppConstants.Actor.chef }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.chef)
        }

        // 讀取玩家與庫存
        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }

        // 驗證資源
        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for (material, amount) in def.ingredients {
            guard inventory.amount(of: material) >= amount else {
                throw TaskCreationError.insufficientMaterials
            }
        }

        // 扣除資源
        player.gold -= def.goldCost
        for (material, amount) in def.ingredients {
            inventory.deduct(amount, of: material)
        }

        // 廚師 tier 縮短烹飪時間（複用 craftDurationMultiplier）
        let multiplier = NpcUpgradeDef.craftDurationMultiplier(tier: player.chefTier)
        let duration   = max(30, Int(Double(def.cookMinutes * 60) * multiplier))

        let now = Date.now
        let task = TaskModel(
            kind:          .cuisine,
            actorKey:      AppConstants.Actor.chef,
            definitionKey: recipeKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration))
        )
        task.resultCuisineKey = def.key
        repository.insert(task)
    }

    // MARK: - 農田任務（V7-4）

    /// 建立農田種植任務。
    /// 驗證：農田閒置、玩家持有該種子 ≥ 1。
    /// 建立前立即扣除種子 1 顆（與鑄造扣素材邏輯相同）。
    func createFarmTask(plotKey: String, seedType: MaterialType, durationSeconds: Int) throws {
        // 1. 農田是否閒置
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == plotKey && $0.kind == .farming }) {
            throw TaskCreationError.actorBusy(plotKey)
        }

        // 2. 讀取庫存
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else {
            throw TaskCreationError.noInventory
        }

        // 3. 驗證種子庫存 ≥ 1
        guard inventory.amount(of: seedType) >= 1 else {
            throw TaskCreationError.insufficientMaterials
        }

        // 4. 扣除種子
        inventory.deduct(1, of: seedType)

        // 5. 建立任務（definitionKey = seedType.rawValue，供結算時判斷農作物種類）
        let now = Date.now
        let task = TaskModel(
            kind:          .farming,
            actorKey:      plotKey,
            definitionKey: seedType.rawValue,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(durationSeconds))
        )
        repository.insert(task)
    }

    // MARK: - 煉藥任務（V7-4）

    /// 建立煉藥任務。
    /// 驗證：配方存在、製藥師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材。
    func createAlchemyTask(recipeKey: String) throws {
        guard let def = PotionDef.find(recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }

        // 製藥師是否閒置
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == AppConstants.Actor.pharmacist }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.pharmacist)
        }

        // 讀取玩家與庫存
        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }

        // 驗證資源
        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for (mat, amount) in def.ingredients {
            guard inventory.amount(of: mat) >= amount else {
                throw TaskCreationError.insufficientMaterials
            }
        }

        // 扣除資源
        player.gold -= def.goldCost
        for (mat, amount) in def.ingredients {
            inventory.deduct(amount, of: mat)
        }

        // 製藥師 tier 縮短釀製時間（複用 craftDurationMultiplier）
        let multiplier = NpcUpgradeDef.craftDurationMultiplier(tier: player.pharmacistTier)
        let duration   = max(30, Int(Double(def.brewMinutes * 60) * multiplier))

        let now = Date.now
        let task = TaskModel(
            kind:          .alchemy,
            actorKey:      AppConstants.Actor.pharmacist,
            definitionKey: def.key,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration))
        )
        repository.insert(task)
    }

    // MARK: - 地下城任務

    /// 建立 V2-1 地下城（樓層）任務。
    /// 驗證：樓層存在、玩家目前沒有進行中地下城任務。
    /// 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥。
    func createDungeonFloorTask(
        floorKey: String,
        durationSeconds: Int,
        heroStats: HeroStats,
        equippedSkillKeys: [String] = [],  // V6-1：已裝備技能 key
        cuisineKey: String = "",           // V7-4：攜帶的料理 ConsumableType rawValue
        potionKey:  String = ""            // V7-4：攜帶的藥水 ConsumableType rawValue
    ) throws {
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

        // V7-4：扣除消耗品（出發前立即扣）
        let consumable = fetchConsumableInventory()
        if !cuisineKey.isEmpty, let type = ConsumableType(rawValue: cuisineKey) {
            guard consumable?.use(of: type) == true else {
                throw TaskCreationError.insufficientConsumable(cuisineKey)
            }
        }
        if !potionKey.isEmpty, let type = ConsumableType(rawValue: potionKey) {
            guard consumable?.use(of: type) == true else {
                throw TaskCreationError.insufficientConsumable(potionKey)
            }
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
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        task.snapshotCuisineKey     = cuisineKey
        task.snapshotPotionKey      = potionKey
        repository.insert(task)
    }

    private func fetchConsumableInventory() -> ConsumableInventoryModel? {
        let descriptor = FetchDescriptor<ConsumableInventoryModel>()
        return (try? context.fetch(descriptor))?.first
    }

    /// 建立地下城任務（V1 路徑，以 DungeonAreaDef key 為 definitionKey）。
    /// 驗證：區域存在、玩家目前沒有進行中地下城任務。
    /// 首次出征（選 15 分鐘）：30 秒完成，固定 5 場戰鬥。
    func createDungeonTask(
        areaKey: String,
        durationSeconds: Int,
        heroStats: HeroStats,
        equippedSkillKeys: [String] = []  // V6-1：已裝備技能 key
    ) throws {
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

        // V6-1：技能改為主動觸發，snapshotPower 只含職業加成 + 裝備 + 屬性點
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
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        repository.insert(task)
    }
}
