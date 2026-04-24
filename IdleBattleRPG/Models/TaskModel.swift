// TaskModel.swift
// 統一任務模型（採集 / 鑄造 / 冒險 共用）
// 玩家點「收下」後直接刪除，不保留歷史紀錄

import Foundation
import SwiftData

// MARK: - 任務類型

enum TaskKind: String, Codable {
    case gather  = "gather"
    case craft   = "craft"
    case dungeon = "dungeon"
    case cuisine = "cuisine"    // V7-3 廚師 NPC
    case farming = "farming"    // V7-4 農夫 NPC（多塊農田）
    case alchemy = "alchemy"    // V7-4 製藥師 NPC
}

// MARK: - 任務狀態

enum TaskStatus: String, Codable {
    case inProgress = "in_progress"
    case completed  = "completed"
    // 無 .settled：玩家收下後直接刪除 TaskModel
}

// MARK: - TaskModel

@Model
final class TaskModel {

    // MARK: - 基本識別

    var id: UUID
    var kind: TaskKind
    /// "gatherer_1" / "gatherer_2" / "blacksmith" / "player"
    var actorKey: String
    /// 對應靜態資料的 key（採集地點 / 配方 / 地下城區域或樓層）
    var definitionKey: String

    // MARK: - 時間

    var startedAt: Date
    var endsAt: Date
    /// 新手特快覆蓋秒數，nil = 正常時長
    var durationOverride: Int?

    // MARK: - 特殊控制

    /// 首次出征：固定場次（nil = 按時間計算）
    var forcedBattles: Int?
    /// .dungeon 專用：出發當下的英雄戰力快照（結算時用此值，不用當前戰力）
    var snapshotPower: Int?
    /// .dungeon 專用：出發當下的英雄 AGI 快照（ATB 填充速度，nil = 舊任務向後相容）
    var snapshotAgi: Int?
    /// .dungeon 專用：出發當下的英雄 DEX 快照（暴擊率，nil = 舊任務向後相容）
    var snapshotDex: Int?

    // MARK: - 狀態

    var status: TaskStatus

    // MARK: - 結果欄位：V1 通用（inProgress 時全為 0 / nil，completed 後填入）

    var resultGold:            Int
    var resultWood:            Int
    var resultOre:             Int
    var resultHide:            Int
    var resultCrystalShard:    Int
    var resultAncientFragment: Int

    // MARK: - 結果欄位：V2-1 荒野邊境素材

    var resultOldPostBadge:       Int   // 舊哨徽片
    var resultDriedHideBundle:    Int   // 風乾獸皮束
    var resultSplitHornBone:      Int   // 裂角繫骨
    var resultRiftFangRoyalBadge: Int   // 裂牙王徽

    // MARK: - 結果欄位：V2-1 廢棄礦坑素材

    var resultMineLampCopperClip: Int   // 礦燈銅扣
    var resultTunnelIronClip:     Int   // 坑道鐵扣
    var resultVeinStoneSlab:      Int   // 脈石承片
    var resultStoneSwallowCore:   Int   // 吞岩甲核

    // MARK: - 結果欄位：V2-1 古代遺跡素材

    var resultRelicSealRing:        Int   // 殘印石環
    var resultOathInscriptionShard: Int   // 誓紋碑片
    var resultForeShrineClip:       Int   // 前殿儀扣
    var resultAncientKingCore:      Int   // 古王儀核

    // MARK: - 結果欄位：V4-3 沉落王城素材

    var resultSunkenRuneShard:      Int   // 沉紋碎片
    var resultAbyssalCrystalDrop:   Int   // 深淵晶滴
    var resultDrownedCrownFragment: Int   // 溺冕殘片
    var resultSunkenKingSeal:       Int   // 沉王印璽

    // MARK: - 結果欄位：V7-1 採集專屬素材

    var resultAncientWood: Int = 0
    var resultRefinedOre:  Int = 0
    var resultHerb:        Int = 0
    var resultSpiritHerb:  Int = 0
    var resultFreshFish:   Int = 0
    var resultAbyssFish:   Int = 0

    // MARK: - 結果欄位：V7-4 農作物（4 種 × 3 品質；種子為輸入消耗，無結果欄位）

    var resultWheat:            Int = 0
    var resultWheatHigh:        Int = 0
    var resultWheatTop:         Int = 0
    var resultVegetable:        Int = 0
    var resultVegetableHigh:    Int = 0
    var resultVegetableTop:     Int = 0
    var resultFruit:            Int = 0
    var resultFruitHigh:        Int = 0
    var resultFruitTop:         Int = 0
    var resultSpiritGrain:      Int = 0
    var resultSpiritGrainHigh:  Int = 0
    var resultSpiritGrainTop:   Int = 0

