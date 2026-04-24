// BattleLogGenerator.swift
// V4-1 重設計：AFK 地下城戰鬥敘事生成器（純計算層）
//
// 敘事循環（每場）：
//   探索 → 遭遇怪物 → 戰鬥回合 → 勝利（+金幣） 或 失敗（+療傷）
//   15 分鐘到 → 播放直接中斷（provider 回傳 nil）
//
// 設計原則：
//   - 純計算層，無副作用，不引入 SwiftData / ModelContext
//   - 相同輸入永遠回傳相同結果（確定性）

import Foundation

// MARK: - 狀態效果（V6-3 T05）

enum StatusEffect: Equatable {
    /// 燃燒：每回合固定傷害，持續 remainingTurns 回合
    case burn(remainingTurns: Int, dpt: Int)
    /// 中毒：可疊加，每回合 dptPerStack × stacks 傷害，戰鬥中不自動消退
    case poison(stacks: Int, dptPerStack: Int)
    /// 暈眩：跳過 remainingTurns 次行動
    case stun(remainingTurns: Int)
    /// 弱化：敵方攻擊傷害降低 atkReduction，持續 remainingTurns 回合
    case weakened(atkReduction: Double, remainingTurns: Int)
}

// MARK: - 戰鬥事件型別（V4-1 + V4-2 共用）

struct BattleEvent {
    enum EventType {
        case skill      // V6-1：技能啟動（出征開始時）
        case explore    // 探索敘述（每個 regionKey 不同候選文字）
        case encounter  // 遭遇怪物
        case attack     // 英雄攻擊
        case damage     // 英雄受傷
        case victory    // 英雄勝利 + 本場金幣
        case defeat     // 英雄落敗
        case heal       // 療傷恢復（失敗後，chargeTime > 0）
        case statusApplied   // V6-3 T05：施加狀態效果（燃燒 / 中毒 / 暈眩 / 弱化）
        case statusTick      // V6-3 T05：狀態效果觸發（傷害 / 跳過行動）
        case statusExpired   // V6-3 T05：狀態效果消退
        case potionUsed      // V7-4 T05：藥水觸發回復
    }

    let type:         EventType
    let description:  String
    let heroHpAfter:  Int
    let enemyHpAfter: Int
    let heroMaxHp:    Int
    let enemyMaxHp:   Int
    /// ATB / 療傷條填滿所需秒數（.attack / .damage / .heal 有值，其餘為 0）
    let chargeTime:   Double
    /// 英雄暴擊（DEX 驅動，僅 .attack 有效）
    let isCrit:       Bool
    /// heroATBProgress 的目標值（探索三階段用：0.33 / 0.67 / 1.0）
    let chargeTarget: Double
    /// T07：施放的技能 key（僅 .skill 事件且為真實技能施放時有效，其餘為 nil）
    let skillKey:     String?

    init(type: EventType, description: String,
         heroHpAfter: Int, enemyHpAfter: Int,
         heroMaxHp: Int, enemyMaxHp: Int,
         chargeTime: Double, isCrit: Bool,
         chargeTarget: Double = 1.0,
         skillKey: String? = nil) {
        self.type         = type
        self.description  = description
        self.heroHpAfter  = heroHpAfter
        self.enemyHpAfter = enemyHpAfter
        self.heroMaxHp    = heroMaxHp
        self.enemyMaxHp   = enemyMaxHp
        self.chargeTime   = chargeTime
        self.isCrit       = isCrit
        self.chargeTarget = chargeTarget
        self.skillKey     = skillKey
    }
}

// MARK: - 戰鬥模擬結果（T10：結算引擎共用）

struct CombatOutcome {
    let heroSurvived: Bool
}

// MARK: - 戰鬥記錄生成器

struct BattleLogGenerator {

    // MARK: - 當前場次計算

    /// 回傳目前正在進行的場次 index（0-based）
    static func currentBattleIndex(for task: TaskModel) -> Int {
        let elapsed          = Date.now.timeIntervalSince(task.startedAt)
        let totalDuration    = task.endsAt.timeIntervalSince(task.startedAt)
        let secondsPerBattle = 60.0
        let totalBattles     = task.forcedBattles ?? max(1, Int(totalDuration / secondsPerBattle))
        return min(max(0, Int(elapsed / secondsPerBattle)), totalBattles - 1)
    }

    // MARK: - 事件生成

