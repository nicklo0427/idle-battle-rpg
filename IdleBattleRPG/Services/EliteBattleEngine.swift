// EliteBattleEngine.swift
// V4-2 菁英戰鬥：純計算層
//
// 設計原則：
//   - 純計算，無副作用，不引入 SwiftData / ModelContext
//   - 相同輸入永遠回傳相同結果（確定性 RNG）
//   - 輸出 EliteBattleResult，含 toBattleEvents() 供 BattleLogSheet 播放
//
// 與 AFK 戰鬥的差異：
//   - 無探索階段（玩家主動挑戰，直接進入遭遇）
//   - 菁英 HP / ATK / DEF 來自 EliteDef（比普通小怪高出許多）
//   - 菁英 ATB 固定 1.5s（不依 recommendedPower 縮放）
//   - 勝利後顯示金幣 + 素材獎勵，失敗無療傷（可重試）

import Foundation

// MARK: - 菁英戰鬥結果

struct EliteBattleResult {
    let elite:            EliteDef
    let won:              Bool
    let heroHpRemaining:  Int
    let eliteHpRemaining: Int
    let heroMaxHp:        Int
    /// 可直接傳入 BattleLogSheet 的事件序列
    let events:           [BattleEvent]

    /// 轉成 BattleLogSheet 所需的 EliteBattleOutcome
    var outcome: EliteBattleOutcome {
        if won {
            let rewardText = "⚔️ 擊敗 \(elite.name)！\n獲得 \(elite.reward.gold) 金幣 + \(elite.reward.material.icon)\(elite.reward.material.displayName) ×\(elite.reward.materialCount)"
            return .won(rewardText: rewardText)
        } else {
            return .lost
        }
    }
}

// MARK: - 菁英戰鬥引擎

struct EliteBattleEngine {

    // MARK: - 公開 API

    /// 模擬一場菁英戰鬥，回傳完整結果（含事件序列）
    /// - Parameters:
    ///   - elite:      菁英靜態定義
    ///   - heroPower:  英雄當前戰力快照
    ///   - heroAgi:    英雄敏捷（影響 ATB 速度）
    ///   - heroDex:    英雄靈巧（影響暴擊率）
    ///   - seed:       確定性種子（同 seed 永遠產生相同結果）
    static func simulate(
        elite:      EliteDef,
        heroPower:  Int,
        heroAgi:    Int,
        heroDex:    Int,
        seed:       UInt64
    ) -> EliteBattleResult {

        var rng = DeterministicRNG(seed: seed == 0 ? 9876543210987654321 : seed)

        // ── 英雄數值（與 AFK 公式一致）──
        let heroMaxHp       = max(50, heroPower * 2)
        let heroAtk         = max(10, heroPower / 4)
        let heroDef         = max(5,  heroPower / 10)
        let heroChargeTime  = max(0.6, 1.8 - Double(heroAgi) * 0.06)
        let critRate        = min(0.35, Double(heroDex) * 0.035)

        // ── 菁英數值（直接來自 EliteDef）──
        let eliteMaxHp      = elite.hp
        let eliteAtk        = elite.atk
        let eliteDef        = elite.def
        let eliteChargeTime = 1.5   // 菁英固定 ATB（比普通怪慢但更穩）

        var events: [BattleEvent] = []

        // 1. 遭遇事件
        events.append(BattleEvent(
            type:         .encounter,
            description:  "挑戰菁英 \(elite.name)！",
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: eliteMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   eliteMaxHp,
            chargeTime:   0,
            isCrit:       false
        ))

        // 2. 戰鬥回合
        var heroHp  = heroMaxHp
        var eliteHp = eliteMaxHp
        let maxRounds = 80   // 菁英 HP 高，最多 80 回合防止無限迴圈

        for _ in 0..<maxRounds {
            guard heroHp > 0, eliteHp > 0 else { break }

            // 英雄攻擊
            let isCrit  = rng.nextDouble() < critRate
            var heroDmg = max(1, heroAtk - eliteDef + rng.nextInt(in: -2...2))
            if isCrit { heroDmg = Int(Double(heroDmg) * 1.5) }
            eliteHp = max(0, eliteHp - heroDmg)

            let attackDesc = isCrit
                ? "⚡ 暴擊！發動斬擊 → 造成 \(heroDmg) 傷害"
                : "發動斬擊 → 造成 \(heroDmg) 傷害"

            events.append(BattleEvent(
                type:         .attack,
                description:  attackDesc,
                heroHpAfter:  heroHp,
                enemyHpAfter: eliteHp,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   eliteMaxHp,
                chargeTime:   heroChargeTime,
                isCrit:       isCrit
            ))

            guard eliteHp > 0 else { break }

            // 菁英反擊
            let eliteDmg = max(1, eliteAtk - heroDef + rng.nextInt(in: -2...2))
            heroHp = max(0, heroHp - eliteDmg)

            events.append(BattleEvent(
                type:         .damage,
                description:  "\(elite.name) 狂擊 → 受到 \(eliteDmg) 傷害",
                heroHpAfter:  heroHp,
                enemyHpAfter: eliteHp,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   eliteMaxHp,
                chargeTime:   eliteChargeTime,
                isCrit:       false
            ))
        }

        // 3. 勝利 / 失敗
        let won = heroHp > 0

        if won {
            let rewardDesc = "⚔️ 擊敗 \(elite.name)！獲得 \(elite.reward.gold) 金幣 + \(elite.reward.material.icon)\(elite.reward.material.displayName) ×\(elite.reward.materialCount)"
            events.append(BattleEvent(
                type:         .victory,
                description:  rewardDesc,
                heroHpAfter:  heroHp,
                enemyHpAfter: 0,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   eliteMaxHp,
                chargeTime:   0,
                isCrit:       false
            ))
        } else {
            events.append(BattleEvent(
                type:         .defeat,
                description:  "💀 落敗於 \(elite.name)… 可重新挑戰",
                heroHpAfter:  0,
                enemyHpAfter: eliteHp,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   eliteMaxHp,
                chargeTime:   0,
                isCrit:       false
            ))
        }

        return EliteBattleResult(
            elite:            elite,
            won:              won,
            heroHpRemaining:  max(0, heroHp),
            eliteHpRemaining: max(0, eliteHp),
            heroMaxHp:        heroMaxHp,
            events:           events
        )
    }

    // MARK: - Seed 派生

    /// 從菁英 key + 當前時間派生 seed（每次挑戰都不同，但同時間同菁英結果固定）
    static func makeSeed(eliteKey: String, attemptDate: Date = .now) -> UInt64 {
        let tBits = attemptDate.timeIntervalSinceReferenceDate.bitPattern
        let hBits = UInt64(bitPattern: Int64(truncatingIfNeeded: eliteKey.hashValue))
        return tBits ^ hBits
    }
}
