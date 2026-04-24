// ConsumableType.swift
// 消耗品類型列舉（料理 + 藥水）

import Foundation

enum ConsumableType: String, CaseIterable, Codable {
    // 廚師料理（普通品質）
    case fishStew
    case herbFishSoup
    case abyssSoup
    case smokedAbyssFish

    // 廚師料理（高級品質，25% RNG 機率產出）
    case fishStewHigh
    case herbFishSoupHigh
    case abyssSoupHigh
    case smokedAbyssFishHigh

    // 藥水（T04 新增後使用）
    case smallPotion
    case mediumPotion

    var displayName: String {
        switch self {
        case .fishStew:              return "魚肉燉鍋"
        case .fishStewHigh:          return "★魚肉燉鍋"
        case .herbFishSoup:          return "藥草魚湯"
        case .herbFishSoupHigh:      return "★藥草魚湯"
        case .abyssSoup:             return "深淵燉菜"
        case .abyssSoupHigh:         return "★深淵燉菜"
        case .smokedAbyssFish:       return "煙燻深淵魚"
        case .smokedAbyssFishHigh:   return "★煙燻深淵魚"
        case .smallPotion:           return "小型藥水"
        case .mediumPotion:          return "中型藥水"
        }
    }

    var icon: String {
        switch self {
        case .fishStew, .fishStewHigh:                 return "🍲"
        case .herbFishSoup, .herbFishSoupHigh:         return "🍵"
        case .abyssSoup, .abyssSoupHigh:               return "🫕"
        case .smokedAbyssFish, .smokedAbyssFishHigh:   return "🐟"
        case .smallPotion:                             return "🧪"
        case .mediumPotion:                            return "⚗️"
        }
    }

    var isCuisine: Bool {
        switch self {
        case .fishStew, .fishStewHigh, .herbFishSoup, .herbFishSoupHigh,
             .abyssSoup, .abyssSoupHigh, .smokedAbyssFish, .smokedAbyssFishHigh:
            return true
        default: return false
        }
    }

    var isPotion: Bool { !isCuisine }

    var isHighQuality: Bool { rawValue.hasSuffix("High") }

    var highQualityVariant: ConsumableType? {
        guard isCuisine, !isHighQuality else { return nil }
        return ConsumableType(rawValue: rawValue + "High")
    }

    /// 對應的 CuisineDef.key（snake_case）；非料理類型或無映射時回傳 nil
    var cuisineDefKey: String? {
        guard isCuisine else { return nil }
        let base = isHighQuality ? String(rawValue.dropLast(4)) : rawValue
        switch base {
        case "fishStew":         return "fish_stew"
        case "herbFishSoup":     return "herb_fish_soup"
        case "abyssSoup":        return "abyss_soup"
        case "smokedAbyssFish":  return "smoked_abyss_fish"
        default:                 return nil
        }
    }
}
