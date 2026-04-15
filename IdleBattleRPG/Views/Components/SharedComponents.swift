// SharedComponents.swift
// 全域共用 UI 元件 — 消除 View 層的元件重複
//
// 取代：
//   - BaseView / GathererDetailSheet 各自定義的 tierBadge()
//   - BaseView.NPCRowButtonStyle ≡ GathererDetailSheet.GathererDispatchButtonStyle
//   - BaseView / AdventureView / GathererDetailSheet 各自定義的 taskProgress()

import SwiftUI

// MARK: - TierBadgeView
//
// 顯示 NPC Tier 等級徽章。
//
// 使用範例：
//   TierBadgeView(tier: tier)                              // BaseView（T0 不顯示，accentColor）
//   TierBadgeView(tier: tier, alwaysShow: true, color: .green)  // GathererDetailSheet（T0 顯示）

struct TierBadgeView: View {

    let tier: Int

    /// 為 true 時即使 tier == 0 也顯示（GathererDetailSheet 用）
    var alwaysShow: Bool = false

    /// 非零 Tier 的前景色
    var color: Color = .accentColor

    var body: some View {
        if tier > 0 || alwaysShow {
            Text("T\(tier)")
                .font(.caption2.bold())
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background((tier > 0 ? color : Color.gray).opacity(0.15))
                .foregroundStyle(tier > 0 ? color : Color.secondary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - NPCDispatchButtonStyle
//
// 合併：
//   - BaseView.NPCRowButtonStyle（有 enabled 參數）
//   - GathererDetailSheet.GathererDispatchButtonStyle（無 enabled，等同 enabled = true）
//
// enabled = false（忙碌中）：按壓無視覺變化，強調不可互動。

struct NPCDispatchButtonStyle: ButtonStyle {

    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(enabled && configuration.isPressed ? 0.55 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - TaskModel + progress(relativeTo:)
//
// 取代三個 View 中各自定義的 taskProgress(_:) 私有函式。
// 可在沒有 AppState 的測試環境中使用。

extension TaskModel {

    /// 任務進度 [0.0, 1.0]
    func progress(relativeTo tick: Date) -> Double {
        let total   = endsAt.timeIntervalSince(startedAt)
        let elapsed = tick.timeIntervalSince(startedAt)
        guard total > 0 else { return 1.0 }
        return min(1.0, max(0.0, elapsed / total))
    }
}