    // MARK: - 結果欄位：特殊

    /// .dungeon 專用
    var resultBattlesWon:  Int?
    var resultBattlesLost: Int?

    /// .craft 專用（建立任務時就填入，不需 RNG）；
    /// .dungeon Boss 層也會寫入（Boss 武器掉落 key）
    var resultCraftedEquipKey: String?

    /// V2-1 Boss 武器浮動 ATK（結算時 RNG 決定）；nil = 非 Boss 武器掉落
    var resultRolledAtk: Int?

    /// .dungeon 專用（V2-1）：本次任務發生首通時，記錄該樓層 key（用於結算 Sheet 顯示解鎖提示）
    /// nil = 非首通 / V1 任務 / 尚未結算
    var resultFirstClearedFloorKey: String?

    /// .dungeon 專用：結算後獲得的 EXP（.gather / .craft 恆為 0）
    var resultExp: Int = 0

    // MARK: - 技能快照（V6-1）

    /// .dungeon 專用：出發時裝備的技能 key 快照，逗號分隔（空字串 = 無技能）
    var snapshotSkillKeysRaw: String = ""

    // MARK: - 技能升階快照（V6-2 T09）

    /// .dungeon 專用：出發時技能升階等級快照，格式 "key:level,key:level"
    var snapshotSkillLevelsRaw: String = ""

    // MARK: - 即時戰鬥標記（V6-3 T01）

    /// .dungeon 專用：任務到期後戰鬥尚未發起時為 true
    /// 戰鬥完成後由 DungeonBattleSheet 重設為 false
    var battlePending: Bool = false

    // MARK: - 採集隨機事件（V7-1 T03）

    /// .gather 專用：nil = 無事件 / "bumper_harvest" / "rare_find" / "gold_vein"
    var gatherEventKey: String? = nil

    // MARK: - 料理任務（V7-3）

    /// .cuisine 專用：建立任務時就填入的料理 key（對應 CuisineDef.key）
    var resultCuisineKey: String = ""

    // MARK: - 出征消耗品快照（V7-4 T05）

    /// .dungeon 專用：攜帶的料理 ConsumableType rawValue（空字串 = 未攜帶）
    var snapshotCuisineKey: String = ""
    /// .dungeon 專用：攜帶的藥水 ConsumableType rawValue（空字串 = 未攜帶）
    var snapshotPotionKey:  String = ""

    // MARK: - Init

