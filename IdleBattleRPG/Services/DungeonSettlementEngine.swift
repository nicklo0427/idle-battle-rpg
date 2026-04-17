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
//   輸出：gold / materials:[MaterialType:Int] / battlesWon / battlesLost / rolledBossWeapon
//   說明：drop table 中任意 MaterialType 皆可掉落，支援全部 17 種素材
//         Boss 層 + battlesWon >= 1 時額外產出浮動 ATK 武器掉落
//
// T10：改用完整戰鬥模擬（方案 B）
//   combatRng seed = taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42（"COMB"）
//   與 BattleLogGenerator 使用相同 combatRng → 勝負完全一致
//   金幣 / 素材由 settlementRng（DeterministicRNG(task:)）決定（維持原有隨機性）

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
    let exp:         Int
    /// Boss 武器掉落（isBossFloor && battlesWon >= 1 時有值）
    let rolledBossWeapon: (equipKey: String, atk: Int)?
}

// MARK: - 結算引擎

struct DungeonSettlementEngine {

    // MARK: - V1 結算入口（維持不變，供既有 V1 DungeonAreaDef 任務使用）

    /// V1 主結算入口（純計算，無副作用，可單元測試）
    static func settle(task: TaskModel, area: DungeonAreaDef) -> DungeonSettlementResult {

        // 1. 場次計算
        let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles   = task.forcedBattles ?? max(1, Int(actualDuration / 60))

        // 2. 英雄戰鬥數值（與 BattleLogGenerator 相同公式）
        let snapshotPower = task.snapshotPower ?? 50
        let snapshotAgi   = task.snapshotAgi   ?? 0
        let snapshotDex   = task.snapshotDex   ?? 0

        let heroMaxHp      = max(50, snapshotPower * 2)
        let heroAtk        = max(10, snapshotPower / 4)
        let heroDef        = max(5,  snapshotPower / 10)
        let heroChargeTime = max(0.6, 1.8 - Double(snapshotAgi) * 0.06)
        let critRate       = min(0.35, Double(snapshotDex) * 0.035)
        let healChargeTime = max(1.0, min(3.0, 3.0 / (1.0 + Double(heroDef) * 0.1)))

        // 3. 敵方數值
        let enemyMaxHp      = max(30, area.recommendedPower * 2)
        let enemyAtk        = max(8,  area.recommendedPower / 4)
        let enemyDef        = max(3,  area.recommendedPower / 10)
        let enemyChargeTime = max(0.8, 2.0 - Double(area.recommendedPower) * 0.001)

        // 4. 技能快照
        let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

        // 5. task seed（同 BattleLogGenerator）
        let tBits    = task.startedAt.timeIntervalSinceReferenceDate.bitPattern
        let hBits    = UInt64(bitPattern: Int64(truncatingIfNeeded: task.id.hashValue))
        let taskSeed = tBits ^ hBits

        // 6. 逐場結算（combatRng 跑模擬，settlementRng 算金幣 / 素材）
        var settlementRng = DeterministicRNG(task: task)
        var gold:            Int = 0
        var hide:            Int = 0
        var crystalShard:    Int = 0
        var ancientFragment: Int = 0
        var won:             Int = 0
        var lost:            Int = 0

        for battleIndex in 0..<totalBattles {
            let combatSeed = taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42
            let outcome = BattleLogGenerator.runCombat(
                seed:            combatSeed,
                activeSkills:    activeSkills,
                heroMaxHp:       heroMaxHp,
                heroAtk:         heroAtk,
                heroDef:         heroDef,
                heroChargeTime:  heroChargeTime,
                critRate:        critRate,
                healChargeTime:  healChargeTime,
                enemyMaxHp:      enemyMaxHp,
                enemyAtk:        enemyAtk,
                enemyDef:        enemyDef,
                enemyChargeTime: enemyChargeTime
            )

            if outcome.heroSurvived {
                won  += 1
                gold += settlementRng.nextInt(in: area.goldPerBattleRange)

                for entry in area.dropTable {
                    if settlementRng.nextDouble() < entry.dropRate {
                        let qty = settlementRng.nextInt(in: entry.quantityRange)
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

        // 7. 首次出征保底
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

        // 1. 場次計算（同 V1 規則）
        let actualDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles   = task.forcedBattles ?? max(1, Int(actualDuration / 60))

        // 2. 英雄戰鬥數值（與 BattleLogGenerator 相同公式）
        let snapshotPower = task.snapshotPower ?? 50
        let snapshotAgi   = task.snapshotAgi   ?? 0
        let snapshotDex   = task.snapshotDex   ?? 0

        let heroMaxHp      = max(50, snapshotPower * 2)
        let heroAtk        = max(10, snapshotPower / 4)
        let heroDef        = max(5,  snapshotPower / 10)
        let heroChargeTime = max(0.6, 1.8 - Double(snapshotAgi) * 0.06)
        let critRate       = min(0.35, Double(snapshotDex) * 0.035)
        let healChargeTime = max(1.0, min(3.0, 3.0 / (1.0 + Double(heroDef) * 0.1)))

        // 3. 敵方數值
        let enemyMaxHp      = max(30, floor.recommendedPower * 2)
        let enemyAtk        = max(8,  floor.recommendedPower / 4)
        let enemyDef        = max(3,  floor.recommendedPower / 10)
        let enemyChargeTime = max(0.8, 2.0 - Double(floor.recommendedPower) * 0.001)

        // 4. 技能快照
        let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

        // 5. task seed（同 BattleLogGenerator）
        let tBits    = task.startedAt.timeIntervalSinceReferenceDate.bitPattern
        let hBits    = UInt64(bitPattern: Int64(truncatingIfNeeded: task.id.hashValue))
        let taskSeed = tBits ^ hBits

        // 6. 逐場結算（combatRng 跑模擬，settlementRng 算金幣 / 素材）
        var settlementRng = DeterministicRNG(task: task)
        var gold:      Int = 0
        var materials: [MaterialType: Int] = [:]
        var won:       Int = 0
        var lost:      Int = 0

        for battleIndex in 0..<totalBattles {
            let combatSeed = taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42
            let outcome = BattleLogGenerator.runCombat(
                seed:            combatSeed,
                activeSkills:    activeSkills,
                heroMaxHp:       heroMaxHp,
                heroAtk:         heroAtk,
                heroDef:         heroDef,
                heroChargeTime:  heroChargeTime,
                critRate:        critRate,
                healChargeTime:  healChargeTime,
                enemyMaxHp:      enemyMaxHp,
                enemyAtk:        enemyAtk,
                enemyDef:        enemyDef,
                enemyChargeTime: enemyChargeTime
            )

            if outcome.heroSurvived {
                won  += 1
                gold += settlementRng.nextInt(in: floor.goldPerBattleRange)

                for entry in floor.dropTable {
                    if settlementRng.nextDouble() < entry.dropRate {
                        materials[entry.material, default: 0] += settlementRng.nextInt(in: entry.quantityRange)
                    }
                }
            } else {
                lost += 1
                gold += Int(Double(floor.goldPerBattleRange.lowerBound) * 0.2)
            }
        }

        // 7. 首次出征保底
        if task.forcedBattles != nil && gold == 0 {
            gold = floor.goldPerBattleRange.lowerBound
        }

        // 8. EXP 計算
        let expPerWin = max(1, floor.recommendedPower / 10)
        let totalExp  = won * expPerWin + lost * 1

        // 9. Boss 武器掉落（isBossFloor && 至少 1 場勝利）
        var rolledBossWeapon: (equipKey: String, atk: Int)?
        if floor.isBossFloor && won >= 1,
           let weaponDef = EquipmentDef.find(key: floor.unlocksEquipmentKey),
           let range = weaponDef.atkRange {
            let rolledAtk = settlementRng.nextInt(in: range)
            rolledBossWeapon = (floor.unlocksEquipmentKey, rolledAtk)
        }

        return FloorDungeonResult(
            gold:             gold,
            materials:        materials,
            battlesWon:       won,
            battlesLost:      lost,
            exp:              totalExp,
            rolledBossWeapon: rolledBossWeapon
        )
    }
}

// MARK: - DungeonAreaDef 勝率計算擴充（V1 相容用，T10 後不再用於結算）

extension DungeonAreaDef {

    /// 根據快照戰力計算此區域的勝率（保留供 UI 顯示勝率預覽使用）
    func winRate(snapshotPower: Int) -> Double {
        HeroStats.winRate(power: snapshotPower, recommendedPower: recommendedPower)
    }
}
