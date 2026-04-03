// DungeonSettlementEngine.swift
// 地下城確定性 RNG 結算引擎
//
// 責任：
//   純計算層，無副作用，不需要 ModelContext。
//
// V1 路徑：settle(task:area:) → DungeonSettlementResult（硬編碼 V1 素材欄位）
//   輸入：TaskModel + DungeonAreaDef
//   輸出：gold / hide / crystalShard / ancientFragment / battlesWon / battlesLost
//
// V2-1 路徑：settle(task:floor:) → FloorDungeonResult（泛型素材字典）
//   輸入：TaskModel + DungeonFloorDef
//   輸出：gold / materials:[MaterialType:Int] / battlesWon / battlesLost
//   說明：drop table 中任意 MaterialType 皆可掉落，支援全部 17 種素材
//
// 規格對應（MVP_SPEC_FINAL.md §8）：
//   totalBattles = forcedBattles ?? max(1, Int(actualDuration / 60))
//   winRate      = clamp(0.10, 0.95, 0.50 + 0.40 × tanh(2 × (snapshotPower/recommendedPower − 1)))
//   勝場         → 全額 gold + 素材掉落（依 dropTable）
//   敗場         → floor(goldMin × 0.2) 安慰金幣，無素材
//   首次出征保底 → forcedBattles != nil && resultGold == 0 → resultGold = goldMin

import Foundation

// MARK: - V1 結算結果（維持既有欄位，不破壞現有路徑）

struct DungeonSettlementResult {
    let gold:            Int
    let hide:            Int
    let crystalShard:    Int
    let ancientFragment: Int
    let battlesWon:      Int
    let battlesLost:     Int
}

// MARK: - V2-1 結算結果（泛型素材字典）

struct FloorDungeonResult {
    let gold:       Int
    let materials:  [MaterialType: Int]   // 掉落的所有區域素材
    let battlesWon:  Int
    let battlesLost: Int
}

// MARK: - 結算引擎

struct DungeonSettlementEngine {

    // MARK: - V1 結算入口（維持不變，供既有 V1 DungeonAreaDef 任務使用）

    /// V1 主結算入口（純計算，無副作用，可單元測試）
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
                lost += 1
                gold += Int(Double(area.goldPerBattleRange.lowerBound) * 0.2)
            }
        }

        // 4. 首次出征保底
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

    // MARK: - V2-1 結算入口（樓層結構，泛型素材字典）

    /// V2-1 樓層結算（純計算，無副作用，可單元測試）
    /// drop table 可包含任意 MaterialType，結果以字典回傳
    static func settle(task: TaskModel, floor: DungeonFloorDef) -> FloorDungeonResult {
        var rng = DeterministicRNG(task: task)

        // 1. 場次計算（同 V1 規則）
        let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles   = task.forcedBattles ?? max(1, Int(actualDuration / 60))

        // 2. 勝率（使用 floor.recommendedPower）
        let winRate = HeroStats.winRate(
            power:            task.snapshotPower ?? 0,
            recommendedPower: floor.recommendedPower
        )

        // 3. 逐場結算
        var gold:      Int = 0
        var materials: [MaterialType: Int] = [:]
        var won:       Int = 0
        var lost:      Int = 0

        for _ in 0..<totalBattles {
            if rng.nextDouble() < winRate {
                won  += 1
                gold += rng.nextInt(in: floor.goldPerBattleRange)

                for entry in floor.dropTable {
                    if rng.nextDouble() < entry.dropRate {
                        let qty = rng.nextInt(in: entry.quantityRange)
                        materials[entry.material, default: 0] += qty
                    }
                }
            } else {
                lost += 1
                gold += Int(Double(floor.goldPerBattleRange.lowerBound) * 0.2)
            }
        }

        // 4. 首次出征保底（同 V1 邏輯）
        if task.forcedBattles != nil && gold == 0 {
            gold = floor.goldPerBattleRange.lowerBound
        }

        return FloorDungeonResult(
            gold:        gold,
            materials:   materials,
            battlesWon:  won,
            battlesLost: lost
        )
    }
}

// MARK: - DungeonAreaDef 勝率計算擴充（V1）

extension DungeonAreaDef {

    /// 根據快照戰力計算此區域的勝率
    func winRate(snapshotPower: Int) -> Double {
        HeroStats.winRate(power: snapshotPower, recommendedPower: recommendedPower)
    }
}
