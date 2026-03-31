// AppConstants.swift
// 所有遊戲固定數值的唯一來源
// 調整遊戲平衡時，只需修改這個檔案

import Foundation

enum AppConstants {

    // MARK: - Actor Keys（與 TaskModel.actorKey 對應）
    enum Actor {
        static let gatherer1  = "gatherer_1"
        static let gatherer2  = "gatherer_2"
        static let blacksmith = "blacksmith"
        static let player     = "player"
    }

    // MARK: - 初始狀態
    enum Initial {
        static let gold               = 100
        static let wood               = 6
        static let ore                = 4
        static let startingWeaponKey  = "rusty_sword"
    }

    // MARK: - 遊戲規則
    enum Game {
        static let maxOfflineSeconds      = 8 * 3600   // 8 小時離線上限
        static let secondsPerBattle       = 60          // 每場戰鬥 60 秒
        static let heroMaxLevel           = 10
        static let statPointsPerLevel     = 3
        static let firstBoostSeconds      = 30          // 新手特快時長（秒）
        static let forcedBattlesFirstRun  = 5           // 首次出征固定場數
    }

    // MARK: - 出征時長選項（秒）
    enum DungeonDuration {
        static let short:  Int = 15 * 60       // 15 分鐘
        static let medium: Int = 60 * 60       // 1 小時
        static let long:   Int = 8 * 3600      // 8 小時

        static let all: [Int] = [short, medium, long]

        static func displayName(for seconds: Int) -> String {
            switch seconds {
            case short:  return "15 分鐘"
            case medium: return "1 小時"
            case long:   return "8 小時"
            default:     return "\(seconds / 60) 分鐘"
            }
        }
    }

    // MARK: - 英雄升級費用（純金幣）
    enum UpgradeCost {
        /// 升到指定等級所需的金幣（level: 目標等級，從 2 開始）
        static func gold(toLevel level: Int) -> Int {
            return 100 * level   // 升 Lv.2 = 200，升 Lv.3 = 300，以此類推
        }
    }
}