    init(
        id: UUID = UUID(),
        kind: TaskKind,
        actorKey: String,
        definitionKey: String,
        startedAt: Date,
        endsAt: Date,
        durationOverride: Int?  = nil,
        forcedBattles:    Int?  = nil,
        snapshotPower:    Int?  = nil,
        snapshotAgi:      Int?  = nil,
        snapshotDex:      Int?  = nil,
        status: TaskStatus = .inProgress,
        // V1 結果
        resultGold:            Int = 0,
        resultWood:            Int = 0,
        resultOre:             Int = 0,
        resultHide:            Int = 0,
        resultCrystalShard:    Int = 0,
        resultAncientFragment: Int = 0,
        // V2-1 荒野邊境
        resultOldPostBadge:       Int = 0,
        resultDriedHideBundle:    Int = 0,
        resultSplitHornBone:      Int = 0,
        resultRiftFangRoyalBadge: Int = 0,
        // V2-1 廢棄礦坑
        resultMineLampCopperClip: Int = 0,
        resultTunnelIronClip:     Int = 0,
        resultVeinStoneSlab:      Int = 0,
        resultStoneSwallowCore:   Int = 0,
        // V2-1 古代遺跡
        resultRelicSealRing:        Int = 0,
        resultOathInscriptionShard: Int = 0,
        resultForeShrineClip:       Int = 0,
        resultAncientKingCore:      Int = 0,
        // V4-3 沉落王城
        resultSunkenRuneShard:      Int = 0,
        resultAbyssalCrystalDrop:   Int = 0,
        resultDrownedCrownFragment: Int = 0,
        resultSunkenKingSeal:       Int = 0,
        // 特殊
        resultBattlesWon:           Int?    = nil,
        resultBattlesLost:          Int?    = nil,
        resultCraftedEquipKey:      String? = nil,
        resultRolledAtk:            Int?    = nil,
        resultFirstClearedFloorKey: String? = nil
    ) {
        self.id               = id
        self.kind             = kind
        self.actorKey         = actorKey
        self.definitionKey    = definitionKey
        self.startedAt        = startedAt
        self.endsAt           = endsAt
        self.durationOverride = durationOverride
        self.forcedBattles    = forcedBattles
        self.snapshotPower    = snapshotPower
        self.snapshotAgi      = snapshotAgi
        self.snapshotDex      = snapshotDex
        self.status           = status

        self.resultGold            = resultGold
        self.resultWood            = resultWood
        self.resultOre             = resultOre
        self.resultHide            = resultHide
        self.resultCrystalShard    = resultCrystalShard
        self.resultAncientFragment = resultAncientFragment

        self.resultOldPostBadge       = resultOldPostBadge
        self.resultDriedHideBundle    = resultDriedHideBundle
        self.resultSplitHornBone      = resultSplitHornBone
        self.resultRiftFangRoyalBadge = resultRiftFangRoyalBadge

        self.resultMineLampCopperClip = resultMineLampCopperClip
        self.resultTunnelIronClip     = resultTunnelIronClip
        self.resultVeinStoneSlab      = resultVeinStoneSlab
        self.resultStoneSwallowCore   = resultStoneSwallowCore

        self.resultRelicSealRing        = resultRelicSealRing
        self.resultOathInscriptionShard = resultOathInscriptionShard
        self.resultForeShrineClip       = resultForeShrineClip
        self.resultAncientKingCore      = resultAncientKingCore

        self.resultSunkenRuneShard      = resultSunkenRuneShard
        self.resultAbyssalCrystalDrop   = resultAbyssalCrystalDrop
        self.resultDrownedCrownFragment = resultDrownedCrownFragment
        self.resultSunkenKingSeal       = resultSunkenKingSeal

        self.resultBattlesWon           = resultBattlesWon
        self.resultBattlesLost          = resultBattlesLost
        self.resultCraftedEquipKey      = resultCraftedEquipKey
        self.resultRolledAtk            = resultRolledAtk
        self.resultFirstClearedFloorKey = resultFirstClearedFloorKey
    }

    // MARK: - 便利計算屬性

    var isCompleted: Bool { status == .completed }

    /// 剩餘秒數（負數代表已超時）
    var remainingSeconds: TimeInterval {
        endsAt.timeIntervalSinceNow
    }

    var isOverdue: Bool {
        remainingSeconds <= 0
    }

    // MARK: - V2-1 區域素材便利存取

    /// 依 MaterialType 讀取對應 result 欄位（供 SettlementService / TaskClaimService 使用）
    func resultAmount(of material: MaterialType) -> Int {
        switch material {
        case .wood:            return resultWood
        case .ore:             return resultOre
        case .hide:            return resultHide
        case .crystalShard:    return resultCrystalShard
        case .ancientFragment: return resultAncientFragment
        case .oldPostBadge:       return resultOldPostBadge
        case .driedHideBundle:    return resultDriedHideBundle
        case .splitHornBone:      return resultSplitHornBone
        case .riftFangRoyalBadge: return resultRiftFangRoyalBadge
        case .mineLampCopperClip: return resultMineLampCopperClip
        case .tunnelIronClip:     return resultTunnelIronClip
        case .veinStoneSlab:      return resultVeinStoneSlab
        case .stoneSwallowCore:   return resultStoneSwallowCore
        case .relicSealRing:        return resultRelicSealRing
        case .oathInscriptionShard: return resultOathInscriptionShard
        case .foreShrineClip:       return resultForeShrineClip
        case .ancientKingCore:      return resultAncientKingCore
        case .sunkenRuneShard:      return resultSunkenRuneShard
        case .abyssalCrystalDrop:   return resultAbyssalCrystalDrop
        case .drownedCrownFragment: return resultDrownedCrownFragment
        case .sunkenKingSeal:       return resultSunkenKingSeal
        // V7-1
        case .ancientWood:  return resultAncientWood
        case .refinedOre:   return resultRefinedOre
        case .herb:         return resultHerb
        case .spiritHerb:   return resultSpiritHerb
        case .freshFish:    return resultFreshFish
        case .abyssFish:    return resultAbyssFish
        // V7-4 種子（作為輸入消耗，無結果欄位）
        case .wheatSeed, .vegetableSeed, .fruitSeed, .spiritGrainSeed:
            return 0
        // V7-4 農作物
        case .wheat:           return resultWheat
        case .wheatHigh:       return resultWheatHigh
        case .wheatTop:        return resultWheatTop
        case .vegetable:       return resultVegetable
        case .vegetableHigh:   return resultVegetableHigh
        case .vegetableTop:    return resultVegetableTop
        case .fruit:           return resultFruit
        case .fruitHigh:       return resultFruitHigh
        case .fruitTop:        return resultFruitTop
        case .spiritGrain:     return resultSpiritGrain
        case .spiritGrainHigh: return resultSpiritGrainHigh
        case .spiritGrainTop:  return resultSpiritGrainTop
        }
    }

