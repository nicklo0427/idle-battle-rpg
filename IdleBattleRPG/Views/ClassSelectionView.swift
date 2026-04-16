// ClassSelectionView.swift
// V6-1 職業選擇畫面
//
// 顯示時機：player.classKey == ""（新遊戲 或 舊存檔升級後）
// 選定後不可更改，透過 BaseView 的 .fullScreenCover 綁定觸發

import SwiftUI
import SwiftData

struct ClassSelectionView: View {

    @Environment(\.modelContext) private var context
    @Query private var players: [PlayerStateModel]

    /// 目前選中（按下但尚未確認）的職業
    @State private var pendingClass: ClassDef?
    /// 顯示確認 Alert
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    classGrid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("選擇職業")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .padding(.top, 16)

            Text("踏上冒險前，選擇你的英雄路線。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("一旦選定，不可更換。")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - 2×2 職業卡片網格

    private var classGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(ClassDef.all, id: \.key) { classDef in
                classCard(classDef)
            }
        }
    }

    @ViewBuilder
    private func classCard(_ classDef: ClassDef) -> some View {
        Button {
            pendingClass = classDef
            showConfirm  = true
        } label: {
            VStack(spacing: 10) {
                // 圖示
                ZStack {
                    Circle()
                        .fill(classDef.themeColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: classDef.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(classDef.themeColor)
                }

                // 職業名稱
                Text(classDef.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // 簡介
                Text(classDef.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // 基礎加成
                Text(classDef.bonusSummary)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(classDef.themeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(classDef.themeColor.opacity(0.12))
                    .clipShape(Capsule())

                // 技能預覽（前 2 個技能名稱）
                let previewSkills = ClassDef.all
                    .first { $0.key == classDef.key }
                    .map { SkillDef.unlocked(classKey: $0.key, atLevel: 3) } ?? []
                if let firstSkill = previewSkills.first {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.7))
                        Text("Lv.3：\(firstSkill.name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(classDef.themeColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "確定選擇「\(pendingClass?.name ?? "")」嗎？",
            isPresented: Binding(
                get: { showConfirm && pendingClass?.key == classDef.key },
                set: { if !$0 { showConfirm = false } }
            ),
            titleVisibility: .visible
        ) {
            Button("確認，開始冒險！") {
                confirmSelection(classDef)
            }
            Button("再想想", role: .cancel) {
                pendingClass = nil
            }
        } message: {
            Text("職業選定後無法更換。\n\(classDef.bonusSummary)")
        }
    }

    // MARK: - 確認選擇

    private func confirmSelection(_ classDef: ClassDef) {
        guard let player = players.first else { return }
        player.classKey = classDef.key
        try? context.save()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self, DungeonProgressionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    // 建立尚未選職業的玩家
    let player = PlayerStateModel()
    container.mainContext.insert(player)
    return ClassSelectionView()
        .modelContainer(container)
}
