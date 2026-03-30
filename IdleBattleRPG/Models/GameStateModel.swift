import Foundation
import SwiftData

@Model
final class GameStateModel {
    var gold: Int
    var lastLoginDate: Date
    var activeZoneId: String
    var totalBattlesWon: Int
    var offlineSummaryPending: Bool
    var offlineSummaryText: String?
    var offlineSeconds: Int
    var isOnboarded: Bool

    init() {
        self.gold = AppConstants.Game.startingGold
        self.lastLoginDate = .now
        self.activeZoneId = "Z01"
        self.totalBattlesWon = 0
        self.offlineSummaryPending = false
        self.offlineSummaryText = nil
        self.offlineSeconds = 0
        self.isOnboarded = false
    }
}
