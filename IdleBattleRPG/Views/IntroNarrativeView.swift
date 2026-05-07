// IntroNarrativeView.swift
// V10-1 開場敘事屏：3 張全屏卡片，玩家第一次啟動時顯示

import SwiftUI
import SwiftData

struct IntroNarrativeView: View {

    @Environment(\.modelContext) private var context
    @Query private var players: [PlayerStateModel]

    var onFinished: () -> Void

    @State private var currentPage = 0

    private let slides: [Slide] = [
        Slide(
            icon:    "rays",
            title:   "廢墟之中",
            body:    "你在黑暗中甦醒。身旁是破碎的石柱與覆滿青苔的廢牆——這裡曾是一座繁華的古城，如今只剩殘骸。你不記得自己是怎麼倒下的，只知道手邊還攥著一把生鏽的短劍。"
        ),
        Slide(
            icon:    "house.lodge.fill",
            title:   "邊境要塞",
            body:    "他們發現了你——一群在荒野邊緣討生活的人。採集者、鑄造師、商人，還有一個話不多的農夫。他們把你帶回了這座簡陋的要塞，替你包紮傷口，等你甦醒。"
        ),
        Slide(
            icon:    "figure.fencing",
            title:   "重新出發",
            body:    "地下城的陰影正在蔓延。要塞需要更多資源，而你需要找回自己的力量。你曾是什麼人，將決定你如何走下去。"
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 跳過按鈕
                HStack {
                    Spacer()
                    Button("跳過") { finish() }
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.subheadline)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                }

                Spacer()

                // 卡片內容
                let slide = slides[currentPage]
                VStack(spacing: 28) {
                    Image(systemName: slide.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(slide.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(slide.body)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                Spacer()

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(slides.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 20)

                // 下一頁 / 繼續
                Button {
                    if currentPage < slides.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(currentPage < slides.count - 1 ? "下一頁" : "繼續")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func finish() {
        guard let player = players.first else { onFinished(); return }
        player.hasSeenIntro = true
        try? context.save()
        onFinished()
    }
}

// MARK: - Slide Model

private struct Slide {
    let icon:  String
    let title: String
    let body:  String
}
