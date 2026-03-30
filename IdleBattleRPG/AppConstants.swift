import Foundation

enum AppConstants {
    enum Game {
        static let maxOfflineHours: Double = 8
        static let heroSummonCost: Int = 300
        static let startingGold: Int = 100
        static let initialPartySlots: Int = 3
    }

    enum Upgrade {
        static let atkBaseCost: Int = 80
        static let defBaseCost: Int = 60
        static let hpBaseCost: Int = 40
        static let costExponent: Double = 1.18
        static let atkGainPercent: Double = 0.08
        static let defGainPercent: Double = 0.10
        static let hpGainPercent: Double = 0.12
    }

    enum Battle {
        static let winRateAtEqualPower: Double = 0.50
        static let winRateFloor: Double = 0.10
        static let winRateCeiling: Double = 0.98
        static let randomEventChance: Double = 0.15
        static let offlineSummaryTriggerSeconds: Double = 300  // 5 min
    }

    enum Claude {
        static let model: String = "claude-haiku-4-5-20251001"
        static let maxTokensHeroName: Int = 20
        static let maxTokensHeroLore: Int = 200
        static let maxTokensItemFlavor: Int = 100
        static let maxTokensOfflineSummary: Int = 250
        static let maxTokensRandomEvent: Int = 150
        static let batchDelayMs: UInt64 = 500_000_000  // 500ms in nanoseconds
    }

    enum Fallback {
        static let heroLore: String = "A seasoned warrior whose past is shrouded in mystery. They fight without question, and without fear."
        static let itemFlavor: String = "Forged in forgotten fires. Its purpose clear, its origin unknown."
        static let offlineSummary: String = "Your heroes fought valiantly in your absence, pushing back the darkness one battle at a time."
        static let randomEvent: String = "A strange wind passes through the zone. Your heroes press on."
    }
}
