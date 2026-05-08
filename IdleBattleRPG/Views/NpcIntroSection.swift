// NpcIntroSection.swift
// V10-1 NPC 首次對話 Section
//
// 行為：
//   首次開啟（hasSeenIntro == false）→ 顯示對話氣泡，點「明白了」直接標記已看過（無命名步驟）
//   教程完成後（onboardingStep >= 8）+ 已看過 → 顯示改名入口（OB 成就解鎖）
//   其他情況 → 不顯示任何內容

import SwiftUI
import SwiftData

struct NpcIntroSection: View {

    let actorKey: String

    @Query private var players: [PlayerStateModel]
    @Environment(\.modelContext) private var context

    @State private var showRenaming = false
    @State private var nameInput    = ""
    @FocusState private var nameFocused: Bool

    private var player: PlayerStateModel? { players.first }
    private var introDef: NpcIntroDef? { NpcIntroDef.find(actorKey: actorKey) }

    private var hasSeenIntro: Bool {
        player?.seenNpcIntroKeys.contains(actorKey) == true
    }

    private var namingUnlocked: Bool {
        (player?.onboardingStep ?? 0) >= 8
    }

    var body: some View {
        if !hasSeenIntro, let def = introDef {
            Section {
                dialogueBubble(def: def)
            }
        } else if hasSeenIntro && namingUnlocked, let def = introDef {
            Section {
                if showRenaming {
                    renamingRow(def: def)
                } else {
                    renameEntryRow(def: def)
                }
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

    // MARK: - 改名入口（教程完成後，預設收合）

    private func renameEntryRow(def: NpcIntroDef) -> some View {
        let currentName = player?.npcDisplayName(for: actorKey) ?? def.defaultName
        Button {
            nameInput = player?.customNpcName(for: actorKey) ?? ""
            withAnimation { showRenaming = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { nameFocused = true }
        } label: {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("修改名字")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currentName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 命名輸入列

    private func renamingRow(def: NpcIntroDef) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(def.defaultName, text: $nameInput)
                .focused($nameFocused)
                .font(.body)
                .onChange(of: nameInput) { _, v in
                    if v.count > 10 { nameInput = String(v.prefix(10)) }
                }

            HStack(spacing: 12) {
                Button("取消") {
                    withAnimation { showRenaming = false }
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("確認") {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
                    saveName(trimmed.isEmpty ? nil : trimmed)
                    withAnimation { showRenaming = false }
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

    private func saveName(_ name: String?) {
        guard let player else { return }
        if let name {
            player.setCustomNpcName(name, for: actorKey)
        } else {
            player.setCustomNpcName("", for: actorKey)
        }
        try? context.save()
    }
}