    /// 依 MaterialType 寫入對應 result 欄位（供 SettlementService 使用）
    func setResult(_ amount: Int, of material: MaterialType) {
        switch material {
        case .wood:            resultWood            = amount
        case .ore:             resultOre             = amount
        case .hide:            resultHide            = amount
        case .crystalShard:    resultCrystalShard    = amount
        case .ancientFragment: resultAncientFragment = amount
        case .oldPostBadge:       resultOldPostBadge       = amount
        case .driedHideBundle:    resultDriedHideBundle    = amount
        case .splitHornBone:      resultSplitHornBone      = amount
        case .riftFangRoyalBadge: resultRiftFangRoyalBadge = amount
        case .mineLampCopperClip: resultMineLampCopperClip = amount
        case .tunnelIronClip:     resultTunnelIronClip     = amount
        case .veinStoneSlab:      resultVeinStoneSlab      = amount
        case .stoneSwallowCore:   resultStoneSwallowCore   = amount
        case .relicSealRing:        resultRelicSealRing        = amount
        case .oathInscriptionShard: resultOathInscriptionShard = amount
        case .foreShrineClip:       resultForeShrineClip       = amount
        case .ancientKingCore:      resultAncientKingCore      = amount
        case .sunkenRuneShard:      resultSunkenRuneShard      = amount
        case .abyssalCrystalDrop:   resultAbyssalCrystalDrop   = amount
        case .drownedCrownFragment: resultDrownedCrownFragment = amount
        case .sunkenKingSeal:       resultSunkenKingSeal       = amount
        // V7-1
        case .ancientWood:  resultAncientWood = amount
        case .refinedOre:   resultRefinedOre  = amount
        case .herb:         resultHerb        = amount
        case .spiritHerb:   resultSpiritHerb  = amount
        case .freshFish:    resultFreshFish   = amount
        case .abyssFish:    resultAbyssFish   = amount
        // V7-4 種子（作為輸入消耗，無結果欄位，忽略寫入）
        case .wheatSeed, .vegetableSeed, .fruitSeed, .spiritGrainSeed:
            break
        // V7-4 農作物
        case .wheat:           resultWheat           = amount
        case .wheatHigh:       resultWheatHigh       = amount
        case .wheatTop:        resultWheatTop        = amount
        case .vegetable:       resultVegetable       = amount
        case .vegetableHigh:   resultVegetableHigh   = amount
        case .vegetableTop:    resultVegetableTop    = amount
        case .fruit:           resultFruit           = amount
        case .fruitHigh:       resultFruitHigh       = amount
        case .fruitTop:        resultFruitTop        = amount
        case .spiritGrain:     resultSpiritGrain     = amount
        case .spiritGrainHigh: resultSpiritGrainHigh = amount
        case .spiritGrainTop:  resultSpiritGrainTop  = amount
        }
    }
}

// MARK: - 技能快照便利存取（V6-1）

extension TaskModel {

    /// 出發時裝備的技能 key 陣列（由 snapshotSkillKeysRaw 解析）
    var snapshotSkillKeys: [String] {
        get {
            snapshotSkillKeysRaw
                .split(separator: ",")
                .compactMap { s in s.isEmpty ? nil : String(s) }
        }
        set {
            snapshotSkillKeysRaw = newValue.joined(separator: ",")
        }
    }

    /// 出發時技能升階等級快照字典（key: skillKey, value: 升階次數）
    var snapshotSkillLevels: [String: Int] {
        Dictionary(uniqueKeysWithValues:
            snapshotSkillLevelsRaw
                .split(separator: ",")
                .compactMap { pair -> (String, Int)? in
                    let parts = pair.split(separator: ":")
                    guard parts.count == 2, let lv = Int(parts[1]) else { return nil }
                    return (String(parts[0]), lv)
                }
        )
    }
}
