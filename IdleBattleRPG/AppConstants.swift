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
        static let maxOfflineSeconds      = 12 * 3600  // 12 小時離線上限
        static let secondsPerBattle       = 60          // 每場戰鬥 60 秒
        static let heroMaxLevel           = 20
        static let statPointsPerLevel     = 3
        static let firstBoostSeconds      = 30          // 新手特快時長（秒）
        static let forcedBattlesFirstRun  = 5           // 首次出征固定場數
    }

    // MARK: - 出征時長選項（秒）
    enum DungeonDuration {
        static let short:  Int = 15 * 60        // 15 分鐘
        static let medium: Int = 60 * 60        // 1 小時
        static let long:   Int = 12 * 3600      // 12 小時

        static let all: [Int] = [short, medium, long]

        static func displayName(for seconds: Int) -> String {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            if h > 0 && m > 0 { return "\(h) 小時 \(m) 分鐘" }
            if h > 0           { return "\(h) 小時" }
            return "\(m) 分鐘"
        }
    }

    // MARK: - 英雄升級所需 EXP
    enum ExpThreshold {
        private static let table: [Int: Int] = [
            // Lv.1 → 10
            2: 100,  3: 200,  4: 300,  5: 450,
            6: 600,  7: 800,  8: 1000, 9: 1300, 10: 1600,
            // Lv.10 → 20
            11: 2000,  12: 2500,  13: 3100,  14: 3800,  15: 4600,
            16: 5600,  17: 6800,  18: 8200,  19: 9900,  20: 12000
        ]
        /// 升至目標等級所需 EXP；超出範圍回傳 nil
        static func required(toLevel level: Int) -> Int? {
            table[level]
        }
    }
}
