// NpcIntroSection.swift
// V10-1 NPC 首次對話 + 命名 Section
//
// 嵌入各 NPC Sheet 的 List 頂部 Section：
//   首次開啟 → 顯示對話氣泡
//   點「明白了」→ 顯示命名輸入框
//   確認/跳過 → Section 消失，seenNpcIntroKeys 加入該 actorKey

import SwiftUI
import SwiftData

struct NpcIntroSection: View {

    let actorKey: String

    @Query private var players: [PlayerStateModel]
    @Environment(\.modelContext) private var context

    @State private var showNaming = false
    @State private var nameInput  = ""
    @FocusState private var nameFocused: Bool

    private var player: PlayerStateModel? { players.first }

    private var introDef: NpcIntroDef? { NpcIntroDef.find(actorKey: actorKey) }

    private var hasSeenIntro: Bool {
        player?.seenNpcIntroKeys.contains(actorKey) == true
    }

    var body: some View {
        if !hasSeenIntro, let def = introDef {
            Section {
                if !showNaming {
                    dialogueBubble(def: def)
                } else {
                    namingRow(def: def)
                }
            }
        }
    }

    // MARK: - 對話氣泡

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
                    withAnimation { showNaming = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        nameFocused = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 命名輸入

    private func namingRow(def: NpcIntroDef) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("幫他取個名字吧")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(def.defaultName, text: $nameInput)
                .focused($nameFocused)
                .font(.body)
                .onChange(of: nameInput) { _, v in
                    if v.count > 10 { nameInput = String(v.prefix(10)) }
                }

            HStack(spacing: 12) {
                Button("跳過") { finish(customName: nil) }
                    .foregroundStyle(.secondary)

                Spacer()

                Button("確認") {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
                    finish(customName: trimmed.isEmpty ? nil : trimmed)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private

    private func finish(customName: String?) {
        guard let player else { return }
        if let name = customName {
            player.setCustomNpcName(name, for: actorKey)
        }
        player.markNpcIntroSeen(for: actorKey)
        try? context.save()
    }
}
