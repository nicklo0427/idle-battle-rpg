// DungeonSettlementEngine.swift
// 地下城確定性 RNG 結算引擎
//
// 責任：
//   純計算層，無副作用，不需要 ModelContext。
//   輸入  ─ TaskModel（含 snapshotPower、forcedBattles、startedAt、endsAt）
//           + DungeonAreaDef（含 recommendedPower、dropTable、goldPerBattleRange）
//   輸出  ─ DungeonSettlementResult（所有結果欄位）
//
// 規格對應（MVP_SPEC_FINAL.md §8）：
//   totalBattles = forcedBattles ?? max(1, Int(actualDuration / 60))
//   winRate      = clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (snapshotPower/recommendedPower − 1)))
//   勝場         → 全額 gold + 素材掉落（依 dropTable）
//   敗場         → floor(goldMin × 0.2) 安慰金幣，無素材
//   首次出征保底 → forcedBattles != nil && resultGold == 0 → resultGold = goldMin

import Foundation

// MARK: - 結算結果（Value Type）

struct DungeonSettlementResult {
    let gold:            Int
    let hide:            Int
    let crystalShard:    Int
    let ancientFragment: Int
    let battlesWon:      Int
    let battlesLost:     Int
}

// MARK: - 結算引擎

struct DungeonSettlementEngine {

    /// 主結算入口（純計算，無副作用，可單元測試）
    static func settle(task: TaskModel, area: DungeonAreaDef) -> DungeonSettlementResult {
        var rng = DeterministicRNG(task: task)

        // 1. 場次計算
        let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles   = task.forcedBattles ?? max(1, Int(actualDuration / 60))

        // 2. 勝率（使用出發時快照戰力，不用結算當下的當前戰力）
        let winRate = area.winRate(snapshotPower: task.snapshotPower ?? 0)

        // 3. 逐場結算
        var gold:            Int = 0
        var hide:            Int = 0
        var crystalShard:    Int = 0
        var ancientFragment: Int = 0
        var won:             Int = 0
        var lost:            Int = 0

        for _ in 0..<totalBattles {
            if rng.nextDouble() < winRate {
                // 勝場：全額 gold + 素材掉落
                won  += 1
                gold += rng.nextInt(in: area.goldPerBattleRange)

                for entry in area.dropTable {
                    if rng.nextDouble() < entry.dropRate {
                        let qty = rng.nextInt(in: entry.quantityRange)
                        switch entry.material {
                        case .hide:            hide            += qty
                        case .crystalShard:    crystalShard    += qty
                        case .ancientFragment: ancientFragment += qty
                        default:               break
                        }
                    }
                }
            } else {
                // 敗場：20% 安慰金幣，無素材
                lost += 1
                gold += Int(Double(area.goldPerBattleRange.lowerBound) * 0.2)
            }
        }

        // 4. 首次出征保底（forcedBattles != nil = 首次加速觸發）
        //    確保第一次結算至少有金幣入帳
        if task.forcedBattles != nil && gold == 0 {
            gold = area.goldPerBattleRange.lowerBound
        }

        return DungeonSettlementResult(
            gold:            gold,
            hide:            hide,
            crystalShard:    crystalShard,
            ancientFragment: ancientFragment,
            battlesWon:      won,
            battlesLost:     lost
        )
    }
}

// MARK: - DungeonAreaDef 勝率計算擴充

extension DungeonAreaDef {

    /// 根據快照戰力計算此區域的勝率
    /// 委派給 HeroStats.winRate(power:recommendedPower:)，公式集中在單一位置
    func winRate(snapshotPower: Int) -> Double {
        HeroStats.winRate(power: snapshotPower, recommendedPower: recommendedPower)
    }
}
