// SettlementViewModel.swift
// 結算 Sheet 的展示協調 ViewModel（最薄）
//
// 責任：
//   - 將 AppState.lastSettledCount + 當前 completed 任務的 result* 欄位
//     轉換成 SettlementSummary（純 UI 資料，不含任何計算邏輯）
//   - makeRewardLines() 只讀任務既有欄位，不做入帳、不做 RNG
//
// Phase 5 範圍：金幣 / 素材獎勵行顯示、裝備新增提示
// Phase 6+ 補充：地下城勝場 / 敗場統計、裝備掉落明細

import Foundation

// MARK: - SettlementSummary（Value Type）

struct SettlementSummary {
    let completedCount: Int
    let rewardLines: [String]

    var displayTitle: String { "任務完成" }

    var displayBody: String {
        completedCount == 1
            ? "1 筆任務已完成"
            : "共 \(completedCount) 筆任務已完成"
    }

    var hasRewards: Bool { !rewardLines.isEmpty }
}

// MARK: - SettlementViewModel

@Observable
final class SettlementViewModel {

    /// 從 AppState 筆數 + 已完成任務列表，組合成 SettlementSummary
    func makeSummary(from appState: AppState, completedTasks: [TaskModel]) -> SettlementSummary {
        SettlementSummary(
            completedCount: appState.lastSettledCount,
            rewardLines:    makeRewardLines(from: completedTasks)
        )
    }

    // MARK: - Private

    /// 從任務 result* 欄位彙整成顯示行（不做計算，只做格式化）
    private func makeRewardLines(from tasks: [TaskModel]) -> [String] {
        var goldTotal    = 0
        var materials    = [MaterialType: Int]()
        var craftCount   = 0
        var totalWon     = 0
        var totalLost    = 0

        for task in tasks {
            goldTotal += task.resultGold

            accumulate(task.resultWood,            .wood,            into: &materials)
            accumulate(task.resultOre,             .ore,             into: &materials)
            accumulate(task.resultHide,            .hide,            into: &materials)
            accumulate(task.resultCrystalShard,    .crystalShard,    into: &materials)
            accumulate(task.resultAncientFragment, .ancientFragment, into: &materials)

            if task.kind == .craft && task.resultCraftedEquipKey != nil {
                craftCount += 1
            }
            if task.kind == .dungeon {
                totalWon  += task.resultBattlesWon  ?? 0
                totalLost += task.resultBattlesLost ?? 0
            }
        }

        var lines: [String] = []
        if goldTotal > 0 { lines.append("💰 金幣 +\(goldTotal)") }
        for mat in MaterialType.allCases {
            if let amt = materials[mat], amt > 0 {
                lines.append("\(mat.icon) \(mat.displayName) +\(amt)")
            }
        }
        if craftCount > 0 { lines.append("🗡 新裝備 ×\(craftCount)") }
        if totalWon + totalLost > 0 { lines.append("⚔️ 戰鬥 \(totalWon) 勝 \(totalLost) 敗") }

        return lines
    }

    private func accumulate(_ value: Int, _ type: MaterialType, into dict: inout [MaterialType: Int]) {
        guard value > 0 else { return }
        dict[type, default: 0] += value
    }
}
