// AdventureView.swift
// 冒險 Tab — V2-1 Ticket 04 重構版
//
// 顯示內容：
//   - 英雄當前戰力
//   - 出征中 Banner（含即時倒數）
//   - 首次出征提示（未使用加速時）
//   - 地下城區域列表（DungeonRegionDef，3 區 × 4 層）
//     - 區域卡片可展開 / 收合
//     - 未解鎖區域：灰化，顯示解鎖條件
//     - 點擊已解鎖樓層 → FloorDetailSheet（掉落表、戰力比較、時長選擇、出發）

import SwiftUI
import SwiftData

struct AdventureView: View {

    let appState: AppState

    @Query private var players:    [PlayerStateModel]
    @Query private var equipments: [EquipmentModel]
    @Query private var tasks:      [TaskModel]

    @State private var viewModel         = AdventureViewModel()
    @State private var expandedRegionKey: String? = "wildland"   // 預設展開第一區
    @State private var selectedFloor:    DungeonFloorDef?
    @State private var errorMessage:     String?
    @State private var showError         = false

    @Environment(\.modelContext) private var context

    // MARK: - 計算屬性

    private var heroStats: HeroStats? {
        guard let player = players.first else { return nil }
        return HeroStatsService.compute(player: player, equipped: equipments.filter { $0.isEquipped })
    }

    private var activeDungeonTask: TaskModel? {
        viewModel.dungeonTask(from: tasks)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                heroStatSection
                activeBannerSection
                firstBoostBannerSection
                regionListSection
            }
            .navigationTitle("冒險")
            .sheet(item: $selectedFloor) { floor in
                FloorDetailSheet(
                    floor:              floor,
                    heroStats:          heroStats,
                    activeDungeonTask:  activeDungeonTask,
                    progressionService: appState.progressionService,
                    tick:               appState.tick,
                    onStart: { duration in
                        launchFloor(floor: floor, durationSeconds: duration)
                        selectedFloor = nil
                    }
                )
            }
            .alert("無法出征", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }

    // MARK: - Sections

    private var heroStatSection: some View {
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
    }

    @ViewBuilder
    private var activeBannerSection: some View {
        if let task = activeDungeonTask {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("正在出征：\(viewModel.activeDungeonName(from: tasks) ?? "—")")
                            .fontWeight(.semibold)
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.purple)
                            .monospacedDigit()
                        let progress = taskProgress(task)
                        ProgressView(value: progress)
                            .tint(.blue)
                            .padding(.top, 2)

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
    }

    @ViewBuilder
    private var firstBoostBannerSection: some View {
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
    }

    private var regionListSection: some View {
        ForEach(DungeonRegionDef.all, id: \.key) { region in
            let unlocked  = viewModel.isRegionUnlocked(region.key, service: appState.progressionService)
            let completed = viewModel.isRegionCompleted(region.key, service: appState.progressionService)
            let expanded  = expandedRegionKey == region.key

            Section {
                // 區域標頭
                Button {
                    guard unlocked else { return }
                    expandedRegionKey = expanded ? nil : region.key
                } label: {
                    regionHeader(region: region, unlocked: unlocked, completed: completed, expanded: expanded)
                }
                .buttonStyle(.plain)

                // 樓層列表（已解鎖且展開才顯示）
                if unlocked && expanded {
                    ForEach(region.floors) { floor in
                        floorRow(floor: floor, region: region)
                    }
                }
            }
        }
    }

    // MARK: - Region Header

