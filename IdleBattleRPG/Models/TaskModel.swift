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

    // MARK: - 結果欄位：特殊

    /// .dungeon 專用
    var resultBattlesWon:  Int?
    var resultBattlesLost: Int?

    /// .craft 專用（建立任務時就填入，不需 RNG）
    var resultCraftedEquipKey: String?

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
        // 特殊
        resultBattlesWon:      Int?    = nil,
        resultBattlesLost:     Int?    = nil,
        resultCraftedEquipKey: String? = nil
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

        self.resultBattlesWon      = resultBattlesWon
        self.resultBattlesLost     = resultBattlesLost
        self.resultCraftedEquipKey = resultCraftedEquipKey
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
        }
    }
}
