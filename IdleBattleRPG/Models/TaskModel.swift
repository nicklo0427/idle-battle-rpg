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
    /// 對應靜態資料的 key（採集地點 / 配方 / 地下城區域）
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

    // MARK: - 結果欄位（inProgress 時全為 0 / nil，completed 後填入）

    var resultGold: Int
    var resultWood: Int
    var resultOre: Int
    var resultHide: Int
    var resultCrystalShard: Int
    var resultAncientFragment: Int

    /// .dungeon 專用
    var resultBattlesWon: Int?
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
        durationOverride: Int? = nil,
        forcedBattles: Int? = nil,
        snapshotPower: Int? = nil,
        status: TaskStatus = .inProgress,
        resultGold: Int = 0,
        resultWood: Int = 0,
        resultOre: Int = 0,
        resultHide: Int = 0,
        resultCrystalShard: Int = 0,
        resultAncientFragment: Int = 0,
        resultBattlesWon: Int? = nil,
        resultBattlesLost: Int? = nil,
        resultCraftedEquipKey: String? = nil
    ) {
        self.id                   = id
        self.kind                 = kind
        self.actorKey             = actorKey
        self.definitionKey        = definitionKey
        self.startedAt            = startedAt
        self.endsAt               = endsAt
        self.durationOverride     = durationOverride
        self.forcedBattles        = forcedBattles
        self.snapshotPower        = snapshotPower
        self.status               = status
        self.resultGold           = resultGold
        self.resultWood           = resultWood
        self.resultOre            = resultOre
        self.resultHide           = resultHide
        self.resultCrystalShard   = resultCrystalShard
        self.resultAncientFragment = resultAncientFragment
        self.resultBattlesWon     = resultBattlesWon
        self.resultBattlesLost    = resultBattlesLost
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
}
