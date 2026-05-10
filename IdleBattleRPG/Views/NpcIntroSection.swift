// NpcIntroSection.swift
// V10-1 NPC 首次對話 Section
//
// 行為：
//   首次開啟（hasSeenIntro == false）→ 顯示對話氣泡，點「明白了」直接標記已看過（無命名步驟）
//   已看過後 → 不顯示任何內容。命名資料保留，但 V10-4A 先隱藏改名入口。

import SwiftUI
import SwiftData

struct NpcIntroSection: View {

    let actorKey: String

    @Query private var players: [PlayerStateModel]
    @Environment(\.modelContext) private var context

    private var player: PlayerStateModel? { players.first }
    private var introDef: NpcIntroDef? { NpcIntroDef.find(actorKey: actorKey) }

    private var hasSeenIntro: Bool {
        player?.seenNpcIntroKeys.contains(actorKey) == true
    }

    var body: some View {
        if !hasSeenIntro, let def = introDef {
            Section {
                dialogueBubble(def: def)
            }
        }
    }

    // MARK: - 對話氣泡（首次開啟，點「明白了」直接完成）

    private func dialogueBubble(def: NpcIntroDef) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                Text(def.introLine)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("明白了") {
                    markSeen()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private

    private func markSeen() {
        guard let player else { return }
        player.markNpcIntroSeen(for: actorKey)
        try? context.save()
    }
}
