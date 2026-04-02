// AdventureView.swift
// 冒險 Tab — Phase 9
//
// 顯示內容：
//   - 英雄當前戰力
//   - 地下城區域卡片（全展開，不折疊）
//     - 解鎖狀態、推薦戰力、掉落預覽
//     - 時長 Chip 選擇（15 分 / 1 小時 / 8 小時）
//     - 「出發」按鈕 → 建立地下城任務
//   - 英雄在地下城中：顯示目前區域與即時剩餘時間倒數，其他區域出發按鈕 disabled

import SwiftUI
import SwiftData

struct AdventureView: View {

    let appState: AppState

    @Query private var players:    [PlayerStateModel]
    @Query private var equipments: [EquipmentModel]
    @Query private var tasks:      [TaskModel]

    @State private var viewModel = AdventureViewModel()
    /// 各區域選擇的出征時長（key = area.key）
    @State private var selectedDurations: [String: Int] = [:]

    @State private var errorMessage: String?
    @State private var showError = false

    @Environment(\.modelContext) private var context

    // MARK: - 計算屬性

    private var heroStats: HeroStats? {
        guard let player = players.first else { return nil }
        let equipped = equipments.filter { $0.isEquipped }
        return HeroStatsService.compute(player: player, equipped: equipped)
    }

    private var activeDungeonTask: TaskModel? {
        viewModel.dungeonTask(from: tasks)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // ── 英雄戰力摘要 ─────────────────────────────────────
                Section("英雄戰力") {
                    if let stats = heroStats {
                        HStack {
                            Label("當前戰力", systemImage: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Spacer()
                            Text("\(stats.power)")
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    } else {
                        Text("⚠️ 尚無英雄資料").foregroundStyle(.red)
                    }
                }

                // ── 英雄在地下城中 Banner ────────────────────────────
                if let dungeonTask = activeDungeonTask,
                   let area = viewModel.currentArea(from: tasks) {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("正在出征：\(area.name)")
                                    .fontWeight(.semibold)
                                Text(TaskCountdown.remaining(for: dungeonTask, relativeTo: appState.tick))
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                                    .monospacedDigit()
                            }
                            Spacer()
                            Text("出征中")
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.purple.opacity(0.12))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 2)
                    }
                }

                // ── 首次出征提示（只在加速未使用前顯示）────────────────
                if let player = players.first, !player.hasUsedFirstDungeonBoost {
                    Section {
                        Label(
                            "首次出征特快！選 15 分鐘出征，只需 30 秒即可完成，固定 5 場戰鬥。",
                            systemImage: "bolt.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                    }
                }

                // ── 地下城區域列表 ───────────────────────────────────
                Section("地下城區域") {
                    ForEach(viewModel.allAreas(), id: \.key) { area in
                        dungeonAreaCard(area: area)
                    }
                }
            }
            .navigationTitle("冒險")
            .alert("無法出征", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }

    // MARK: - Dungeon Area Card

    @ViewBuilder
    private func dungeonAreaCard(area: DungeonAreaDef) -> some View {
        let accessible = viewModel.isAccessible(area, heroStats: heroStats)
        let playerBusy = activeDungeonTask != nil
        let selectedDuration = selectedDurations[area.key] ?? AppConstants.DungeonDuration.short

        VStack(alignment: .leading, spacing: 8) {

            // 標題行
            HStack {
                Image(systemName: accessible ? "lock.open.fill" : "lock.fill")
                    .foregroundStyle(accessible ? .green : .secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(area.name)
                        .fontWeight(accessible ? .semibold : .regular)
                        .foregroundStyle(accessible ? .primary : .secondary)
                    Text(viewModel.lockLabel(for: area))
                        .font(.caption)
                        .foregroundStyle(accessible ? .green : .orange)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("推薦戰力 \(area.recommendedPower)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let power = heroStats?.power {
                        let rate = Int(HeroStats.winRate(power: power, recommendedPower: area.recommendedPower) * 100)
                        Text("勝率 \(rate)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(winRateColor(rate))
                    }
                }
            }

            // 掉落預覽
            HStack(spacing: 6) {
                ForEach(area.dropTable, id: \.material) { entry in
                    Text("\(entry.material.icon) \(entry.material.displayName)")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text("💰 金幣")
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            if accessible {
                // 時長 Chip
                HStack(spacing: 8) {
                    ForEach(AppConstants.DungeonDuration.all, id: \.self) { duration in
                        durationChip(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            onSelect: { selectedDurations[area.key] = duration }
                        )
                    }
                }

                // 出發按鈕
                Button {
                    startDungeon(area: area, durationSeconds: selectedDuration)
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text(playerBusy ? "英雄出征中" : "出發")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(playerBusy ? Color.secondary.opacity(0.15) : Color.purple.opacity(0.15))
                    .foregroundStyle(Color.purple.opacity(playerBusy ? 0.4 : 1.0))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(playerBusy)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(accessible ? 1.0 : 0.6)
    }

    // MARK: - Duration Chip

    @ViewBuilder
    private func durationChip(duration: Int, isSelected: Bool, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            Text(AppConstants.DungeonDuration.displayName(for: duration))
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(isSelected ? Color.purple.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? .purple : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Helpers

    private func winRateColor(_ rate: Int) -> Color {
        switch rate {
        case 70...: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    private func startDungeon(area: DungeonAreaDef, durationSeconds: Int) {
        guard let stats = heroStats else {
            errorMessage = "找不到英雄資料"
            showError = true
            return
        }
        let result = viewModel.startDungeon(
            areaKey: area.key,
            durationSeconds: durationSeconds,
            heroStats: stats,
            context: context
        )
        switch result {
        case .success:
            break
        case .failure(let error):
            errorMessage = error.errorDescription
            showError = true
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    AdventureView(appState: AppState(context: container.mainContext))
        .modelContainer(container)
}
