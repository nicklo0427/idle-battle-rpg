// OnboardingBannerView.swift
// 首次引導 Banner（3 步驟）
//
// 顯示時機：PlayerStateModel.onboardingStep < 3
// 步驟說明：
//   0 → 採集：指引玩家點採集者（實際派出後自動推進）
//   1 → 鑄造：指引玩家點鑄造師（實際開始鑄造後自動推進）
//   2 → 冒險：指引玩家切換到冒險頁（實際出征後自動推進）
//   3 → 完成，Banner 消失
//
// 注意：步驟推進由真實行為驅動（不再有手動「下一步」按鈕）。

import SwiftUI

struct OnboardingBannerView: View {

    let step:      Int
    let onAdvance: () -> Void   // 保留簽名相容，但不再使用

    var body: some View {
        if step == 0 {
            stepSection(
                icon:      "leaf.fill",
                iconColor: .green,
                headline:  "先派遣採集者",
                body: [
                    .plain("在"),
                    .location("基地的採集者營地"),
                    .plain("找到"),
                    .action("伐木工阿森"),
                    .plain("，派他採集"),
                    .material("木材"),
                    .plain("，準備打造"),
                    .equipment("初始武器"),
                    .plain("。"),
                ],
                hint:      "派出採集者後自動進入下一步",
                tint:      .green
            )
        } else if step == 1 {
            stepSection(
                icon:      "hammer.fill",
                iconColor: .orange,
                headline:  "委派鑄造師",
                body: [
                    .plain("在"),
                    .location("基地的生產者小屋"),
                    .plain("找到"),
                    .action("鑄造師老鐵"),
                    .plain("，用"),
                    .material("木材"),
                    .plain("打造"),
                    .equipment("初始武器"),
                    .plain("。"),
                ],
                hint:      "開始鑄造後自動進入下一步",
                tint:      .orange
            )
        } else if step == 2 {
            stepSection(
                icon:      "map.fill",
                iconColor: .purple,
                headline:  "前往冒險頁出征",
                body: [
                    .plain("到"),
                    .action("冒險"),
                    .plain("頁進入"),
                    .location("穀倉前道"),
                    .plain("，開始第一次"),
                    .action("出征"),
                    .plain("。"),
                ],
                hint:      "出征後引導自動完成",
                tint:      .purple
            )
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func stepSection(
        icon: String,
        iconColor: Color,
        headline: String,
        body: [TutorialTextRun],
        hint: String,
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
                    TutorialStepBadge(step: step, total: 3, tint: tint)
                }

                // 說明文字
                TutorialRichText(runs: body, font: .subheadline, plainColor: .secondary)

                // 行動提示（取代原有「下一步」按鈕）
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                    Text(hint)
                        .font(.caption)
                }
                .foregroundStyle(tint.opacity(0.8))
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
