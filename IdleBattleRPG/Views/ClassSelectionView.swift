// ClassSelectionView.swift
// V6-1 職業選擇畫面（重構：Icon 選擇列 + 詳情面板 + 確認按鈕）
//
// 顯示時機：player.classKey == ""（新遊戲 或 舊存檔升級後）
// 選定後不可更改，透過 BaseView 的 .fullScreenCover 綁定觸發

import SwiftUI
import SwiftData

struct ClassSelectionView: View {

    @Environment(\.modelContext) private var context
    @Query private var players: [PlayerStateModel]

    /// 目前選中（可自由切換）的職業，預設第一個
    @State private var selectedClass: ClassDef = ClassDef.all[0]
    /// 顯示確認 Dialog
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 1. 副標 + 警告
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // 2. Icon 選擇列
                classIconRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // 3. 詳情面板
                ScrollView {
                    classDetailPanel(selectedClass)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // 4. 確認按鈕（固定底部）
                confirmButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .navigationTitle("選擇職業")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("踏上冒險前，選擇你的英雄路線。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("一旦選定，不可更換。")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Icon 選擇列

    private var classIconRow: some View {
        HStack(spacing: 12) {
            ForEach(ClassDef.all, id: \.key) { cls in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedClass = cls
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(selectedClass.key == cls.key
                                      ? cls.themeColor.opacity(0.25)
                                      : cls.themeColor.opacity(0.10))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle().strokeBorder(
                                        cls.themeColor,
                                        lineWidth: selectedClass.key == cls.key ? 2.5 : 0
                                    )
                                )
                            Image(systemName: cls.iconName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(cls.themeColor)
                        }
                        Text(cls.name)
                            .font(.caption2)
                            .fontWeight(selectedClass.key == cls.key ? .semibold : .regular)
                            .foregroundStyle(
                                selectedClass.key == cls.key ? cls.themeColor : .secondary
                            )
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 詳情面板

    private func classDetailPanel(_ cls: ClassDef) -> some View {
        VStack(alignment: .leading, spacing: 14) {

            // 名稱 + 描述
            VStack(alignment: .leading, spacing: 6) {
                Text(cls.name)
                    .font(.title2.bold())
                    .foregroundStyle(cls.themeColor)
                Text(cls.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 屬性加成 + 戰力
            HStack(spacing: 8) {
                Text(cls.bonusSummary)
                    .font(.subheadline.bold())
                    .foregroundStyle(cls.themeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(cls.themeColor.opacity(0.12))
                    .clipShape(Capsule())

                let powerDelta = cls.estimatedPowerBonus
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(powerDelta > 0 ? "戰力 +\(powerDelta)" : "敏捷 / 暴擊率提升")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // 技能預覽
            let skills = SkillDef.unlocked(classKey: cls.key, atLevel: 3)
            if let skill = skills.first {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Lv.3 技能", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(skill.name)　\(skill.effectSummary)")
                        .font(.subheadline)
                        .foregroundStyle(cls.themeColor)
                }
            }

            Divider()

            // 背景故事
            Text(cls.backstory)
                .font(.callout)
                .italic()
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(selectedClass.themeColor.opacity(0.35), lineWidth: 1.5)
        )
    }

    // MARK: - 確認按鈕

    private var confirmButton: some View {
        Button {
            showConfirm = true
        } label: {
            Text("選擇「\(selectedClass.name)」，開始冒險！")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(selectedClass.themeColor)
        .confirmationDialog(
            "確定選擇「\(selectedClass.name)」嗎？",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("確認，開始冒險！") {
                confirmSelection(selectedClass)
            }
            Button("再想想", role: .cancel) { }
        } message: {
            Text("職業選定後無法更換。\n\(selectedClass.bonusSummary)")
        }
    }

    // MARK: - 確認選擇

    private func confirmSelection(_ classDef: ClassDef) {
        guard let player = players.first else { return }
        player.classKey = classDef.key
        // 裝備由 T06 教程鑄造結算時授予，此處只存 classKey
        try? context.save()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self, DungeonProgressionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let player = PlayerStateModel()
    container.mainContext.insert(player)
    return ClassSelectionView()
        .modelContainer(container)
}
