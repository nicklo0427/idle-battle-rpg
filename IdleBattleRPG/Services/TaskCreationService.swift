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
    case onboardingBlocked

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
        case .onboardingBlocked:     return "請先完成目前的新手引導目標"
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

    private func assertNormalTaskAllowedDuringOnboarding() throws {
        let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first
        guard let player, player.onboardingStep < OnboardingService.completedStep else { return }
        throw TaskCreationError.onboardingBlocked
    }

    // MARK: - 採集任務

    /// 建立採集任務。
    /// 驗證：地點存在、該採集者目前沒有進行中任務。
    /// durationSeconds：玩家選擇的時長；需屬於 def.durationOptions 之一。
    func createGatherTask(actorKey: String, locationKey: String, durationSeconds: Int) throws {
        try assertNormalTaskAllowedDuringOnboarding()
        guard let def = GatherLocationDef.find(key: locationKey) else {
            throw TaskCreationError.locationNotFound(locationKey)
        }
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == actorKey && $0.kind == .gather }) {
            throw TaskCreationError.actorBusy(actorKey)
        }

        let maxDuration  = def.durationOptions.max() ?? def.shortestDuration
        let baseDuration = min(max(def.shortestDuration, durationSeconds), maxDuration)

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
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    // MARK: - 鑄造任務

    /// 建立鑄造任務。
    /// 驗證：配方存在、鑄造師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材，resultCraftedEquipKey 在建立時填入。
    func createCraftTask(recipeKey: String) throws {
        try createEquipmentCraftTask(recipeKey: recipeKey, actorKey: AppConstants.Actor.blacksmith)
    }

    /// 建立防具鑄造任務（皮甲師 actorKey）。
    /// 驗證：配方存在、皮甲師閒置、金幣足夠、素材足夠。
    func createArmorCraftTask(recipeKey: String) throws {
        try assertNormalTaskAllowedDuringOnboarding()
        guard let def = CraftRecipeDef.find(key: recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }

        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == AppConstants.Actor.armorer }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.armorer)
        }

        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }

        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for req in def.requiredMaterials {
            guard inventory.amount(of: req.material) >= req.amount else {
                throw TaskCreationError.insufficientMaterials
            }
        }

        player.gold -= def.goldCost
        for req in def.requiredMaterials {
            inventory.deduct(req.amount, of: req.material)
        }

        let now = Date.now
        let task = TaskModel(
            kind:                  .craft,
            actorKey:              AppConstants.Actor.armorer,
            definitionKey:         recipeKey,
            startedAt:             now,
            endsAt:                now.addingTimeInterval(TimeInterval(def.durationSeconds)),
            resultCraftedEquipKey: def.outputEquipmentKey
        )
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    // MARK: - 副手鑄造任務（V10-1 T12）

    func createOffhandCraftTask(recipeKey: String) throws {
        try createEquipmentCraftTask(recipeKey: recipeKey, actorKey: AppConstants.Actor.weaponsmith)
    }

    // MARK: - 飾品鑄造任務（V10-1 T13）

    func createAccessoryCraftTask(recipeKey: String) throws {
        try createEquipmentCraftTask(recipeKey: recipeKey, actorKey: AppConstants.Actor.jeweler)
    }

    // MARK: - 裁縫鑄造任務（V10-1 T14）

    func createTailorCraftTask(recipeKey: String) throws {
        try createEquipmentCraftTask(recipeKey: recipeKey, actorKey: AppConstants.Actor.tailor)
    }

    private func createEquipmentCraftTask(recipeKey: String, actorKey: String) throws {
        try assertNormalTaskAllowedDuringOnboarding()
        guard let def = CraftRecipeDef.find(key: recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }

        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == actorKey }) {
            throw TaskCreationError.actorBusy(actorKey)
        }

        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }

        let effectiveGold = effectiveCraftGoldCost(baseGold: def.goldCost, actorKey: actorKey, player: player)
        guard player.gold >= effectiveGold else { throw TaskCreationError.insufficientGold }
        for req in def.requiredMaterials {
            guard inventory.amount(of: req.material) >= req.amount else {
                throw TaskCreationError.insufficientMaterials
            }
        }

        player.gold -= effectiveGold
        for req in def.requiredMaterials {
            inventory.deduct(req.amount, of: req.material)
        }

        let duration = effectiveCraftDuration(baseDuration: def.durationSeconds, actorKey: actorKey, player: player)
        let now = Date.now
        let task = TaskModel(
            kind:                  .craft,
            actorKey:              actorKey,
            definitionKey:         recipeKey,
            startedAt:             now,
            endsAt:                now.addingTimeInterval(TimeInterval(duration)),
            resultCraftedEquipKey: def.outputEquipmentKey
        )
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    private func effectiveCraftGoldCost(baseGold: Int, actorKey: String, player: PlayerStateModel) -> Int {
        let goldNode = ProducerSkillNodeDef.nodes(for: actorKey)
            .first { $0.goldReductionPerPoint > 0 }
        let level = goldNode.map { player.skillLevel(nodeKey: $0.key, actorKey: actorKey) } ?? 0
        let discount = Double(level) * (goldNode?.goldReductionPerPoint ?? 0)
        return max(0, Int(Double(baseGold) * (1.0 - discount)))
    }

    private func effectiveCraftDuration(baseDuration: Int, actorKey: String, player: PlayerStateModel) -> Int {
        let tierMult = NpcUpgradeDef.craftDurationMultiplier(tier: player.tier(for: actorKey))
        let speedNode = ProducerSkillNodeDef.nodes(for: actorKey)
            .first { $0.speedReductionPerPoint > 0 }
        let speedLevel = speedNode.map { player.skillLevel(nodeKey: $0.key, actorKey: actorKey) } ?? 0
        let skillMult = 1.0 - Double(speedLevel) * (speedNode?.speedReductionPerPoint ?? 0)
        return max(30, Int(Double(baseDuration) * tierMult * skillMult))
    }

    // MARK: - 料理任務（V7-3）

    /// 建立料理任務。
    /// 驗證：配方存在、廚師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材，resultCuisineKey 在建立時填入。
    func createCuisineTask(recipeKey: String) throws {
        try assertNormalTaskAllowedDuringOnboarding()
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

        // 廚師 tier + 速度技能縮短烹飪時間
        let tierMult      = NpcUpgradeDef.craftDurationMultiplier(tier: player.chefTier)
        let chSpeedNode   = ProducerSkillNodeDef.nodes(for: AppConstants.Actor.chef)
            .first { $0.speedReductionPerPoint > 0 }
        let chSpeedLv     = chSpeedNode.map { player.skillLevel(nodeKey: $0.key, actorKey: AppConstants.Actor.chef) } ?? 0
        let chSkillMult   = 1.0 - Double(chSpeedLv) * (chSpeedNode?.speedReductionPerPoint ?? 0)
        let duration      = max(30, Int(Double(def.cookMinutes * 60) * tierMult * chSkillMult))

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
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    // MARK: - 農田任務（V7-4）

    /// 建立農田種植任務。
    /// 驗證：農田閒置、玩家持有該種子 ≥ rounds（1 輪 = 300 秒 = 1 顆種子）。
    /// 建立前立即扣除 rounds 顆種子（與鑄造扣素材邏輯相同）。
    func createFarmTask(plotKey: String, seedType: MaterialType, durationSeconds: Int) throws {
        try assertNormalTaskAllowedDuringOnboarding()
        let shortestRound = 300   // 5 分鐘 / 輪
        let rounds = max(1, durationSeconds / shortestRound)

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

        // 3. 驗證種子庫存 ≥ rounds
        guard inventory.amount(of: seedType) >= rounds else {
            throw TaskCreationError.insufficientMaterials
        }

        // 4. 扣除 rounds 顆種子
        inventory.deduct(rounds, of: seedType)

        // 4b. 套用農夫速度技能（fa_speed）縮短實際任務時長
        let playerDesc2 = FetchDescriptor<PlayerStateModel>()
        let farmerPlayer = (try? context.fetch(playerDesc2))?.first
        let speedNode    = ProducerSkillNodeDef.nodes(for: "farmer")
                              .first { $0.speedReductionPerPoint > 0 }
        let speedLv      = speedNode.map {
            farmerPlayer?.skillLevel(nodeKey: $0.key, actorKey: "farmer") ?? 0
        } ?? 0
        let skillMult    = 1.0 - Double(speedLv) * (speedNode?.speedReductionPerPoint ?? 0)
        let effectiveDuration = max(shortestRound, Int(Double(rounds * shortestRound) * skillMult))

        // 5. 建立任務（definitionKey = seedType.rawValue，供結算時判斷農作物種類）
        let now = Date.now
        let task = TaskModel(
            kind:          .farming,
            actorKey:      plotKey,
            definitionKey: seedType.rawValue,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(effectiveDuration))
        )
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    // MARK: - 煉藥任務（V7-4）

    /// 建立煉藥任務。
    /// 驗證：配方存在、製藥師閒置、金幣足夠、素材足夠。
    /// 建立前立即扣除金幣和素材。
    func createAlchemyTask(recipeKey: String) throws {
        try assertNormalTaskAllowedDuringOnboarding()
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

        // 製藥師 tier + 速度技能縮短釀製時間
        let phTierMult  = NpcUpgradeDef.craftDurationMultiplier(tier: player.pharmacistTier)
        let phSpeedNode = ProducerSkillNodeDef.nodes(for: AppConstants.Actor.pharmacist)
            .first { $0.speedReductionPerPoint > 0 }
        let phSpeedLv   = phSpeedNode.map { player.skillLevel(nodeKey: $0.key, actorKey: AppConstants.Actor.pharmacist) } ?? 0
        let phSkillMult = 1.0 - Double(phSpeedLv) * (phSpeedNode?.speedReductionPerPoint ?? 0)
        let duration    = max(30, Int(Double(def.brewMinutes * 60) * phTierMult * phSkillMult))

        let now = Date.now
        let task = TaskModel(
            kind:          .alchemy,
            actorKey:      AppConstants.Actor.pharmacist,
            definitionKey: def.key,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration))
        )
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
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
        try assertNormalTaskAllowedDuringOnboarding()
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

        let duration = durationSeconds
        let now = Date.now
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: floorKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            durationOverride: nil,
            forcedBattles:    nil,
            snapshotPower:    heroStats.power,
            snapshotAgi:      heroStats.totalAGI,
            snapshotDex:      heroStats.totalDEX
        )
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        task.snapshotCuisineKey     = cuisineKey
        task.snapshotPotionKey      = potionKey
        task.snapshotChFlavorLevel  = player.skillLevel(nodeKey: "ch_flavor",  actorKey: AppConstants.Actor.chef)
        task.snapshotPhPotencyLevel = player.skillLevel(nodeKey: "ph_potency", actorKey: AppConstants.Actor.pharmacist)
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    private func fetchConsumableInventory() -> ConsumableInventoryModel? {
        let descriptor = FetchDescriptor<ConsumableInventoryModel>()
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - 後續教程任務（V10）

    /// 教程地下城任務：使用真實 floorKey，但以 tutorialKey 辨識，短程完成且保證一場戰鬥。
    func createTutorialDungeonFloorTask(
        floorKey: String,
        heroStats: HeroStats,
        equippedSkillKeys: [String] = [],
        cuisineKey: String = "",
        potionKey: String = "",
        tutorialKey: String = OnboardingTutorialKey.firstDungeon
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

        let now = Date.now
        let duration = OnboardingService.combatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: floorKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   tutorialKey,
            forcedBattles: 1,
            snapshotPower: heroStats.power,
            snapshotAgi:   heroStats.totalAGI,
            snapshotDex:   heroStats.totalDEX
        )
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        task.snapshotCuisineKey     = cuisineKey
        task.snapshotPotionKey      = potionKey
        task.snapshotChFlavorLevel  = player.skillLevel(nodeKey: "ch_flavor",  actorKey: AppConstants.Actor.chef)
        task.snapshotPhPotencyLevel = player.skillLevel(nodeKey: "ph_potency", actorKey: AppConstants.Actor.pharmacist)

        if tutorialKey == OnboardingTutorialKey.firstDungeon, player.onboardingStep == 9 {
            player.onboardingStep = 10
        } else if tutorialKey == OnboardingTutorialKey.buffedRun, player.onboardingStep == 19 {
            player.onboardingStep = 20
        }

        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }

    /// 教程農田任務：種下小麥種子，使用真實 seed definitionKey，10 秒完成。
    func createTutorialFarmTask() throws {
        OnboardingService(context: context).prepareForCurrentStep()
        let plotKey = AppConstants.FarmerPlot.key(for: 0)
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == plotKey && $0.kind == .farming }) {
            throw TaskCreationError.actorBusy(plotKey)
        }
        guard let inventory = (try? context.fetch(FetchDescriptor<MaterialInventoryModel>()))?.first else {
            throw TaskCreationError.noInventory
        }
        guard inventory.deduct(1, of: .wheatSeed) else {
            throw TaskCreationError.insufficientMaterials
        }
        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .farming,
            actorKey:      plotKey,
            definitionKey: MaterialType.wheatSeed.rawValue,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   OnboardingTutorialKey.farmWheat
        )
        repository.insert(task)
    }

    /// 教程料理任務：製作魚肉燉鍋，補齊差額後照常扣素材 / 金幣，10 秒完成。
    func createTutorialCuisineTask() throws {
        OnboardingService(context: context).prepareForCurrentStep()
        try createTutorialCuisineLikeTask(
            recipeKey: "fish_stew",
            actorKey: AppConstants.Actor.chef,
            tutorialKey: OnboardingTutorialKey.fishStew
        )
    }

    /// 教程煉藥任務：製作小型藥水，補齊差額後照常扣素材 / 金幣，10 秒完成。
    func createTutorialAlchemyTask() throws {
        OnboardingService(context: context).prepareForCurrentStep()
        guard let def = PotionDef.find("small_potion") else {
            throw TaskCreationError.recipeNotFound("small_potion")
        }
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == AppConstants.Actor.pharmacist }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.pharmacist)
        }
        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }
        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for (mat, amount) in def.ingredients {
            guard inventory.amount(of: mat) >= amount else { throw TaskCreationError.insufficientMaterials }
        }
        player.gold -= def.goldCost
        for (mat, amount) in def.ingredients {
            inventory.deduct(amount, of: mat)
        }
        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .alchemy,
            actorKey:      AppConstants.Actor.pharmacist,
            definitionKey: def.key,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   OnboardingTutorialKey.smallPotion
        )
        repository.insert(task)
    }

    private func createTutorialCuisineLikeTask(recipeKey: String, actorKey: String, tutorialKey: String) throws {
        guard let def = CuisineDef.find(recipeKey) else {
            throw TaskCreationError.recipeNotFound(recipeKey)
        }
        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.actorKey == actorKey }) {
            throw TaskCreationError.actorBusy(actorKey)
        }
        let playerDesc    = FetchDescriptor<PlayerStateModel>()
        let inventoryDesc = FetchDescriptor<MaterialInventoryModel>()
        guard let player    = (try? context.fetch(playerDesc))?.first    else { throw TaskCreationError.noPlayerState }
        guard let inventory = (try? context.fetch(inventoryDesc))?.first else { throw TaskCreationError.noInventory }
        guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
        for (mat, amount) in def.ingredients {
            guard inventory.amount(of: mat) >= amount else { throw TaskCreationError.insufficientMaterials }
        }
        player.gold -= def.goldCost
        for (mat, amount) in def.ingredients {
            inventory.deduct(amount, of: mat)
        }
        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .cuisine,
            actorKey:      actorKey,
            definitionKey: def.key,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   tutorialKey
        )
        task.resultCuisineKey = def.key
        repository.insert(task)
    }

    // MARK: - 教程任務（T06）

    /// 教程採集任務：gatherer_1 採集 10 秒，直接給 6 木材，不扣素材，onboardingStep → 1
    func createTutorialGatherTask() throws {
        guard let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first else {
            throw TaskCreationError.noPlayerState
        }

        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .gather,
            actorKey:      AppConstants.Actor.gatherer1,
            definitionKey: OnboardingTutorialKey.gatherWood,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   OnboardingTutorialKey.gatherWood
        )
        player.onboardingStep = 1
        repository.insert(task)
    }

    /// 教程探索任務：使用真實樓層短程完成，保底一場戰鬥；教學獎勵於戰鬥完成後套用。
    func createTutorialExploreTask(
        floorKey: String,
        heroStats: HeroStats,
        equippedSkillKeys: [String] = []
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

        let now = Date.now
        let duration = OnboardingService.combatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: floorKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:   OnboardingTutorialKey.armorMaterials,
            forcedBattles: 1,
            snapshotPower: heroStats.power,
            snapshotAgi:   heroStats.totalAGI,
            snapshotDex:   heroStats.totalDEX
        )
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        repository.insert(task)
    }

    /// 教程防具鑄造任務：tailor 鑄造 10 秒，不扣素材/金幣，onboardingStep 由結算設為 8
    func createTutorialArmorTask() throws {
        guard (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first != nil else {
            throw TaskCreationError.noPlayerState
        }

        let inProgress = repository.fetchInProgress()
        if inProgress.contains(where: { $0.kind == .craft && $0.actorKey == AppConstants.Actor.tailor }) {
            throw TaskCreationError.actorBusy(AppConstants.Actor.tailor)
        }

        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:                  .craft,
            actorKey:              AppConstants.Actor.tailor,
            definitionKey:         OnboardingTutorialKey.starterArmor,
            startedAt:             now,
            endsAt:                now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:           OnboardingTutorialKey.starterArmor,
            resultCraftedEquipKey: "wildland_armor"
        )
        repository.insert(task)
    }

    /// 教程鑄造任務：blacksmith 鑄造 10 秒，不扣素材/金幣，onboardingStep 由結算推進
    func createTutorialCraftTask(for classDef: ClassDef) throws {
        guard let player = (try? context.fetch(FetchDescriptor<PlayerStateModel>()))?.first else {
            throw TaskCreationError.noPlayerState
        }

        let now = Date.now
        let duration = OnboardingService.nonCombatTutorialTaskDurationSeconds
        let task = TaskModel(
            kind:                 .craft,
            actorKey:             AppConstants.Actor.blacksmith,
            definitionKey:        OnboardingTutorialKey.starterWeapon,
            startedAt:            now,
            endsAt:               now.addingTimeInterval(TimeInterval(duration)),
            tutorialKey:          OnboardingTutorialKey.starterWeapon,
            resultCraftedEquipKey: classDef.starterEquipmentKeys.first
        )
        _ = player  // onboardingStep 由結算時設為 3
        repository.insert(task)
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
        try assertNormalTaskAllowedDuringOnboarding()
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

        // V6-1：技能改為主動觸發，snapshotPower 只含職業加成 + 裝備 + 屬性點
        let duration = durationSeconds
        let now = Date.now
        let task = TaskModel(
            kind:          .dungeon,
            actorKey:      AppConstants.Actor.player,
            definitionKey: areaKey,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(TimeInterval(duration)),
            durationOverride: nil,
            forcedBattles:    nil,
            snapshotPower:    heroStats.power,
            snapshotAgi:      heroStats.totalAGI,
            snapshotDex:      heroStats.totalDEX
        )
        task.snapshotSkillKeysRaw   = equippedSkillKeys.joined(separator: ",")
        task.snapshotSkillLevelsRaw = player.skillLevelsRaw
        repository.insert(task)
        NotificationService.requestPermissionIfNeeded()
        NotificationService.schedule(for: task)
    }
}
