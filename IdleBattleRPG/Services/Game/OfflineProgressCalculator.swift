import Foundation

struct OfflineResult {
    let offlineSeconds: Int
    let battlesSimulated: Int
    let battlesWon: Int
    let goldEarned: Int
    let materialDrops: [String: Int]
    let cappedAtMaxHours: Bool

    var formattedDuration: String {
        let hours = offlineSeconds / 3600
        let minutes = (offlineSeconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

enum OfflineProgressCalculator {
    static func calculate(
        from lastLogin: Date,
        to now: Date,
        party: [HeroModel],
        zone: ZoneDefinition
    ) -> OfflineResult {
        let maxSeconds = Int(AppConstants.Game.maxOfflineHours * 3600)
        let rawSeconds = Int(now.timeIntervalSince(lastLogin))
        let offlineSeconds = min(rawSeconds, maxSeconds)
        let cappedAtMaxHours = rawSeconds > maxSeconds

        guard !party.isEmpty else {
            return OfflineResult(offlineSeconds: offlineSeconds, battlesSimulated: 0, battlesWon: 0,
                                 goldEarned: 0, materialDrops: [:], cappedAtMaxHours: cappedAtMaxHours)
        }

        let secondsPerBattle = 3600 / zone.battlesPerHour
        let totalBattles = offlineSeconds / secondsPerBattle

        let teamPower = party.reduce(0) { $0 + $1.totalPower }
        let winRate = clampedWinRate(teamPower: teamPower, zone: zone)

        // Seed: derived from lastLogin so it's reproducible
        let seed = UInt64(abs(lastLogin.timeIntervalSinceReferenceDate)) &* 6364136223846793005
        var rng = SeededRNG(seed: seed)

        var goldEarned = 0
        var battlesWon = 0
        var drops: [String: Int] = [:]

        for _ in 0..<totalBattles {
            if rng.nextBool(probability: winRate) {
                battlesWon += 1
                goldEarned += rng.nextInt(in: zone.goldPerBattle)

                // Roll drops from monster pool
                for monster in zone.monsterPool {
                    if rng.nextBool(probability: monster.dropChance) {
                        let dropKey = monster.possibleDrops[rng.nextInt(in: 0...(monster.possibleDrops.count - 1))]
                        drops[dropKey, default: 0] += 1
                    }
                }
            }
        }

        return OfflineResult(
            offlineSeconds: offlineSeconds,
            battlesSimulated: totalBattles,
            battlesWon: battlesWon,
            goldEarned: goldEarned,
            materialDrops: drops,
            cappedAtMaxHours: cappedAtMaxHours
        )
    }

    static func clampedWinRate(teamPower: Int, zone: ZoneDefinition) -> Double {
        guard zone.minTeamPower > 0 else { return 0.95 }
        let ratio = Double(teamPower) / Double(zone.minTeamPower)
        let raw = 0.5 + 0.45 * tanh(2.0 * (ratio - 1.0))
        return max(AppConstants.Battle.winRateFloor, min(AppConstants.Battle.winRateCeiling, raw))
    }
}
