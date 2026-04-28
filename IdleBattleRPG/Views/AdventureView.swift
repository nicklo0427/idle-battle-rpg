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
//     - 點擊進行中樓層 → 直接進入 BattleLogSheet（跳過 FloorDetailSheet）
//     - 點擊閒置樓層 → FloorDetailSheet（掉落表、戰力比較、時長選擇、出發）
//     - 出發成功 → 自動開啟 BattleLogSheet

import SwiftUI
import SwiftData

struct AdventureView: View {

    let appState: AppState

    @Query private var players:    [PlayerStateModel]
    @Query private var equipments: [EquipmentModel]
    @Query private var tasks:      [TaskModel]

    @State private var viewModel          = AdventureViewModel()
    @State private var expandedRegionKey: String? = "wildland"
    @State private var selectedFloor:     DungeonFloorDef?
    @State private var showBattleLog      = false
    @State private var errorMessage:      String?
    @State private var showError          = false

    @Environment(\.modelContext) private var context

    // MARK: - 計算屬性

    private var heroStats: HeroStats? {
        guard let player = players.first else { return nil }
        return HeroStatsService.compute(player: player, equipped: equipments.filter { $0.isEquipped })
    }

    private var activeDungeonTask: TaskModel? {
        viewModel.dungeonTask(from: tasks)
    }

