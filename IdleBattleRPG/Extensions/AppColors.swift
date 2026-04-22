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

    // MARK: - 精良裝備金色（T03）

    /// 精良（refined）稀有度的金黃色
    static let rarityRefined = Color(red: 1.0, green: 0.78, blue: 0.2)

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
