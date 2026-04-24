// ConsumableInventoryModel.swift
// 消耗品背包（單例 SwiftData Model）

import Foundation
import SwiftData

@Model
final class ConsumableInventoryModel {

    // 廚師料理
    var fishStew: Int = 0;           var fishStewHigh: Int = 0
    var herbFishSoup: Int = 0;       var herbFishSoupHigh: Int = 0
    var abyssSoup: Int = 0;          var abyssSoupHigh: Int = 0
    var smokedAbyssFish: Int = 0;    var smokedAbyssFishHigh: Int = 0

    // 藥水（T04 使用）
    var smallPotion: Int = 0
    var mediumPotion: Int = 0

    init() {}

    func amount(of type: ConsumableType) -> Int {
        switch type {
        case .fishStew:              return fishStew
        case .fishStewHigh:          return fishStewHigh
        case .herbFishSoup:          return herbFishSoup
        case .herbFishSoupHigh:      return herbFishSoupHigh
        case .abyssSoup:             return abyssSoup
        case .abyssSoupHigh:         return abyssSoupHigh
        case .smokedAbyssFish:       return smokedAbyssFish
        case .smokedAbyssFishHigh:   return smokedAbyssFishHigh
        case .smallPotion:           return smallPotion
        case .mediumPotion:          return mediumPotion
        }
    }

    func add(_ n: Int = 1, of type: ConsumableType) {
        switch type {
        case .fishStew:              fishStew              += n
        case .fishStewHigh:          fishStewHigh          += n
        case .herbFishSoup:          herbFishSoup          += n
        case .herbFishSoupHigh:      herbFishSoupHigh      += n
        case .abyssSoup:             abyssSoup             += n
        case .abyssSoupHigh:         abyssSoupHigh         += n
        case .smokedAbyssFish:       smokedAbyssFish       += n
        case .smokedAbyssFishHigh:   smokedAbyssFishHigh   += n
        case .smallPotion:           smallPotion           += n
        case .mediumPotion:          mediumPotion          += n
        }
    }

    @discardableResult
    func use(of type: ConsumableType) -> Bool {
        guard amount(of: type) > 0 else { return false }
        add(-1, of: type)
        return true
    }
}
