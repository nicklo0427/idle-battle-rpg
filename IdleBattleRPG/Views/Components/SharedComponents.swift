// SharedComponents.swift
// 全域共用 UI 元件 — 消除 View 層的元件重複
//
// 取代：
//   - BaseView / GathererDetailSheet 各自定義的 tierBadge()
//   - BaseView.NPCRowButtonStyle ≡ GathererDetailSheet.GathererDispatchButtonStyle
//   - BaseView / AdventureView / GathererDetailSheet 各自定義的 taskProgress()

import SwiftUI

// MARK: - TutorialRichText

enum TutorialHighlightKind {
    case action
    case location
    case equipment
    case material

    var color: Color {
        switch self {
        case .action:    return .orange
        case .location:  return .green
        case .equipment: return .blue
        case .material:  return .brown
        }
    }
}

struct TutorialTextRun {
    let text: String
    let highlight: TutorialHighlightKind?

    static func plain(_ text: String) -> TutorialTextRun {
        TutorialTextRun(text: text, highlight: nil)
    }

    static func action(_ text: String) -> TutorialTextRun {
        TutorialTextRun(text: text, highlight: .action)
    }

    static func location(_ text: String) -> TutorialTextRun {
        TutorialTextRun(text: text, highlight: .location)
    }

    static func equipment(_ text: String) -> TutorialTextRun {
        TutorialTextRun(text: text, highlight: .equipment)
    }

    static func material(_ text: String) -> TutorialTextRun {
        TutorialTextRun(text: text, highlight: .material)
    }
}

struct TutorialRichText: View {
    let runs: [TutorialTextRun]
    var font: Font = .subheadline
    var plainColor: Color = .primary

    var body: some View {
        Text(attributedText)
            .font(font)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributedText: AttributedString {
        var result = AttributedString("")
        for run in runs {
            var segment = AttributedString(run.text)
            segment.foregroundColor = run.highlight?.color ?? plainColor
            if run.highlight != nil {
                segment.inlinePresentationIntent = .stronglyEmphasized
            }
            result += segment
        }
        return result
    }
}

// MARK: - SmoothLinearProgressBar

struct SmoothLinearProgressBar: View {

    private let fixedProgress: Double?
    private let task: TaskModel?
    var tint: Color = .accentColor
    var trackColor: Color? = nil
    var height: CGFloat = 5

    init(value: Double, total: Double = 1.0, tint: Color = .accentColor, trackColor: Color? = nil, height: CGFloat = 5) {
        self.fixedProgress = total > 0 ? value / total : 1.0
        self.task = nil
        self.tint = tint
        self.trackColor = trackColor
        self.height = height
    }

    init(task: TaskModel, tint: Color = .accentColor, trackColor: Color? = nil, height: CGFloat = 5) {
        self.fixedProgress = nil
        self.task = task
        self.tint = tint
        self.trackColor = trackColor
        self.height = height
    }

    var body: some View {
        Group {
            if let task {
                TimelineView(.animation) { context in
                    accessibleBar(progress: task.progress(relativeTo: context.date))
                }
            } else {
                accessibleBar(progress: fixedProgress ?? 0)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("進度")
    }

    private func accessibleBar(progress: Double) -> some View {
        bar(progress: progress)
            .accessibilityValue("\(Int(clamped(progress) * 100))%")
    }

    private func bar(progress: Double) -> some View {
        GeometryReader { proxy in
            let normalized = clamped(progress)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill((trackColor ?? tint).opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: max(CGFloat.zero, proxy.size.width * CGFloat(normalized)))
            }
            .animation(.linear(duration: 0.08), value: normalized)
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
}

// MARK: - NPCPortraitView
//
// 顯示 NPC WebP 圖像的固定舞台。外框可以維持卡片圓角，
// 但圖片本身用 scaledToFit，避免 bust portrait 被裁掉。

struct NPCPortraitView: View {

    let imageName: String
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 6
    var imageOpacity: Double = 1.0
    var fillWidth: Bool = false
    var backgroundColor: Color = Color(.tertiarySystemGroupedBackground)

    var body: some View {
        Group {
            if fillWidth {
                portraitContent
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            } else {
                portraitContent
                    .frame(width: width, height: height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var portraitContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)

            Image(webp: imageName)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .opacity(imageOpacity)
        }
    }
}

// MARK: - NPCDetailHeaderSection

struct NPCDetailHeaderSection: View {

    let actorKey: String
    let fallbackName: String
    let roleName: String
    let imageName: String
    let color: Color
    let player: PlayerStateModel?
    let currentTier: Int
    var statusTitle: String = "閒置"
    var statusColor: Color = .secondary
    var metricText: String? = nil
    var metricColor: Color = .secondary
    var dialogueTextOverride: String? = nil
    var dialogueRichTextOverride: [TutorialTextRun]? = nil
    let onGrowth: () -> Void
    let onIntroSeen: () -> Void

    private var displayName: String {
        player?.npcDisplayName(for: actorKey) ?? fallbackName
    }

    private var hasSeenIntro: Bool {
        player?.seenNpcIntroKeys.contains(actorKey) == true
    }

    private var introDef: NpcIntroDef? {
        NpcIntroDef.find(actorKey: actorKey)
    }

    private var resolvedMetricText: String {
        if let metricText { return metricText }
        return currentTier > 0 ? "養成加成已啟用" : "尚無養成加成"
    }

    private var resolvedMetricColor: Color {
        if metricText != nil { return metricColor }
        return currentTier > 0 ? color : .secondary
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            NPCPortraitView(
                                imageName: imageName,
                                width: 112,
                                height: 112,
                                cornerRadius: 14,
                                padding: 8
                            )

                            statusCapsule
                                .padding(6)
                        }
                        .overlay(alignment: .topLeading) {
                            TierBadgeView(tier: currentTier, alwaysShow: true, color: color)
                                .padding(6)
                        }

                        VStack(spacing: 5) {
                            Text(roleName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Text(resolvedMetricText)
                                .font(.caption2)
                                .foregroundStyle(resolvedMetricColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Button {
                            onGrowth()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text("狀態及養成")
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-90))
                            }
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(color.opacity(0.12))
                            .foregroundStyle(color)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)

                        dialogueBubble
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statusCapsule: some View {
        Text(statusTitle)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial)
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var dialogueBubble: some View {
        let text = dialogueTextOverride ?? (hasSeenIntro
            ? (introDef?.shortLine ?? "交給我吧。")
            : (introDef?.introLine ?? "交給我吧。"))

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                if let dialogueRichTextOverride {
                    TutorialRichText(runs: dialogueRichTextOverride, font: .subheadline)
                } else {
                    Text(text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if dialogueTextOverride == nil && dialogueRichTextOverride == nil && !hasSeenIntro {
                HStack {
                    Spacer()
                    Button("明白了", action: onIntroSeen)
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

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
