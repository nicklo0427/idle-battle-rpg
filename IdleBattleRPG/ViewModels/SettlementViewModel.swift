// SettlementViewModel.swift
// 結算 Sheet 的展示協調 ViewModel（最薄）
//
// 責任：
//   - 將 AppState.lastSettledCount + 當前 completed 任務的 result* 欄位
//     轉換成 SettlementSummary（純 UI 資料，不含任何計算邏輯）
//   - makeRows() 只讀任務既有欄位，不做入帳、不做 RNG
//
// Phase 5 範圍：金幣 / 素材獎勵行顯示、裝備新增提示
// Phase 6+ 補充：地下城勝場 / 敗場統計
// V2-1 Ticket 02：全部 17 種素材（V1 + V2-1 區域素材）皆可在結算摘要顯示
//   - 使用 TaskModel.resultAmount(of:) 讀取所有素材欄位
//   - 迭代 MaterialType.allCases 顯示，新素材自動涵蓋，無需手動新增顯示行
// V2-1 Ticket 07：首通解鎖提示
//   - SettlementRow.Kind.firstClear / .regionUnlock
// V2-4 Ticket 05：裝備屬性顯示
//   - SettlementRow.Kind.equipment(name:stats:isRolled:)
//   - Boss 武器顯示浮動 ATK + ✦ 標記

import Foundation

// MARK: - SettlementRow

struct SettlementRow: Identifiable {
    enum RowKind {
        case gold(Int)
        case exp(Int)
        case material(MaterialType, Int)
        case equipment(name: String, stats: String, isRolled: Bool)
        case battle(won: Int, lost: Int)
        case firstClear(floorName: String)
        case regionUnlock(regionName: String)
    }
    let id = UUID()
    let kind: RowKind
}

// MARK: - SettlementSummary（Value Type）

struct SettlementSummary {
    let completedCount: Int
    let rows: [SettlementRow]

    var displayTitle: String { "任務完成" }

    var displayBody: String {
        completedCount == 1
            ? "1 筆任務已完成"
            : "共 \(completedCount) 筆任務已完成"
    }

    var rewardRows: [SettlementRow] {
        rows.filter {
            switch $0.kind {
            case .gold, .exp, .material, .equipment, .battle: return true
            case .firstClear, .regionUnlock:                   return false
            }
        }
    }

    var unlockRows: [SettlementRow] {
        rows.filter {
            switch $0.kind {
            case .firstClear, .regionUnlock: return true
            default:                         return false
            }
        }
    }

    var hasRewards: Bool { !rewardRows.isEmpty }
    var hasUnlocks: Bool { !unlockRows.isEmpty }
}

// MARK: - SettlementViewModel

@Observable
final class SettlementViewModel {

    /// 從 AppState 筆數 + 已完成任務列表，組合成 SettlementSummary
    func makeSummary(from appState: AppState, completedTasks: [TaskModel]) -> SettlementSummary {
        SettlementSummary(
            completedCount: appState.lastSettledCount,
            rows:           makeRows(from: completedTasks)
        )
    }

    // MARK: - Private

    /// 從任務 result* 欄位組裝 SettlementRow 列表（不做計算，只做格式化）
    private func makeRows(from tasks: [TaskModel]) -> [SettlementRow] {
        var goldTotal  = 0
        var materials  = [MaterialType: Int]()
        var equipRows: [SettlementRow] = []
        var battleWon  = 0
        var battleLost = 0
        var unlockRows: [SettlementRow] = []

        for task in tasks {
            goldTotal += task.resultGold

            for mat in MaterialType.allCases {
                let amt = task.resultAmount(of: mat)
                guard amt > 0 else { continue }
                materials[mat, default: 0] += amt
            }

            // 裝備行：鑄造完成 or 地下城 Boss 武器掉落
            if let key = task.resultCraftedEquipKey,
               let def = EquipmentDef.find(key: key) {
                if task.kind == .dungeon {
                    // Boss 武器：使用已結算的浮動 ATK
                    let atk   = task.resultRolledAtk ?? def.atkBonus
                    equipRows.append(.init(kind: .equipment(
                        name: def.name,
                        stats: "ATK +\(atk)",
                        isRolled: true
                    )))
                } else {
                    // 鑄造任務：固定屬性
                    equipRows.append(.init(kind: .equipment(
                        name: def.name,
                        stats: statsString(def: def),
                        isRolled: false
                    )))
                }
            }

            if task.kind == .dungeon {
                battleWon  += task.resultBattlesWon  ?? 0
                battleLost += task.resultBattlesLost ?? 0
            }

            // 首通解鎖行
            if let floorKey = task.resultFirstClearedFloorKey,
               let floor    = DungeonFloorDef.find(key: floorKey),
               let equipDef = EquipmentDef.find(key: floor.unlocksEquipmentKey) {

                unlockRows.append(.init(kind: .firstClear(floorName: equipDef.name)))

                if floor.isBossFloor {
                    let allRegions = DungeonRegionDef.all
                    if let idx = allRegions.firstIndex(where: { $0.key == floor.regionKey }),
                       idx + 1 < allRegions.count {
                        unlockRows.append(.init(kind: .regionUnlock(
                            regionName: allRegions[idx + 1].name
                        )))
                    }
                }
            }
        }

        let expTotal = tasks.reduce(0) { $0 + $1.resultExp }

        var rows: [SettlementRow] = []
        if goldTotal > 0 { rows.append(.init(kind: .gold(goldTotal))) }
        if expTotal  > 0 { rows.append(.init(kind: .exp(expTotal))) }
        for mat in MaterialType.allCases {
            if let amt = materials[mat], amt > 0 {
                rows.append(.init(kind: .material(mat, amt)))
            }
        }
        rows.append(contentsOf: equipRows)
        if battleWon + battleLost > 0 {
            rows.append(.init(kind: .battle(won: battleWon, lost: battleLost)))
        }
        rows.append(contentsOf: unlockRows)
        return rows
    }

    // MARK: - Helpers

    private func statsString(def: EquipmentDef) -> String {
        var parts: [String] = []
        if def.atkBonus > 0 { parts.append("ATK +\(def.atkBonus)") }
        if def.defBonus > 0 { parts.append("DEF +\(def.defBonus)") }
        if def.hpBonus  > 0 { parts.append("HP +\(def.hpBonus)") }
        return parts.joined(separator: " / ")
    }
}
