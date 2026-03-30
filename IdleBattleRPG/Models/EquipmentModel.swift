import Foundation
import SwiftData

@Model
final class EquipmentModel {
    var id: UUID
    var definitionKey: String
    var flavorText: String?
    var quantity: Int
    var equippedByHeroId: UUID?

    init(definitionKey: String, quantity: Int = 1) {
        self.id = UUID()
        self.definitionKey = definitionKey
        self.flavorText = nil
        self.quantity = quantity
        self.equippedByHeroId = nil
    }
}