    /// 從 fromBattleIndex 開始，生成該場及後續場次的戰鬥事件陣列
    /// - Parameters:
    ///   - task:            進行中的地下城任務
    ///   - floor:           樓層靜態定義
    ///   - fromBattleIndex: 起始場次（currentBattleIndex 的回傳值）
    ///   - maxBattles:      最多生成幾場（供 nextBatchProvider 控制批次大小）
    static func generate(
        task: TaskModel,
        floor: DungeonFloorDef,
        fromBattleIndex: Int,
        maxBattles: Int = Int.max,
        cuisineDef: CuisineDef? = nil,   // V7-4 T05
        potionDef: PotionDef? = nil      // V7-4 T05
    ) -> [BattleEvent] {

        let totalDuration = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles  = task.forcedBattles ?? max(1, Int(totalDuration / 60))

        let startIndex = max(0, fromBattleIndex)
        guard startIndex < totalBattles else { return [] }

        let snapshotPower = task.snapshotPower ?? 50
        let snapshotAgi   = task.snapshotAgi   ?? 0
        let snapshotDex   = task.snapshotDex   ?? 0

        // 英雄戰鬥數值
        var heroMaxHp = max(50, snapshotPower * 2)
        var heroAtk   = max(10, snapshotPower / 4)
        var heroDef   = max(5,  snapshotPower / 10)
        // V7-4：套用料理加成
        if let cuisine = cuisineDef {
            heroAtk   += cuisine.atkBonus
            heroDef   += cuisine.defBonus
            heroMaxHp += cuisine.hpBonus
        }

        // ATB 填充時間
        let heroChargeTime  = max(0.6, 1.8 - Double(snapshotAgi) * 0.06)
        let enemyChargeTime = max(0.8, 2.0 - Double(floor.recommendedPower) * 0.001)

        // 暴擊率
        let critRate = min(0.35, Double(snapshotDex) * 0.035)

        // 敵方數值（T11：血量 3× 提升，攻擊略微提升，讓戰鬥持續足夠回合以體現技能）
        let enemyMaxHp = max(80, floor.recommendedPower * 6)
        let enemyAtk   = max(10, floor.recommendedPower / 3)
        let enemyDef   = max(3,  floor.recommendedPower / 10)

        // 療傷時長：高 DEF 恢復更快
        let healChargeTime = max(1.0, min(3.0, 3.0 / (1.0 + Double(heroDef) * 0.1)))

        // 任務 seed
        let tBits    = task.startedAt.timeIntervalSinceReferenceDate.bitPattern
        let hBits    = UInt64(bitPattern: Int64(truncatingIfNeeded: task.id.hashValue))
        let taskSeed = tBits ^ hBits

        // V6-1：讀取已裝備主動技能
        let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }
        // V6-2 T09：讀取技能升階快照
        let skillLevels  = task.snapshotSkillLevels

        var allEvents: [BattleEvent] = []

        // V6-1：首批且有裝備技能時，插入簡短出征提示
        if startIndex == 0, !activeSkills.isEmpty {
            let names = activeSkills.map { $0.name }.joined(separator: "、")
            allEvents.append(BattleEvent(
                type:         .skill,
                description:  "帶著【\(names)】踏入地下城",
                heroHpAfter:  heroMaxHp,
                enemyHpAfter: 0,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   enemyMaxHp,
                chargeTime:   0,
                isCrit:       false,
                chargeTarget: 0
            ))
        }

        let endIndex = min(totalBattles, startIndex + maxBattles)
        for battleIndex in startIndex..<endIndex {
            allEvents += makeBattleEvents(
                battleIndex:     battleIndex,
                taskSeed:        taskSeed,
                floor:           floor,
                activeSkills:    activeSkills,
                skillLevels:     skillLevels,
                heroMaxHp:       heroMaxHp,
                heroAtk:         heroAtk,
                heroDef:         heroDef,
                heroChargeTime:  heroChargeTime,
                critRate:        critRate,
                healChargeTime:  healChargeTime,
                enemyMaxHp:      enemyMaxHp,
                enemyAtk:        enemyAtk,
                enemyDef:        enemyDef,
                enemyChargeTime: enemyChargeTime,
                potionDef:       potionDef
            )
        }

