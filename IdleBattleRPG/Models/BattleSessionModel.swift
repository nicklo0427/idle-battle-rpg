import Foundation
import SwiftData

@Model
final class BattleSessionModel {
    var id: UUID
    var zoneId: String
    var startedAt: Date
    var lastTickAt: Date
    var battlesWon: Int
    var battlesLost: Int
    var goldEarned: Int
    var isActive: Bool

    init(zoneId: String) {
        self.id = UUID()
        self.zoneId = zoneId
        self.startedAt = .now
        self.lastTickAt = .now
        self.battlesWon = 0
        self.battlesLost = 0
        self.goldEarned = 0
        self.isActive = true
    }
}
