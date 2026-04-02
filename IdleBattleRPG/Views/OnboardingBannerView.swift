// OnboardingBannerView.swift
// 首次引導 Banner（3 步驟）
//
// 顯示時機：PlayerStateModel.onboardingStep < 3
// 步驟說明：
//   0 → 採集：指引玩家點採集者
//   1 → 鑄造：指引玩家點鑄造師（附首件加速提示）
//   2 → 冒險：指引玩家切換到冒險頁（附首次出征加速提示）
//   3 → 完成，Banner 消失
//
// 使用方式（在 List 內直接放置）：
//   OnboardingBannerView(step: player.onboardingStep, onAdvance: { ... })

import SwiftUI

struct OnboardingBannerView: View {

    let step:      Int
    let onAdvance: () -> Void

    var body: some View {
        if step == 0 {
            stepSection(
                badge:       "1 / 3",
                icon:        "leaf.fill",
                iconColor:   .green,
                headline:    "先派遣採集者",
                body:        "點擊下方「採集者」，送出採集任務取得素材。素材是打造裝備的原料！",
                buttonLabel: "下一步",
                tint:        .green
            )
        } else if step == 1 {
            stepSection(
                badge:       "2 / 3",
                icon:        "hammer.fill",
                iconColor:   .orange,
                headline:    "委派鑄造師",
                body:        "點擊「鑄造師」，用素材打造裝備提升戰力。✨ 首件鑄造特快，只需 30 秒！",
                buttonLabel: "下一步",
                tint:        .orange
            )
        } else if step == 2 {
            stepSection(
                badge:       "3 / 3",
                icon:        "map.fill",
                iconColor:   .purple,
                headline:    "前往冒險頁出征",
                body:        "切到底部「冒險」Tab，選地下城出發！⚡ 首次出征特快，只需 30 秒！",
                buttonLabel: "知道了",
                tint:        .purple
            )
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func stepSection(
        badge: String,
        icon: String,
        iconColor: Color,
        headline: String,
        body: String,
        buttonLabel: String,
        tint: Color
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {

                // 標題行
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                    Text(headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(badge)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(tint.opacity(0.15))
                        .foregroundStyle(tint)
                        .clipShape(Capsule())
                }

                // 說明文字
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // 前進按鈕
                HStack {
                    Spacer()
                    Button(buttonLabel) { onAdvance() }
                        .buttonStyle(.borderedProminent)
                        .tint(tint)
                        .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("新手引導", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        OnboardingBannerView(step: 1, onAdvance: {})
    }
}
