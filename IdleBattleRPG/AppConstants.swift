// AppConstants.swift
// 所有遊戲固定數值的唯一來源
// 調整遊戲平衡時，只需修改這個檔案

import Foundation

enum AppConstants {

    // MARK: - Actor Keys（與 TaskModel.actorKey 對應）
    enum Actor {
        static let gatherer1   = "gatherer_1"
        static let gatherer2   = "gatherer_2"
        static let blacksmith  = "blacksmith"
        static let player      = "player"
        static let chef        = "chef"         // V7-3 廚師 NPC
        static let pharmacist  = "pharmacist"   // V7-4 製藥師 NPC
    }

    // MARK: - 農夫農田 Keys（V7-4）
    enum FarmerPlot {
        /// 所有農田的 actorKey（索引 0-based）
        static let keys = ["farmer_plot_1", "farmer_plot_2", "farmer_plot_3", "farmer_plot_4"]
        /// 根據索引（0-based）取得 actorKey
        static func key(for index: Int) -> String { keys[index] }
        static let maxPlots = 4
    }

    // MARK: - 初始狀態
    enum Initial {
        static let gold               = 150
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
            switch seconds {
            case short:  return String(localized: "15 分鐘")
            case medium: return String(localized: "1 小時")
            case long:   return String(localized: "12 小時")
            default:
                let h = seconds / 3600
                let m = (seconds % 3600) / 60
                if h > 0 && m > 0 { return "\(h) 小時 \(m) 分鐘" }
                if h > 0           { return "\(h) 小時" }
                return "\(m) 分鐘"
            }
        }
    }

    // MARK: - 英雄升級所需 EXP
    enum ExpThreshold {
        private static let table: [Int: Int] = [
            // Lv.1 → 10（早期稍快，讓新手快得第一升）
            2: 80,   3: 160,  4: 280,  5: 420,
            6: 600,  7: 850,  8: 1100, 9: 1500, 10: 2000,
            // Lv.10 → 20（中後期大幅拉長，讓沉落王城成為長期目標）
            11: 2800,  12: 3600,  13: 4500,  14: 5500,  15: 6800,
            16: 8400,  17: 10200, 18: 12500, 19: 15500, 20: 19000
        ]
        /// 升至目標等級所需 EXP；超出範圍回傳 nil
        static func required(toLevel level: Int) -> Int? {
            table[level]
        }
    }
}