        return allEvents
    }

    // MARK: - 戰鬥核心（T10：BattleLogGenerator + DungeonSettlementEngine 共用）

    /// 執行一場戰鬥回合模擬的核心邏輯。
    /// - onEvent: nil → 結算模式（不建立 BattleEvent）；closure → 記錄模式（透過 closure 傳出事件）
    /// - 不生成 victory 事件（由 caller 決定 gold 並自行 append）
    /// - 生成 defeat + heal 事件（onEvent 非 nil 時）
    /// - 回傳 CombatOutcome，供 caller 判斷勝負
    internal static func runCombatCore(
        rng:             inout DeterministicRNG,
        enemyName:       String,
        activeSkills:    [SkillDef],
        skillLevels:     [String: Int] = [:],
        heroMaxHp:       Int,
        heroAtk:         Int,
        heroDef:         Int,
        heroChargeTime:  Double,
        critRate:        Double,
        healChargeTime:  Double,
        enemyMaxHp:      Int,
        enemyAtk:        Int,
        enemyDef:        Int,
        enemyChargeTime: Double,
        potionDef:       PotionDef? = nil,   // V7-4 T05
        onEvent:         ((BattleEvent) -> Void)?
    ) -> CombatOutcome {

        var heroHp      = heroMaxHp
        var enemyHp     = enemyMaxHp
        var potionUsed  = false   // V7-4 T05

        // T11：初始值為 cooldownSeconds，技能從冷卻開始，需完整等待一次 CD 才可觸發
        var skillNextFireTime: [String: Double] = Dictionary(
            uniqueKeysWithValues: activeSkills.map { ($0.key, Double($0.cooldownSeconds)) }
        )
        var elapsedCombatTime  = 0.0
        var heroAtkMultiplier  = 1.0
        var enemyAtkMultiplier = 1.0

        // T05: 敵方狀態效果追蹤
        var enemyStatuses: [StatusEffect] = []

        combatLoop: for _ in 0..<50 {
            guard heroHp > 0, enemyHp > 0 else { break }

            // T05: 每 tick 起始時，觸發燃燒 / 中毒傷害並倒數
            var nextStatuses: [StatusEffect] = []
            for status in enemyStatuses {
                switch status {
                case .burn(let turns, let dpt):
                    enemyHp = max(0, enemyHp - dpt)
                    onEvent?(BattleEvent(
                        type: .statusTick,
                        description: "🔥 \(enemyName) 燃燒傷害 \(dpt)（剩餘 \(max(0, turns - 1)) 回合）",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    if turns > 1 {
                        nextStatuses.append(.burn(remainingTurns: turns - 1, dpt: dpt))
                    } else {
                        onEvent?(BattleEvent(
                            type: .statusExpired,
                            description: "🔥 燃燒效果結束",
                            heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                            heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                            chargeTime: 0, isCrit: false
                        ))
                    }
                case .poison(let stacks, let dptPerStack):
                    let poisonDmg = dptPerStack * stacks
                    enemyHp = max(0, enemyHp - poisonDmg)
                    onEvent?(BattleEvent(
                        type: .statusTick,
                        description: "☠️ \(enemyName) 中毒傷害 \(poisonDmg)（\(stacks) 層）",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    nextStatuses.append(status)   // 中毒不自動消退
                case .stun, .weakened:
                    nextStatuses.append(status)   // 暈眩 / 弱化在行動時處理
                }
            }
            enemyStatuses = nextStatuses
            if enemyHp <= 0 { break }   // 狀態效果擊殺

            // V7-4 T05：藥水觸發（HP < 50% 時一次性回復）
            if let potion = potionDef, !potionUsed, heroHp < heroMaxHp / 2, heroHp > 0 {
                potionUsed = true
                let healed = Int(Double(heroMaxHp) * potion.healPercent)
                heroHp = min(heroMaxHp, heroHp + healed)
                onEvent?(BattleEvent(
                    type: .potionUsed,
                    description: "\(potion.icon) 飲下\(potion.name)！恢復 \(healed) HP（\(heroHp)/\(heroMaxHp)）",
                    heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                    heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                    chargeTime: 0, isCrit: false
                ))
            }

            elapsedCombatTime += heroChargeTime

            // 按裝備槽順序觸發到期技能
            for skill in activeSkills {
                guard let nextFire = skillNextFireTime[skill.key],
                      elapsedCombatTime >= nextFire else { continue }

                skillNextFireTime[skill.key] = nextFire + Double(skill.cooldownSeconds)

                let upgradeM = skill.effectMultiplier(at: skillLevels[skill.key] ?? 0)

                switch skill.effect {
                case .damage(let m):
                    let dmg = max(1, Int(Double(heroAtk) * m * upgradeM))
                    enemyHp = max(0, enemyHp - dmg)
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】對 \(enemyName) 造成 \(dmg) 傷害",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    if enemyHp <= 0 { break combatLoop }

                case .heal(let m):
                    let restored = Int(Double(heroMaxHp) * m * upgradeM)
                    heroHp = min(heroMaxHp, heroHp + restored)
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】恢復 \(restored) HP（\(heroHp)/\(heroMaxHp)）",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))

                case .damageAndHeal(let dm, let hm):
                    let dmg      = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    let restored = Int(Double(heroMaxHp) * hm * upgradeM)
                    enemyHp = max(0, enemyHp - dmg)
                    heroHp  = min(heroMaxHp, heroHp + restored)
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】造成 \(dmg) 傷害，恢復 \(restored) HP",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    if enemyHp <= 0 { break combatLoop }

                case .heroAtkUp(let b):
                    let scaledB = min(0.99, b * upgradeM)
                    heroAtkMultiplier = 1.0 + scaledB
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】下次攻擊傷害提升 \(Int(scaledB * 100))%",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))

                case .enemyAtkDown(let r):
                    let scaledR = min(0.99, r * upgradeM)
                    enemyAtkMultiplier = 1.0 - scaledR
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】\(enemyName) 下次攻擊削弱 \(Int(scaledR * 100))%",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))

                case .damageAndEnemyAtkDown(let dm, let r):
                    let scaledR = min(0.99, r * upgradeM)
                    let dmg = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    enemyHp = max(0, enemyHp - dmg)
                    enemyAtkMultiplier = 1.0 - scaledR
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】造成 \(dmg) 傷害，\(enemyName) 下次攻擊削弱 \(Int(scaledR * 100))%",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    if enemyHp <= 0 { break combatLoop }

                // T05: 狀態效果技能
                case .damageAndBurn(let dm, let dpt, let dur):
                    let dmg = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    enemyHp = max(0, enemyHp - dmg)
                    enemyStatuses.append(.burn(remainingTurns: dur, dpt: dpt))
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】造成 \(dmg) 傷害",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    onEvent?(BattleEvent(
                        type: .statusApplied,
                        description: "🔥 \(enemyName) 陷入燃燒！每回合 \(dpt) 傷害，持續 \(dur) 回合",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    if enemyHp <= 0 { break combatLoop }

                case .damageAndPoison(let dm, let dptPerStack):
                    let dmg = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    enemyHp = max(0, enemyHp - dmg)
                    // 疊加中毒層數
                    if let idx = enemyStatuses.firstIndex(where: { if case .poison = $0 { return true }; return false }) {
                        if case .poison(let stacks, _) = enemyStatuses[idx] {
                            let newStacks = stacks + 1
                            enemyStatuses[idx] = .poison(stacks: newStacks, dptPerStack: dptPerStack)
                            onEvent?(BattleEvent(
                                type: .skill,
                                description: "【\(skill.name)】造成 \(dmg) 傷害，中毒加深（\(newStacks) 層）",
                                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                                chargeTime: 0, isCrit: false, skillKey: skill.key
                            ))
                        }
                    } else {
                        enemyStatuses.append(.poison(stacks: 1, dptPerStack: dptPerStack))
                        onEvent?(BattleEvent(
                            type: .skill,
                            description: "【\(skill.name)】造成 \(dmg) 傷害，施加中毒",
                            heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                            heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                            chargeTime: 0, isCrit: false, skillKey: skill.key
                        ))
                        onEvent?(BattleEvent(
                            type: .statusApplied,
                            description: "☠️ \(enemyName) 中毒！每回合持續受到毒害",
                            heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                            heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                            chargeTime: 0, isCrit: false
                        ))
                    }
                    if enemyHp <= 0 { break combatLoop }

                case .stunAndDamage(let dm, let dur):
                    let dmg = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    enemyHp = max(0, enemyHp - dmg)
                    enemyStatuses.append(.stun(remainingTurns: dur))
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】造成 \(dmg) 傷害",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    onEvent?(BattleEvent(
                        type: .statusApplied,
                        description: "💫 \(enemyName) 被暈眩！跳過 \(dur) 次行動",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    if enemyHp <= 0 { break combatLoop }

                case .damageAndWeaken(let dm, let r, let dur):
                    let dmg = max(1, Int(Double(heroAtk) * dm * upgradeM))
                    let scaledR = min(0.99, r * upgradeM)
                    enemyHp = max(0, enemyHp - dmg)
                    enemyStatuses.append(.weakened(atkReduction: scaledR, remainingTurns: dur))
                    onEvent?(BattleEvent(
                        type: .skill,
                        description: "【\(skill.name)】造成 \(dmg) 傷害",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false, skillKey: skill.key
                    ))
                    onEvent?(BattleEvent(
                        type: .statusApplied,
                        description: "⬇️ \(enemyName) 被弱化！攻擊力降低 \(Int(scaledR * 100))%，持續 \(dur) 回合",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    if enemyHp <= 0 { break combatLoop }
                }
            }

            guard heroHp > 0, enemyHp > 0 else { break }

            // 英雄攻擊
            let isCrit  = rng.nextDouble() < critRate
            var heroDmg = max(1, heroAtk - enemyDef + rng.nextInt(in: -2...2))
            if isCrit { heroDmg = Int(Double(heroDmg) * 1.5) }
            heroDmg = max(1, Int(Double(heroDmg) * heroAtkMultiplier))
            heroAtkMultiplier = 1.0
            enemyHp = max(0, enemyHp - heroDmg)

            onEvent?(BattleEvent(
                type: .attack,
                description: isCrit ? "⚡ 暴擊！發動斬擊 → 造成 \(heroDmg) 傷害"
                                    : "發動斬擊 → 造成 \(heroDmg) 傷害",
                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: heroChargeTime, isCrit: isCrit
            ))

            guard enemyHp > 0 else { break }

            // T05: 暈眩檢查 — 敵方被暈眩時跳過反擊
            var skipEnemyAttack = false
            if let stIdx = enemyStatuses.firstIndex(where: { if case .stun = $0 { return true }; return false }) {
                if case .stun(let turns) = enemyStatuses[stIdx] {
                    skipEnemyAttack = true
                    onEvent?(BattleEvent(
                        type: .statusTick,
                        description: "💫 \(enemyName) 被暈眩，無法行動！",
                        heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                        heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                        chargeTime: 0, isCrit: false
                    ))
                    if turns <= 1 {
                        enemyStatuses.remove(at: stIdx)
                        onEvent?(BattleEvent(
                            type: .statusExpired,
                            description: "💫 暈眩效果結束",
                            heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                            heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                            chargeTime: 0, isCrit: false
                        ))
                    } else {
                        enemyStatuses[stIdx] = .stun(remainingTurns: turns - 1)
                    }
                }
            }

            if !skipEnemyAttack {
                // T05: 計算弱化折減（取第一個 weakened 狀態的折減值）
                let weakenReduction = enemyStatuses.compactMap { s -> Double? in
                    if case .weakened(let r, _) = s { return r }
                    return nil
                }.first ?? 0.0

                // 敵方反擊
                var enemyDmg = max(1, enemyAtk - heroDef + rng.nextInt(in: -2...2))
                let effectiveMultiplier = (1.0 - weakenReduction) * enemyAtkMultiplier
                enemyDmg = max(1, Int(Double(enemyDmg) * effectiveMultiplier))
                enemyAtkMultiplier = 1.0
                heroHp = max(0, heroHp - enemyDmg)

                onEvent?(BattleEvent(
                    type: .damage,
                    description: "\(enemyName) 反擊 → 受到 \(enemyDmg) 傷害",
                    heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                    heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                    chargeTime: enemyChargeTime, isCrit: false
                ))

                // T05: 弱化倒數（每次敵方攻擊後 -1 回合）
                var tickedStatuses: [StatusEffect] = []
                for s in enemyStatuses {
                    if case .weakened(let r, let turns) = s {
                        if turns <= 1 {
                            onEvent?(BattleEvent(
                                type: .statusExpired,
                                description: "⬇️ 弱化效果結束，\(enemyName) 恢復正常攻擊力",
                                heroHpAfter: heroHp, enemyHpAfter: enemyHp,
                                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                                chargeTime: 0, isCrit: false
                            ))
                        } else {
                            tickedStatuses.append(.weakened(atkReduction: r, remainingTurns: turns - 1))
                        }
                    } else {
                        tickedStatuses.append(s)
                    }
                }
                enemyStatuses = tickedStatuses
            }
        }

        // 失敗事件（記錄模式）
        if heroHp <= 0 {
            onEvent?(BattleEvent(
                type: .defeat,
                description: "💀 落敗於 \(enemyName)…",
                heroHpAfter: 0, enemyHpAfter: enemyHp,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: 0, isCrit: false
            ))
            onEvent?(BattleEvent(
                type: .heal,
                description: "療傷中… HP 恢復至 \(heroMaxHp)",
                heroHpAfter: heroMaxHp, enemyHpAfter: 0,
                heroMaxHp: heroMaxHp, enemyMaxHp: enemyMaxHp,
                chargeTime: healChargeTime, isCrit: false
            ))
        }

        return CombatOutcome(heroSurvived: heroHp > 0)
    }

    /// 供 DungeonSettlementEngine 使用的公開入口（無事件生成）
    /// seed 應為：taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42
    static func runCombat(
        seed:            UInt64,
        activeSkills:    [SkillDef],
        skillLevels:     [String: Int] = [:],
        heroMaxHp:       Int,
        heroAtk:         Int,
        heroDef:         Int,
        heroChargeTime:  Double,
        critRate:        Double,
        healChargeTime:  Double,
        enemyMaxHp:      Int,
        enemyAtk:        Int,
        enemyDef:        Int,
        enemyChargeTime: Double
    ) -> CombatOutcome {
        var rng = DeterministicRNG(seed: seed)
        return runCombatCore(
            rng:             &rng,
            enemyName:       "",
            activeSkills:    activeSkills,
            skillLevels:     skillLevels,
            heroMaxHp:       heroMaxHp,
            heroAtk:         heroAtk,
            heroDef:         heroDef,
            heroChargeTime:  heroChargeTime,
            critRate:        critRate,
            healChargeTime:  healChargeTime,
            enemyMaxHp:      enemyMaxHp,
            enemyAtk:        enemyAtk,
            enemyDef:        enemyDef,
            enemyChargeTime: enemyChargeTime,
            onEvent:         nil
        )
    }

    // MARK: - 單場事件生成（private）

    private static func makeBattleEvents(
        battleIndex:     Int,
        taskSeed:        UInt64,
        floor:           DungeonFloorDef,
        activeSkills:    [SkillDef],
        skillLevels:     [String: Int] = [:],
        heroMaxHp:       Int,
        heroAtk:         Int,
        heroDef:         Int,
        heroChargeTime:  Double,
        critRate:        Double,
        healChargeTime:  Double,
        enemyMaxHp:      Int,
        enemyAtk:        Int,
        enemyDef:        Int,
        enemyChargeTime: Double,
        potionDef:       PotionDef? = nil   // V7-4 T05
    ) -> [BattleEvent] {
        // 探索 seed（文字選取）：原有 per-battle seed
        var exploreRng = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1))
        // 戰鬥 seed（RNG 與結算引擎一致）：XOR 0x434F4D42（"COMB"）
        var combatRng  = DeterministicRNG(seed: taskSeed ^ UInt64(battleIndex &+ 1) ^ 0x434F4D42)

        var events: [BattleEvent] = []

        // 0. 敵人名稱：Boss 用 bossName，一般層從 commonEnemyNames 以 exploreRng 隨機選
        let enemyName: String
        if let boss = floor.bossName {
            enemyName = boss
        } else {
            let names = floor.commonEnemyNames
            let idx   = Int(exploreRng.nextUInt64() % UInt64(max(1, names.count)))
            enemyName = names.isEmpty ? "未知敵人" : names[idx]
        }

        // 1. 探索事件（4 個：到達 + 三階段搜索）
        let exploreLines = exploreDescriptions(for: floor.regionKey)
        let exploreIdx   = Int(exploreRng.nextUInt64() % UInt64(exploreLines.count))
        // 1a. 到達文字（立即顯示，chargeTime = 0）
        events.append(BattleEvent(
            type:         .explore,
            description:  exploreLines[exploreIdx],
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: enemyMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   enemyMaxHp,
            chargeTime:   0,
            isCrit:       false
        ))
        // 1b–1d. 搜索三階段（輕鬆 → 警覺 → 緊張）
        let totalChargeTime = exploreChargeTime(regionKey: floor.regionKey, floorIndex: floor.floorIndex)
        let phaseTime       = (totalChargeTime / 3.0 * 10).rounded() / 10

        let relaxedLines    = exploreRelaxedDescriptions(for: floor.regionKey)
        let suspiciousLines = exploreSuspiciousDescriptions(for: floor.regionKey)
        let tenseLines      = exploreTenseDescriptions(for: floor.regionKey)

        let relaxedIdx    = Int(exploreRng.nextUInt64() % UInt64(relaxedLines.count))
        let suspiciousIdx = Int(exploreRng.nextUInt64() % UInt64(suspiciousLines.count))
        let tenseIdx      = Int(exploreRng.nextUInt64() % UInt64(tenseLines.count))

        events.append(BattleEvent(
            type:         .explore,
            description:  relaxedLines[relaxedIdx],
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: enemyMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   enemyMaxHp,
            chargeTime:   phaseTime,
            isCrit:       false,
            chargeTarget: 1.0 / 3.0
        ))
        events.append(BattleEvent(
            type:         .explore,
            description:  suspiciousLines[suspiciousIdx],
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: enemyMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   enemyMaxHp,
            chargeTime:   phaseTime,
            isCrit:       false,
            chargeTarget: 2.0 / 3.0
        ))
        events.append(BattleEvent(
            type:         .explore,
            description:  tenseLines[tenseIdx],
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: enemyMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   enemyMaxHp,
            chargeTime:   phaseTime,
            isCrit:       false,
            chargeTarget: 1.0
        ))

        // 2. 遭遇事件
        events.append(BattleEvent(
            type:         .encounter,
            description:  "發現了 \(enemyName)！",
            heroHpAfter:  heroMaxHp,
            enemyHpAfter: enemyMaxHp,
            heroMaxHp:    heroMaxHp,
            enemyMaxHp:   enemyMaxHp,
            chargeTime:   0,
            isCrit:       false
        ))

        // 3. 戰鬥回合（T10：委託 runCombatCore，使用 combatRng）
        let outcome = runCombatCore(
            rng:             &combatRng,
            enemyName:       enemyName,
            activeSkills:    activeSkills,
            skillLevels:     skillLevels,
            heroMaxHp:       heroMaxHp,
            heroAtk:         heroAtk,
            heroDef:         heroDef,
            heroChargeTime:  heroChargeTime,
            critRate:        critRate,
            healChargeTime:  healChargeTime,
            enemyMaxHp:      enemyMaxHp,
            enemyAtk:        enemyAtk,
            enemyDef:        enemyDef,
            enemyChargeTime: enemyChargeTime,
            potionDef:       potionDef,
            onEvent:         { events.append($0) }
        )

        // 4. 勝利事件（敗場的 defeat + heal 已由 runCombatCore 透過 onEvent 生成）
        if outcome.heroSurvived {
            let gold = exploreRng.nextInt(in: floor.goldPerBattleRange)
            events.append(BattleEvent(
                type:         .victory,
                description:  "⚔️ 戰勝 \(enemyName)！獲得 \(gold) 金幣",
                heroHpAfter:  heroMaxHp,
                enemyHpAfter: 0,
                heroMaxHp:    heroMaxHp,
                enemyMaxHp:   enemyMaxHp,
                chargeTime:   0,
                isCrit:       false
            ))
        }

        return events
    }

    // MARK: - 探索到達描述候選（依 regionKey）

    private static func exploreDescriptions(for regionKey: String) -> [String] {
        switch regionKey {
        case "wildland":
            return [
                "穿越枯草荒原，搜尋敵蹤…",
                "沿著裂石山道深入邊境…",
                "狩獵足跡蔓延至前方林地…",
                "荒風捲起塵土，四周悄然無聲…",
            ]
        case "abandoned_mine":
            return [
                "循著礦坑幽光緩步前行…",
                "敲擊岩壁，辨認通道方向…",
                "瓦斯燈昏暗，深處傳來回音…",
                "踩過碎石，礦道愈加狹窄…",
            ]
        case "ancient_ruins":
            return [
                "碑文碎裂，空氣中瀰漫古老氣息…",
                "踏過斷階，前殿在遠方隱約可見…",
                "遺跡牆面浮現詭異符文…",
                "迴廊深處，火把忽明忽滅…",
            ]
        case "sunken_city":
            return [
                "幽暗水流漫過腳踝，滲透甲縫…",
                "沉沒的王城殘影在黑水中若隱若現…",
                "腐蝕魔力在空氣中凝結，呼吸愈發沉重…",
                "石壁滲出幽光，水底藏著什麼…",
            ]
        default:
            return ["小心翼翼地探索前方…"]
        }
    }

    // MARK: - 探索三階段文字候選

    /// 階段一：輕鬆（進度 0→⅓）
    private static func exploreRelaxedDescriptions(for regionKey: String) -> [String] {
        switch regionKey {
        case "wildland":
            return [
                "撥開荒草，仔細查看腳印方向…",
                "藏身岩後，靜待獵物現身…",
                "循聲而動，確認威脅來源…",
                "握緊武器，確認地形後繼續推進…",
            ]
        case "abandoned_mine":
            return [
                "舉起礦燈，逐一掃視坑道隱角…",
                "壓低身形，貼著礦壁緩緩前移…",
                "聽辨水滴與腳步的差異…",
                "探出手，摸索黑暗中的通道壁面…",
            ]
        case "ancient_ruins":
            return [
                "以劍尖試探碎石地面，避免陷阱…",
                "細讀壁上符文，判斷守護者位置…",
                "屏住呼吸，辨別遠處回廊的氣息…",
                "繞過倒塌石柱，搜索前方暗處…",
            ]
        case "sunken_city":
            return [
                "撥開黑水中的浮木殘骸，緩慢前行…",
                "沿著半沉的迴廊扶手，辨認方向…",
                "低頭通過坍塌的拱門，小心腳下…",
                "水聲掩蓋腳步，靜靜探索前方…",
            ]
        default:
            return ["謹慎搜索周圍環境…"]
        }
    }

    /// 階段二：警覺（進度 ⅓→⅔）
    private static func exploreSuspiciousDescriptions(for regionKey: String) -> [String] {
        switch regionKey {
        case "wildland":
            return [
                "枯草中隱約有動靜，謹慎靠近…",
                "遠處傳來踩枝聲，停步傾聽…",
                "腳步聲漸近，握緊武器…",
                "草叢搖動，是獵物還是陷阱？",
            ]
        case "abandoned_mine":
            return [
                "深處傳來低沉回響，停步辨認…",
                "礦壁裂縫透出微光，靠近查看…",
                "坑道空氣突然凝重，有什麼在前方…",
                "碎石悄然滾落，來自某個方向…",
            ]
        case "ancient_ruins":
            return [
                "符文忽然發出微弱光芒…",
                "廊道氣流異常，有東西在移動…",
                "前方陰影扭曲，不像是岩石…",
                "石板上留有新鮮的爪痕…",
            ]
        case "sunken_city":
            return [
                "水面泛起漣漪，不是水流造成的…",
                "幽光閃動，有什麼正在接近…",
                "腐蝕氣息驟然變濃，警覺提升…",
                "黑水深處有輪廓在移動，停步觀察…",
            ]
        default:
            return ["感覺有什麼在附近潛伏…"]
        }
    }

    /// 階段三：緊張（進度 ⅔→1）
    private static func exploreTenseDescriptions(for regionKey: String) -> [String] {
        switch regionKey {
        case "wildland":
            return [
                "輪廓在荒草中若隱若現，就是現在！",
                "獵物已在視線內，不能退縮！",
                "雙方視線交錯，戰鬥一觸即發！",
                "來者不善，決戰就在眼前！",
            ]
        case "abandoned_mine":
            return [
                "黑暗中有東西在逼近，後退已來不及！",
                "坑道盡頭，一雙眼睛正盯著你！",
                "礦道震動，威脅就在轉角後方！",
                "身後退路已斷，只能正面迎擊！",
            ]
        case "ancient_ruins":
            return [
                "守護者從黑暗中現形，無路可退！",
                "遺跡封印碎裂，危機已然降臨！",
                "石像睜開眼睛，直視著你！",
                "回廊充斥殺意，決戰時刻已到！",
            ]
        case "sunken_city":
            return [
                "黑水激蕩，溺化的守衛已鎖定你！",
                "腐蝕魔力驟然爆發，決戰無可避免！",
                "沉沒的王城顫抖，威脅正面現身！",
                "幽暗海水凝固成刃，退路已斷！",
            ]
        default:
            return ["危險近在咫尺，迎戰！"]
        }
    }

    // MARK: - 探索搜索時長（regionKey + floorIndex → chargeTime）
    // 荒野 F1=10s, 礦坑 F1=15s, 遺跡 F1=22s, 沉落王城 F1=30s；每層 +10%

    private static func exploreChargeTime(regionKey: String, floorIndex: Int) -> Double {
        let base: Double
        switch regionKey {
        case "wildland":       base = 10.0
        case "abandoned_mine": base = 15.0
        case "ancient_ruins":  base = 22.0
        case "sunken_city":    base = 30.0
        default:               base = 10.0
        }
        let depth = max(0, floorIndex - 1)
        let raw   = base * pow(1.1, Double(depth))
        return (raw * 10).rounded() / 10
    }

}
