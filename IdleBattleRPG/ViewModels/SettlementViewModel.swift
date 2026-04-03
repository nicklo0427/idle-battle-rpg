// SettlementViewModel.swift
// 結算 Sheet 的展示協調 ViewModel（最薄）
//
// 責任：
//   - 將 AppState.lastSettledCount + 當前 completed 任務的 result* 欄位
//     轉換成 SettlementSummary（純 UI 資料，不含任何計算邏輯）
//   - makeRewardLines() 只讀任務既有欄位，不做入帳、不做 RNG
//
// Phase 5 範圍：金幣 / 素材獎勵行顯示、裝備新增提示
// Phase 6+ 補充：地下城勝場 / 敗場統計
// V2-1 Ticket 02：全部 17 種素材（V1 + V2-1 區域素材）皆可在結算摘要顯示
//   - 使用 TaskModel.resultAmount(of:) 讀取所有素材欄位
//   - 迭代 MaterialType.allCases 顯示，新素材自動涵蓋，無需手動新增顯示行

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
    /// V1 + V2-1 全部 17 種素材皆透過 TaskModel.resultAmount(of:) 讀取，
    /// 並利用 MaterialType.allCases 迭代輸出，結構統一。
    private func makeRewardLines(from tasks: [TaskModel]) -> [String] {
        var goldTotal  = 0
        var materials  = [MaterialType: Int]()
        var craftCount = 0
        var totalWon   = 0
        var totalLost  = 0

        for task in tasks {
            goldTotal += task.resultGold

            // 統一使用 resultAmount(of:) 讀取所有 17 種素材
            for mat in MaterialType.allCases {
                let amount = task.resultAmount(of: mat)
                guard amount > 0 else { continue }
                materials[mat, default: 0] += amount
            }

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
}
