import Foundation
import SwiftData

@Model
final class HeroModel {
    var id: UUID
    var classKey: String
    var name: String
    var loreText: String?
    var level: Int
    var baseATK: Int
    var baseDEF: Int
    var baseHP: Int
    var baseSPD: Int
    var bonusATK: Int
    var bonusDEF: Int
    var bonusHP: Int
    var equippedWeaponId: String?
    var equippedArmorId: String?
    var isInActiveParty: Bool
    var partySlot: Int  // -1 = bench, 0-2 = party

    init(classKey: String, name: String, baseATK: Int, baseDEF: Int, baseHP: Int, baseSPD: Int) {
        self.id = UUID()
        self.classKey = classKey
        self.name = name
        self.loreText = nil
        self.level = 1
        self.baseATK = baseATK
        self.baseDEF = baseDEF
        self.baseHP = baseHP
        self.baseSPD = baseSPD
        self.bonusATK = 0
        self.bonusDEF = 0
        self.bonusHP = 0
        self.equippedWeaponId = nil
        self.equippedArmorId = nil
        self.isInActiveParty = false
        self.partySlot = -1
    }

    var effectiveATK: Int { baseATK + bonusATK }
    var effectiveDEF: Int { baseDEF + bonusDEF }
    var effectiveHP: Int { baseHP + bonusHP }
    var totalPower: Int { effectiveATK + effectiveDEF + (effectiveHP / 5) + baseSPD }
}
