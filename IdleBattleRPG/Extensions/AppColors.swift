// AppColors.swift
// 全域顏色擴充 — 消除 View 層的顏色重複
//
// 取代：
//   - AdventureView / FloorDetailSheet 重複定義的 regionColor(_:)
//   - AdventureView / FloorDetailSheet 重複定義的 winRateColor(_:)
//   - CharacterView 內嵌 6 次的 Color(red: 1.0, green: 0.78, blue: 0.2)

import SwiftUI

// MARK: - SF Symbols 動畫輔助

extension View {
    /// 採集任務進行中的動畫：iOS 18+ .breathe，iOS 17 fallback .pulse
    @ViewBuilder
    func gatheringSymbolEffect(isActive: Bool) -> some View {
        if #available(iOS 18, *) {
            self.symbolEffect(.breathe, isActive: isActive)
        } else {
            self.symbolEffect(.pulse, isActive: isActive)
        }
    }
}

extension Color {

    // MARK: - 地下城區域主題色（T01 差異化色調）

    /// 依地下城區域 key 回傳對應主題色
    static func dungeonRegion(_ key: String) -> Color {
        switch key {
        case "wildland":       return .orange
        case "abandoned_mine": return Color(red: 0.45, green: 0.6, blue: 0.75)  // 藍灰
        case "ancient_ruins":  return .purple
        case "sunken_city":    return .indigo
        default:               return .blue
        }
    }

    // MARK: - 裝備稀有度色

    /// Boss 武器浮動值高亮色（金黃）— SettlementSheet 專用，與稀有度色系無關
    static let rarityRefined   = Color(red: 1.0, green: 0.78, blue: 0.20)
    /// 精良（Fine）稀有度：綠色
    static let rarityFine      = Color.green
    /// 稀有（Rare）稀有度：藍色
    static let rarityRare      = Color.blue
    /// 史詩（Epic）稀有度：紫色
    static let rarityEpic      = Color.purple
    /// 傳說（Legendary）稀有度：金橙色
    static let rarityLegendary = Color(red: 1.0, green: 0.55, blue: 0.0)
    /// 神話（Mythic）稀有度：深紅色
    static let rarityMythic    = Color(red: 0.75, green: 0.05, blue: 0.15)

    // MARK: - 勝率色


    /// 依勝率百分比回傳語意色（綠 / 橙 / 紅）
    static func winRate(_ rate: Int) -> Color {
        switch rate {
        case 70...:    return .green
        case 40..<70:  return .orange
        default:       return .red
        }
    }
}

// MARK: - EquipmentRarity 顯示色（V8-1）

extension EquipmentRarity {
    /// 稀有度對應強調色；common 回傳 .primary（不強調）
    var displayColor: Color {
        switch self {
        case .common:    return .primary
        case .refined:   return .rarityFine
        case .rare:      return .rarityRare
        case .epic:      return .rarityEpic
        case .legendary: return .rarityLegendary
        case .mythic:    return .rarityMythic
        }
    }
    /// common 以外皆有強調色
    var hasAccent: Bool { self != .common }
}