    private var activeDungeonFloor: DungeonFloorDef? {
        guard let task = activeDungeonTask else { return nil }
        return DungeonRegionDef.all.flatMap { $0.floors }.first { $0.key == task.definitionKey }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                activeBannerSection
                firstBoostBannerSection
                regionListSection
            }
            .navigationTitle("冒險")
            .sheet(item: $selectedFloor) { floor in
                FloorDetailSheet(
                    floor:             floor,
                    heroStats:         heroStats,
                    activeDungeonTask: activeDungeonTask,
                    appState:          appState,
                    tick:              appState.tick,
                    onStart: { duration, cuisineKey, potionKey in
                        if let task = launchFloor(floor: floor, durationSeconds: duration,
                                                  cuisineKey: cuisineKey, potionKey: potionKey) {
                            startBattleLogModel(task: task, floor: floor)
                            selectedFloor = nil
                            showBattleLog = true
                        } else {
                            selectedFloor = nil
                        }
                    }
                )
            }
            .sheet(isPresented: $showBattleLog) {
                if let floor = activeDungeonFloor {
                    BattleLogSheet(
                        model:      appState.battleLogPlayback,
                        title:      floor.name,
                        enemyLabel: floor.bossName ?? "敵方"
                    )
                }
            }
            .alert("無法出征", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var activeBannerSection: some View {
        if let task = activeDungeonTask {
            let color = Color.dungeonRegion(activeDungeonFloor?.regionKey ?? "")
            Section {
                Button {
                    if !appState.battleLogPlayback.isActive ||
                        appState.battleLogPlayback.associatedTaskId != task.id,
                       let floor = activeDungeonFloor {
                        startBattleLogModel(task: task, floor: floor)
                    }
                    showBattleLog = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .symbolEffect(.pulse)          // T02 動畫
                            .foregroundStyle(color)          // T01 區域色
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("正在出征：\(viewModel.activeDungeonName(from: tasks) ?? "—")")
                                .fontWeight(.semibold)
                            Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                                .font(.caption)
                                .foregroundStyle(color)
                                .monospacedDigit()
                                ProgressView(value: task.progress(relativeTo: appState.tick))
                                .tint(color)                 // T01 區域色
                                .padding(.top, 2)
                        }
                        Spacer()
                        Label("查看過程", systemImage: "text.alignleft")
                            .font(.caption)
                            .foregroundStyle(color)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
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
                Button {
                    guard unlocked else { return }
                    expandedRegionKey = expanded ? nil : region.key
                } label: {
                    regionHeader(region: region, unlocked: unlocked, completed: completed, expanded: expanded)
                }
                .buttonStyle(.plain)

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
                .foregroundStyle(completed ? .green : (unlocked ? Color.dungeonRegion(region.key) : .secondary))
                .frame(width: 26)

            Text(region.name)
                .fontWeight(.semibold)
                .foregroundStyle(unlocked ? .primary : .secondary)

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
        let isActiveFloor = activeDungeonTask?.definitionKey == floor.key

        Button {
            guard unlocked else { return }
            if isActiveFloor, let task = activeDungeonTask {
                // 進行中樓層：直接開 BattleLogSheet
                if !appState.battleLogPlayback.isActive ||
                    appState.battleLogPlayback.associatedTaskId != task.id {
                    startBattleLogModel(task: task, floor: floor)
                }
                showBattleLog = true
            } else {
                selectedFloor = floor
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(floor.isBossFloor
                              ? Color.dungeonRegion(region.key).opacity(0.2)     // T01 Boss 圓圈
                              : Color.secondary.opacity(0.1))
                        .frame(width: 30, height: 30)
                    if floor.isBossFloor {
                        Image(systemName: "crown.fill")
                            .frame(width: 14, height: 14)
                            .foregroundStyle(Color.dungeonRegion(region.key))
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
                                    .foregroundStyle(Color.winRate(rate))
                            }
                        }
                    }
                }

                Spacer()

                if unlocked {
                    if isActiveFloor {
                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft")
                                .font(.caption)
                            Text("出征中")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.dungeonRegion(region.key))  // T01 區域色
                    } else if activeDungeonTask != nil {
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

    /// 建立地下城任務。成功時回傳已建立的 TaskModel；失敗時設定錯誤訊息並回傳 nil。
    @discardableResult
    private func launchFloor(
        floor: DungeonFloorDef,
        durationSeconds: Int,
        cuisineKey: String = "",   // V7-4
        potionKey:  String = ""    // V7-4
    ) -> TaskModel? {
        guard let stats = heroStats else {
            errorMessage = "找不到英雄資料"
            showError = true
            return nil
        }
        let result = viewModel.startDungeonFloor(
            floorKey: floor.key,
            durationSeconds: durationSeconds,
            heroStats: stats,
            equippedSkillKeys: players.first?.equippedSkillKeys ?? [],
            cuisineKey: cuisineKey,
            potionKey:  potionKey,
            context: context
        )
        if case .failure(let error) = result {
            errorMessage = error.errorDescription
            showError = true
            return nil
        }
        // 出征成功 → 自動推進新手引導 step 2 → 3
        if let player = players.first, player.onboardingStep == 2 {
            player.onboardingStep = 3
            try? context.save()
        }
        // 直接從 context 查詢剛建立的任務（@Query 更新是非同步的）
        let descriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.actorKey == "player" }
        )
        return (try? context.fetch(descriptor))?.first(where: { $0.status == .inProgress })
    }

    /// 啟動戰鬥播放模型（首次啟動或 app 重啟後重新連接）
    private func startBattleLogModel(task: TaskModel, floor: DungeonFloorDef) {
        let fromIdx      = BattleLogGenerator.currentBattleIndex(for: task)
        let totalDur     = task.endsAt.timeIntervalSince(task.startedAt)
        let totalBattles = task.forcedBattles ?? max(1, Int(totalDur / 60))
        let batchSize    = 5

        // V7-4：從快照 key 還原消耗品定義
        let cuisineDef: CuisineDef? = ConsumableType(rawValue: task.snapshotCuisineKey)
            .flatMap { $0.cuisineDefKey }
            .flatMap { CuisineDef.find($0) }
        let potionDef: PotionDef? = {
            guard let type = ConsumableType(rawValue: task.snapshotPotionKey) else { return nil }
            return PotionDef.all.first { $0.consumableType == type }
        }()

        let events = BattleLogGenerator.generate(
            task: task, floor: floor,
            fromBattleIndex: fromIdx, maxBattles: batchSize,
            cuisineDef: cuisineDef, potionDef: potionDef
        )

        // T09：傳入裝備技能定義，啟用 CD 面板
        let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

        appState.battleLogPlayback.start(
            events:           events,
            fromBattleIndex:  fromIdx,
            taskTotalBattles: totalBattles,
            taskId:           task.id,
            activeSkills:     activeSkills,
            nextBatchProvider: { nextIdx in
                guard Date.now < task.endsAt, nextIdx < totalBattles else { return nil }
                return BattleLogGenerator.generate(
                    task: task, floor: floor,
                    fromBattleIndex: nextIdx, maxBattles: batchSize,
                    cuisineDef: cuisineDef, potionDef: potionDef
                )
            }
        )
    }
}

// MARK: - FloorDetailSheet

private struct FloorDetailSheet: View {

    let floor:             DungeonFloorDef
    let heroStats:         HeroStats?
    let activeDungeonTask: TaskModel?
    let appState:          AppState
    let tick:              Date
    let onStart:           (Int, String, String) -> Void   // V7-4: (duration, cuisineKey, potionKey)

    @State private var selectedDuration  = AppConstants.DungeonDuration.short
    @State private var showEliteBattle   = false
    @State private var eliteCleared      = false
    @State private var selectedCuisineKey = ""   // V7-4
    @State private var selectedPotionKey  = ""   // V7-4
    @Environment(\.dismiss) private var dismiss
    @Query private var players:     [PlayerStateModel]
    @Query private var consumables: [ConsumableInventoryModel]   // V7-4

    private var equippedSkills: [SkillDef] {
        (players.first?.equippedSkillKeys ?? []).compactMap { SkillDef.find(key: $0) }
    }

    private var isCleared: Bool {
        appState.progressionService.isFloorCleared(regionKey: floor.regionKey, floorIndex: floor.floorIndex)
    }

    private var isBusy: Bool { activeDungeonTask != nil }

    var body: some View {
        NavigationStack {
            List {
                floorInfoSection
                if let stats = heroStats { powerSection(stats: stats) }
                dropTableSection
                unlockPreviewSection
                eliteSection
                consumableSection   // V7-4
                launchSection
            }
            .navigationTitle(floor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
            .sheet(isPresented: $showEliteBattle) {
                if let elite = EliteDef.find(floorKey: floor.key) {
                    EliteBattleSheet(
                        elite:    elite,
                        appState: appState,
                        onEliteDefeated: { eliteCleared = true }
                    )
                }
            }
            .onAppear {
                eliteCleared = appState.progressionService.isEliteCleared(
                    regionKey:  floor.regionKey,
                    floorIndex: floor.floorIndex
                )
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
                    .foregroundStyle(Color.winRate(rate))
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
                HStack(spacing: 4) {
                    Image(systemName: "coins").frame(width: 14, height: 14).foregroundStyle(.yellow)
                    Text("金幣")
                }
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

    // MARK: - Elite Section

    @ViewBuilder
    private var eliteSection: some View {
        if let elite = EliteDef.find(floorKey: floor.key) {
            Section("地區菁英") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(elite.name)
                            .fontWeight(.semibold)
                        Spacer()
                        if eliteCleared {
                            Label("已擊敗", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Text(elite.lore)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    eliteStatPill("HP",  "\(elite.hp)",  .red)
                    eliteStatPill("ATK", "\(elite.atk)", .orange)
                    eliteStatPill("DEF", "\(elite.def)", .blue)
                    Spacer()
                    Text("需 \(elite.minPowerRequired) 戰力")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "coins").frame(width: 12, height: 12).foregroundStyle(.yellow)
                        Text("\(elite.reward.gold) 金幣")
                    }
                    .font(.caption)
                    Text("+")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("\(elite.reward.material.icon) \(elite.reward.material.displayName) ×\(elite.reward.materialCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if eliteCleared {
                    Label("菁英已擊敗，獎勵已領取", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if let power = heroStats?.power, power >= elite.minPowerRequired {
                    Button {
                        showEliteBattle = true
                    } label: {
                        Label("挑戰菁英", systemImage: "shield.lefthalf.filled")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(isBusy)
                } else {
                    Label("戰力不足（需 \(elite.minPowerRequired)）", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private func eliteStatPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    // V7-4：消耗品 Picker section（選填）
    @ViewBuilder
    private var consumableSection: some View {
        let inv = consumables.first
        let cuisineOptions = ConsumableType.allCases.filter {
            $0.isCuisine && (inv?.amount(of: $0) ?? 0) > 0
        }
        let potionOptions = ConsumableType.allCases.filter {
            $0.isPotion && (inv?.amount(of: $0) ?? 0) > 0
        }
        if !cuisineOptions.isEmpty || !potionOptions.isEmpty {
            Section("攜帶消耗品（選填）") {
                if !cuisineOptions.isEmpty {
                    Picker("料理", selection: $selectedCuisineKey) {
                        Text("不攜帶").tag("")
                        ForEach(cuisineOptions, id: \.rawValue) { type in
                            Text("\(type.icon) \(type.displayName) ×\(inv?.amount(of: type) ?? 0)")
                                .tag(type.rawValue)
                        }
                    }
                }
                if !potionOptions.isEmpty {
                    Picker("藥水", selection: $selectedPotionKey) {
                        Text("不攜帶").tag("")
                        ForEach(potionOptions, id: \.rawValue) { type in
                            Text("\(type.icon) \(type.displayName) ×\(inv?.amount(of: type) ?? 0)")
                                .tag(type.rawValue)
                        }
                    }
                }
            }
        }
    }

    private var launchSection: some View {
        Section {
            if isBusy, let task = activeDungeonTask {
                HStack {
                    Image(systemName: "map.fill")
                        .symbolEffect(.pulse)                    // T02 動畫
                        .foregroundStyle(Color.dungeonRegion(floor.regionKey))
                    Text("英雄出征中").foregroundStyle(.secondary)
                    Spacer()
                    Text(TaskCountdown.remaining(for: task, relativeTo: tick))
                        .font(.caption)
                        .foregroundStyle(Color.dungeonRegion(floor.regionKey))
                        .monospacedDigit()
                }
            } else {
                Picker("出征時長", selection: $selectedDuration) {
                    ForEach(AppConstants.DungeonDuration.all, id: \.self) { duration in
                        Text(AppConstants.DungeonDuration.displayName(for: duration))
                            .tag(duration)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    onStart(selectedDuration, selectedCuisineKey, selectedPotionKey)
                } label: {
                    Label("出發", systemImage: "paperplane.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.dungeonRegion(floor.regionKey))  // T01 出發按鈕用區域色

                // 配備技能預覽
                if !equippedSkills.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(equippedSkills.map { "\($0.name)（\($0.cooldownSeconds)s）" }.joined(separator: "・"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
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