    @ViewBuilder
    private func regionHeader(
        region: DungeonRegionDef,
        unlocked: Bool,
        completed: Bool,
        expanded: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: unlocked ? (completed ? "checkmark.seal.fill" : "lock.open.fill") : "lock.fill")
                .foregroundStyle(completed ? .green : (unlocked ? .purple : .secondary))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(region.name)
                    .fontWeight(.semibold)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(region.regionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if unlocked {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                regionUnlockLabel(region: region)
            }
        }
        .padding(.vertical, 2)
        .opacity(unlocked ? 1.0 : 0.5)
    }

    @ViewBuilder
    private func regionUnlockLabel(region: DungeonRegionDef) -> some View {
        if let idx = DungeonRegionDef.all.firstIndex(where: { $0.key == region.key }), idx > 0 {
            let prev = DungeonRegionDef.all[idx - 1]
            Text("通關\(prev.name) Boss")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Floor Row

    @ViewBuilder
    private func floorRow(floor: DungeonFloorDef, region: DungeonRegionDef) -> some View {
        let unlocked = viewModel.isFloorUnlocked(
            regionKey: region.key, floorIndex: floor.floorIndex,
            service: appState.progressionService
        )
        let cleared = viewModel.isFloorCleared(
            regionKey: region.key, floorIndex: floor.floorIndex,
            service: appState.progressionService
        )
        let isBusy = activeDungeonTask != nil

        Button {
            guard unlocked else { return }
            selectedFloor = floor
        } label: {
            HStack(spacing: 10) {
                // 樓層序號 / Boss 標記
                ZStack {
                    Circle()
                        .fill(floor.isBossFloor ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.1))
                        .frame(width: 30, height: 30)
                    if floor.isBossFloor {
                        Text("👑").font(.caption)
                    } else {
                        Text("\(floor.floorIndex)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(floor.name)
                            .font(.subheadline)
                            .fontWeight(unlocked ? .medium : .regular)
                            .foregroundStyle(unlocked ? .primary : .secondary)
                        if cleared {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        if floor.isBossFloor, let bossName = floor.bossName {
                            Text(bossName)
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    if !unlocked {
                        Text(floor.floorIndex == 1 ? "區域未解鎖" : "需首通第 \(floor.floorIndex - 1) 層")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    } else {
                        HStack(spacing: 6) {
                            Text("推薦 \(floor.recommendedPower)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if let power = heroStats?.power {
                                let rate = Int(HeroStats.winRate(
                                    power: power,
                                    recommendedPower: floor.recommendedPower
                                ) * 100)
                                Text("勝率 \(rate)%")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(winRateColor(rate))
                            }
                        }
                    }
                }

                Spacer()

                if unlocked {
                    if isBusy {
                        Text("出征中")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 2)
            .opacity(unlocked ? 1.0 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    // MARK: - Helpers

    private func winRateColor(_ rate: Int) -> Color {
        switch rate {
        case 70...: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    private func taskProgress(_ task: TaskModel) -> Double {
        let total   = task.endsAt.timeIntervalSince(task.startedAt)
        let elapsed = appState.tick.timeIntervalSince(task.startedAt)
        guard total > 0 else { return 1.0 }
        return min(1.0, max(0.0, elapsed / total))
    }

    private func launchFloor(floor: DungeonFloorDef, durationSeconds: Int) {
        guard let stats = heroStats else {
            errorMessage = "找不到英雄資料"
            showError = true
            return
        }
        let result = viewModel.startDungeonFloor(
            floorKey: floor.key,
            durationSeconds: durationSeconds,
            heroStats: stats,
            context: context
        )
        if case .failure(let error) = result {
            errorMessage = error.errorDescription
            showError = true
        }
    }
}

// MARK: - FloorDetailSheet

private struct FloorDetailSheet: View {

    let floor:              DungeonFloorDef
    let heroStats:          HeroStats?
    let activeDungeonTask:  TaskModel?
    let progressionService: DungeonProgressionService
    let tick:               Date
    let onStart:            (Int) -> Void

    @State private var selectedDuration = AppConstants.DungeonDuration.short
    @Environment(\.dismiss) private var dismiss

    private var isCleared: Bool {
        progressionService.isFloorCleared(regionKey: floor.regionKey, floorIndex: floor.floorIndex)
    }

    private var isBusy: Bool { activeDungeonTask != nil }

    var body: some View {
        NavigationStack {
            List {
                floorInfoSection
                if let stats = heroStats { powerSection(stats: stats) }
                dropTableSection
                unlockPreviewSection
                launchSection
            }
            .navigationTitle(floor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sheet Sections

    private var floorInfoSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if floor.isBossFloor, let bossName = floor.bossName {
                        Label(bossName, systemImage: "crown.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                    if isCleared {
                        Label("已首通", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                Text("推薦戰力 \(floor.recommendedPower)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func powerSection(stats: HeroStats) -> some View {
        let rate = Int(HeroStats.winRate(power: stats.power, recommendedPower: floor.recommendedPower) * 100)
        Section("戰力評估") {
            HStack {
                Text("當前戰力")
                Spacer()
                Text("\(stats.power)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            HStack {
                Text("推薦戰力")
                Spacer()
                Text("\(floor.recommendedPower)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            HStack {
                Text("預估勝率")
                Spacer()
                Text("\(rate)%")
                    .fontWeight(.bold)
                    .foregroundStyle(winRateColor(rate))
            }
        }
    }

    private var dropTableSection: some View {
        Section("掉落物") {
            ForEach(floor.dropTable, id: \.material) { entry in
                HStack {
                    Text("\(entry.material.icon) \(entry.material.displayName)")
                    Spacer()
                    Text("\(Int(entry.dropRate * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("×\(entry.quantityRange.lowerBound)–\(entry.quantityRange.upperBound)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            HStack {
                Text("💰 金幣")
                Spacer()
                let r = floor.goldPerBattleRange
                Text("\(r.lowerBound)–\(r.upperBound) / 場")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var unlockPreviewSection: some View {
        Section("首通解鎖") {
            HStack {
                Text(floor.unlocksSlot.icon + " \(floor.unlocksSlot.displayName)配方")
                Spacer()
                if isCleared {
                    Text("已解鎖")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("未解鎖")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var launchSection: some View {
        Section {
            if isBusy, let task = activeDungeonTask {
                // 出征中：顯示倒數，禁用出發
                HStack {
                    Image(systemName: "map.fill").foregroundStyle(.purple)
                    Text("英雄出征中").foregroundStyle(.secondary)
                    Spacer()
                    Text(TaskCountdown.remaining(for: task, relativeTo: tick))
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .monospacedDigit()
                }
            } else {
                // 時長選擇
                Picker("出征時長", selection: $selectedDuration) {
                    ForEach(AppConstants.DungeonDuration.all, id: \.self) { duration in
                        Text(AppConstants.DungeonDuration.displayName(for: duration))
                            .tag(duration)
                    }
                }
                .pickerStyle(.segmented)

                // 出發按鈕
                Button {
                    onStart(selectedDuration)
                } label: {
                    Label("出發", systemImage: "paperplane.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
    }

    // MARK: - Helpers

    private func winRateColor(_ rate: Int) -> Color {
        switch rate {
        case 70...: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self, DungeonProgressionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    AdventureView(appState: AppState(context: container.mainContext))
        .modelContainer(container)
}
