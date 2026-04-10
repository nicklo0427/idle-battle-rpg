// AchievementDef.swift
// V4-4 成就系統：靜態成就定義
// 靜態資料，不進 SwiftData
//
// 結構：
//   AchievementCondition — 觸發條件（純 enum，供 AchievementService 評估）
//   AchievementDef       — 單一成就定義（10 個）
//
// 條件評估資料來源：
//   .heroLevel      → PlayerStateModel.heroLevel
//   .battlesWon     → PlayerStateModel.totalBattlesWon
//   .goldEarned     → PlayerStateModel.totalGoldEarned
//   .itemsCrafted   → PlayerStateModel.totalItemsCrafted
//   .floorCleared   → DungeonProgressionService.isFloorCleared(regionKey:floorIndex:)

import Foundation

// MARK: - 成就觸發條件

enum AchievementCondition {
    /// 英雄達到指定等級
    case heroLevel(Int)
    /// 累計獲勝場數達標
    case battlesWon(Int)
    /// 累計獲得金幣達標
    case goldEarned(Int)
    /// 累計鑄造裝備件數達標
    case itemsCrafted(Int)
    /// 指定區域指定樓層首通
    case floorCleared(regionKey: String, floorIndex: Int)
}

// MARK: - 成就定義

struct AchievementDef: Identifiable {
    var id: String { key }
    let key:         String                // 唯一識別（持久化用）
    let title:       String                // 短標題（e.g. "百戰老兵"）
    let description: String                // 觸發說明（e.g. "累計獲勝 100 場戰鬥"）
    let icon:        String                // emoji 圖示
    let condition:   AchievementCondition  // 觸發條件
}

// MARK: - 靜態資料

extension AchievementDef {

    static let all: [AchievementDef] = [

        // ── 戰鬥 ─────────────────────────────────────────────────────

        AchievementDef(
            key:         "first_blood",
            title:       "第一滴血",
            description: "贏得第一場地下城戰鬥",
            icon:        "⚔️",
            condition:   .battlesWon(1)
        ),
        AchievementDef(
            key:         "veteran_warrior",
            title:       "百戰老兵",
            description: "累計獲勝 100 場戰鬥",
            icon:        "🛡️",
            condition:   .battlesWon(100)
        ),

        // ── 鑄造 ─────────────────────────────────────────────────────

        AchievementDef(
            key:         "first_craft",
            title:       "鑄造起步",
            description: "完成第一件裝備鑄造",
            icon:        "🔨",
            condition:   .itemsCrafted(1)
        ),
        AchievementDef(
            key:         "equipment_master",
            title:       "裝備大師",
            description: "累計鑄造 15 件裝備",
            icon:        "⚒️",
            condition:   .itemsCrafted(15)
        ),

        // ── 財富 ─────────────────────────────────────────────────────

        AchievementDef(
            key:         "gold_tycoon",
            title:       "黃金富豪",
            description: "累計獲得 50,000 金幣",
            icon:        "💰",
            condition:   .goldEarned(50000)
        ),

        // ── 地下城推進 ────────────────────────────────────────────────

        AchievementDef(
            key:         "wildland_conqueror",
            title:       "荒野征服者",
            description: "首通荒野邊境 Boss 層",
            icon:        "🌾",
            condition:   .floorCleared(regionKey: "wildland", floorIndex: 4)
        ),
        AchievementDef(
            key:         "mine_explorer",
            title:       "礦坑探索家",
            description: "首通廢棄礦坑 Boss 層",
            icon:        "⛏️",
            condition:   .floorCleared(regionKey: "abandoned_mine", floorIndex: 4)
        ),
        AchievementDef(
            key:         "ruins_guardian",
            title:       "遺跡守誓者",
            description: "首通古代遺跡 Boss 層",
            icon:        "🏛️",
            condition:   .floorCleared(regionKey: "ancient_ruins", floorIndex: 4)
        ),
        AchievementDef(
            key:         "abyss_conqueror",
            title:       "深淵征服者",
            description: "首通沉落王城 Boss 層",
            icon:        "🌊",
            condition:   .floorCleared(regionKey: "sunken_city", floorIndex: 4)
        ),

        // ── 英雄成長 ──────────────────────────────────────────────────

        AchievementDef(
            key:         "legend_hero",
            title:       "傳奇英雄",
            description: "英雄升至最高等級 Lv.20",
            icon:        "🌟",
            condition:   .heroLevel(20)
        ),
    ]

    static func find(key: String) -> AchievementDef? {
        all.first { $0.key == key }
    }
}
