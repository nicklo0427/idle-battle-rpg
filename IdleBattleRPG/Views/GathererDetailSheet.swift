// GathererDetailSheet.swift
// 採集者詳細頁 Sheet
//
// Section 結構：
//   採集者資訊（可收合）— Tier badge + 採集加成；展開後顯示「升級/技能」tab 內容
//   派遣             — 閒置：地點列（點箭頭 → 確認 Sheet）；忙碌：進度條 + 撤退入口

import SwiftUI
import SwiftData

struct GathererDetailSheet: View {

    let npcDef:    GathererNpcDef
    let appState:  AppState
    let viewModel: BaseViewModel

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]
    @Query private var tasks:       [TaskModel]

    @State private var alertMsg:          String?
    @State private var detailExpanded:    Bool = true
    @State private var detailTab:         DetailTab = .upgrade
    @State private var pendingDispatch:   PendingDispatch?
    @State private var showRecallConfirm: Bool = false

    private enum DetailTab { case upgrade, skill }

    private struct PendingDispatch: Identifiable {
        let id = UUID()
        let location: GatherLocationDef
    }

    // MARK: - Computed

    private var player:    PlayerStateModel?       { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var activeTask: TaskModel? {
        tasks.first { $0.actorKey == npcDef.actorKey && $0.status == .inProgress }
    }

    private var currentTier: Int {
        player?.tier(for: npcDef.actorKey) ?? 0
    }

    private var gatherBonus: Int {
        NpcUpgradeDef.gatherBonus(tier: currentTier)
    }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: npcDef.npcKind, actorKey: npcDef.actorKey, player: player)
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk  = player.heroExp >= cost.expCost
        let matOk  = cost.materialCosts.allSatisfy { inventory.amount(of: $0.0) >= $0.1 }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    private var filteredLocations: [GatherLocationDef] {
        GatherLocationDef.all.filter { npcDef.locationKeys.contains($0.key) }
    }

    private func isLocationUnlocked(_ loc: GatherLocationDef) -> Bool {
        guard let key = loc.requiredBossFloorKey else { return true }
        return appState.progressionService.isEliteCleared(floorKey: key)
    }

    private var unlockedLocations: [GatherLocationDef] {
        filteredLocations.filter { isLocationUnlocked($0) }
    }

    private var lockedLocations: [GatherLocationDef] {
        filteredLocations.filter { !isLocationUnlocked($0) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                detailSection
                dispatchSection
            }
            .navigationTitle(npcDef.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { alertMsg != nil },
                set: { if !$0 { alertMsg = nil } }
            )) {
                Button("確定", role: .cancel) { alertMsg = nil }
            } message: {
                Text(alertMsg ?? "")
            }
            .sheet(item: $pendingDispatch) { pending in
                DispatchConfirmSheet(
                    npcDef:      npcDef,
                    location:    pending.location,
                    currentTier: currentTier,
                    player:      player,
                    onConfirm: { duration in
                        pendingDispatch = nil
                        startGather(location: pending.location, duration: duration)
                    },
                    onCancel: { pendingDispatch = nil }
                )
            }
        }
    }

    // MARK: - Section：採集者資訊（可收合）
    //
    // 不使用 DisclosureGroup-in-List：DisclosureGroup 的 content rows 會被 List
    // 加上額外縮排，且 .listRowInsets 無法可靠覆寫。
    // 改為整個 Section 只有一個 List row（VStack），手動實作展開/收合。

    @ViewBuilder
    private var detailSection: some View {
        Section {
            VStack(spacing: 0) {

                // ── 標題列 ─────────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: npcDef.icon)
                        .foregroundStyle(.green)
                        .frame(width: 22)
                    Text(gatherBonus > 0 ? "採集加成 +\(gatherBonus)" : "尚無採集加成")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TierBadgeView(tier: currentTier, alwaysShow: true, color: .green)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(detailExpanded ? 0 : -90))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { detailExpanded.toggle() }
                }

                // ── 展開內容 ───────────────────────────────────────────
                if detailExpanded {
                    Divider().padding(.top, 6)

                    Picker("", selection: $detailTab) {
                        Text("升級").tag(DetailTab.upgrade)
                        Text("技能").tag(DetailTab.skill)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)

                    Divider()

                    if detailTab == .upgrade {
                        upgradeContent
                    } else {
                        skillContent
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: detailExpanded)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - 升級內容（VStack 內部，非 List row）

    @ViewBuilder
    private var upgradeContent: some View {
        if currentTier >= NpcUpgradeDef.maxTier {
            HStack {
                Label("已達升級上限 T\(NpcUpgradeDef.maxTier)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 10)
        } else if let cost = upgradeCost, let player {
            upgradeRow(label: "EXP", required: cost.expCost, have: player.heroExp)
            ForEach(cost.materialCosts, id: \.0) { mat, req in
                Divider()
                upgradeRow(label: "\(mat.icon) \(mat.displayName)",
                           required: req, have: inventory?.amount(of: mat) ?? 0)
            }
            Divider()
            upgradeGoldRow(required: cost.goldCost, have: player.gold)
            Button("升至 T\(currentTier + 1)") { performUpgrade() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    // MARK: - 技能內容（VStack 內部，非 List row）

    @ViewBuilder
    private var skillContent: some View {
        let nodes    = GathererSkillNodeDef.nodes(for: npcDef.actorKey)
        let availPts = player?.skillPoints(for: npcDef.actorKey) ?? 0
        if availPts > 0 {
            HStack {
                Spacer()
                Text("可用點數：\(availPts)")
                    .font(.caption).foregroundStyle(.green).fontWeight(.semibold)
            }
            .padding(.vertical, 8)
            Divider()
        }
        ForEach(nodes, id: \.key) { node in
            skillNodeRow(node, availPoints: availPts)
            if node.key != nodes.last?.key { Divider() }
        }
    }

    @ViewBuilder
    private func skillNodeRow(_ node: GathererSkillNodeDef, availPoints: Int) -> some View {
        let level     = player?.skillLevel(nodeKey: node.key, actorKey: npcDef.actorKey) ?? 0
        let isMaxed   = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let p = player else { return true }
            return p.skillLevel(nodeKey: prereqKey, actorKey: npcDef.actorKey) >= node.prerequisiteLevel
        }()
        let canInvest = !isMaxed && prereqMet && availPoints > 0

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(node.name)
                        .fontWeight(.medium)
                        .foregroundStyle(prereqMet ? .primary : .secondary)

                    Text("Lv.\(level)/\(node.maxLevel)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    if isMaxed {
                        Text("已滿")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                if !prereqMet, let prereqKey = node.prerequisiteKey,
                   let prereqNode = GathererSkillNodeDef.find(key: prereqKey) {
                    Text("需先點「\(prereqNode.name)」達 \(node.prerequisiteLevel) 級")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(node.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if canInvest {
                Button {
                    guard let player else { return }
                    if let errMsg = viewModel.investGathererSkillPoint(
                        nodeKey:  node.key,
                        actorKey: npcDef.actorKey,
                        player:   player,
                        context:  context
                    ) {
                        alertMsg = errMsg
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section：派遣

    @ViewBuilder
    private var dispatchSection: some View {
        Section("派遣") {
            if let task = activeTask {
                let locName = GatherLocationDef.find(key: task.definitionKey)?.name ?? "—"
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        Text(locName)
                            .fontWeight(.medium)
                        Spacer()
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.green)
                            .monospacedDigit()
                    }
                    ProgressView(value: task.progress(relativeTo: appState.tick))
                        .tint(.green)
                    Text("預計 \(task.endsAt.formatted(date: .omitted, time: .shortened)) 回來")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)

                Button(role: .destructive) {
                    showRecallConfirm = true
                } label: {
                    Label("提前撤退", systemImage: "xmark.circle")
                        .font(.subheadline)
                }
                .confirmationDialog(
                    "提前撤退將放棄本次所有採集獎勵",
                    isPresented: $showRecallConfirm,
                    titleVisibility: .visible
                ) {
                    Button("撤退（放棄獎勵）", role: .destructive) {
                        recallGatherer()
                    }
                    Button("繼續採集", role: .cancel) {}
                }

            } else {
                ForEach(unlockedLocations, id: \.key) { location in
                    locationRow(location)
                }
                ForEach(lockedLocations, id: \.key) { location in
                    lockedLocationRow(location)
                }
            }
        }
    }

    // MARK: - Location Row（精簡版，無 chip）

    @ViewBuilder
    private func locationRow(_ location: GatherLocationDef) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(location.outputMaterial.icon)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .fontWeight(.semibold)
                Text("\(location.outputMaterial.displayName)  \(location.outputRange.lowerBound)–\(location.outputRange.upperBound)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                pendingDispatch = PendingDispatch(location: location)
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Locked Location Row

    @ViewBuilder
    private func lockedLocationRow(_ location: GatherLocationDef) -> some View {
        let bossName = DungeonRegionDef.all
            .flatMap { $0.floors }
            .first { $0.key == location.requiredBossFloorKey }?
            .bossName ?? "Boss"

        HStack(spacing: 12) {
            Text(location.outputMaterial.icon)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color(uiColor: .systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("需通關：\(bossName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func upgradeRow(label: String, required: Int, have: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(have) / \(required)")
                .font(.caption)
                .foregroundStyle(have >= required ? Color.secondary : Color.red)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    private func upgradeGoldRow(required: Int, have: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "coins")
                .imageScale(.small)
                .foregroundStyle(.yellow)
            Text("金幣")
            Spacer()
            Text("\(have) / \(required)")
                .font(.caption)
                .foregroundStyle(have >= required ? Color.secondary : Color.red)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    private func startGather(location: GatherLocationDef, duration: Int) {
        let result = viewModel.startGatherTask(
            actorKey:        npcDef.actorKey,
            locationKey:     location.key,
            durationSeconds: duration,
            context:         context
        )
        switch result {
        case .success:
            if let player {
                viewModel.advanceOnboarding(expectedStep: 0, player: player, context: context)
            }
            dismiss()
        case .failure(let error):
            alertMsg = error.errorDescription
        }
    }

    private func performUpgrade() {
        guard let player else { return }
        let result = appState.npcUpgradeService.upgrade(
            npcKind:  npcDef.npcKind,
            actorKey: npcDef.actorKey,
            player:   player
        )
        if case .failure(let err) = result {
            alertMsg = err.message
        }
    }

    private func recallGatherer() {
        guard let task = activeTask else { return }
        context.delete(task)
        try? context.save()
    }
}

// MARK: - DispatchConfirmSheet

private struct DispatchConfirmSheet: View {

    let npcDef:      GathererNpcDef
    let location:    GatherLocationDef
    let currentTier: Int
    let player:      PlayerStateModel?
    let onConfirm:   (Int) -> Void
    let onCancel:    () -> Void

    private enum DurationMode: String, CaseIterable {
        case preset   = "時長"
        case runCount = "次數"
    }

    @State private var durationMode:   DurationMode = .preset
    @State private var selectedPreset: Int
    @State private var runCount:       Int = 1

    init(npcDef: GathererNpcDef, location: GatherLocationDef,
         currentTier: Int, player: PlayerStateModel?,
         onConfirm: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.npcDef      = npcDef
        self.location    = location
        self.currentTier = currentTier
        self.player      = player
        self.onConfirm   = onConfirm
        self.onCancel    = onCancel
        _selectedPreset  = State(initialValue: location.shortestDuration)
    }

    // MARK: - Duration Calculations

    private var maxDuration: Int {
        location.durationOptions.max() ?? location.shortestDuration
    }

    private var maxRunCount: Int {
        maxDuration / location.shortestDuration
    }

    private var effectiveDuration: Int {
        switch durationMode {
        case .preset:
            return selectedPreset
        case .runCount:
            return min(maxDuration, runCount * location.shortestDuration)
        }
    }

    private var estimatedEndTime: Date {
        Date().addingTimeInterval(TimeInterval(effectiveDuration))
    }

    private var durationLabel: String {
        let mins = effectiveDuration / 60
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m == 0 ? "\(h) 小時" : "\(h) 小時 \(m) 分"
        }
        return "\(mins) 分鐘"
    }

    // MARK: - Reward Calculations

    private var tierBonus: Int {
        NpcUpgradeDef.gatherBonus(tier: currentTier)
    }

    private var yieldSkillBonus: Int {
        let nodes = GathererSkillNodeDef.nodes(for: npcDef.actorKey)
        guard let yieldNode = nodes.first(where: {
            if case .yieldBonus(_) = $0.effect { return true }
            return false
        }) else { return 0 }
        let level = player?.skillLevel(nodeKey: yieldNode.key, actorKey: npcDef.actorKey) ?? 0
        if case .yieldBonus(let perPoint) = yieldNode.effect { return level * perPoint }
        return 0
    }

    private var totalBonus: Int   { tierBonus + yieldSkillBonus }
    private var cycles:     Int   { max(1, effectiveDuration / location.shortestDuration) }
    private var estimatedMin: Int { (location.outputRange.lowerBound + totalBonus) * cycles }
    private var estimatedMax: Int { (location.outputRange.upperBound + totalBonus) * cycles }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // 頂部：地點資訊
            VStack(spacing: 6) {
                Text(location.outputMaterial.icon)
                    .font(.system(size: 44))
                Text(location.name)
                    .font(.title3).fontWeight(.bold)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // 主體：不用 ScrollView 避免 TextField 崩潰
            VStack(spacing: 18) {

                // 模式選擇器
                Picker("", selection: $durationMode) {
                    ForEach(DurationMode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                // 模式內容（固定高度區塊，避免跳動）
                Group {
                    switch durationMode {
                    case .preset:   presetContent
                    case .runCount: runCountContent
                    }
                }
                .frame(minHeight: 120)

                Divider()

                // 預計獎勵
                VStack(spacing: 4) {
                    Text("預計獲得")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(estimatedMin)–\(estimatedMax)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text(location.outputMaterial.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if totalBonus > 0 {
                        Text("含加成 +\(totalBonus) / 次 × \(cycles) 次")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 0)

                // 按鈕
                VStack(spacing: 10) {
                    Button {
                        onConfirm(effectiveDuration)
                    } label: {
                        Label("確認派遣", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)

                    Button("取消", action: onCancel)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - 時長 Tab

    private var presetContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(location.durationOptions, id: \.self) { dur in
                    PresetDurationChip(
                        dur:           dur,
                        shortestDur:   location.shortestDuration,
                        isSelected:    selectedPreset == dur,
                        onTap:         { selectedPreset = dur }
                    )
                }
            }
            Text("預計 \(estimatedEndTime.formatted(date: .omitted, time: .shortened)) 完成")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 次數 Tab

    @ViewBuilder
    private var runCountContent: some View {
        VStack(spacing: 10) {

            // 上限說明
            Text("最多 \(maxRunCount) 次（\(maxRunCount * location.shortestDuration / 3600) 小時）")
                .font(.caption)
                .foregroundStyle(.tertiary)

            // 數字顯示
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(runCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .frame(minWidth: 80, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: runCount)
                Text("次")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // 內建數字鍵盤（九宮格）
            InlineNumpad(
                value:  $runCount,
                minVal: 1,
                maxVal: maxRunCount
            )

            Text("預計 \(estimatedEndTime.formatted(date: .omitted, time: .shortened)) 完成")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - PresetDurationChip

private struct PresetDurationChip: View {
    let dur:         Int
    let shortestDur: Int
    let isSelected:  Bool
    let onTap:       () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Text(AppConstants.DungeonDuration.displayName(for: dur))
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
            Text("\(dur / shortestDur) 輪")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.green : Color.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isSelected ? Color.green.opacity(0.18) : Color(uiColor: .systemGray5))
        .foregroundStyle(isSelected ? Color.green : Color.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onTap() }
    }
}

// MARK: - InlineNumpad

/// 純 SwiftUI 數字鍵盤，不依賴系統鍵盤或 Alert，無 UIKit 警告。
/// 輸入邏輯：每按一個數字追加到尾端；⌫ 刪最後一位；夾在 minVal...maxVal 之間。
private struct InlineNumpad: View {

    @Binding var value:  Int
    let minVal: Int
    let maxVal: Int

    @State private var buffer: String = ""

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        numKey(key)
                    }
                }
            }
            // 最大值快捷按鈕
            Text("最大值（\(maxVal)）")
                .font(.callout).fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGray5))
                .foregroundStyle(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    buffer = "\(maxVal)"
                    value  = maxVal
                }
        }
        .onAppear { buffer = "" }
    }

    @ViewBuilder
    private func numKey(_ key: String) -> some View {
        let isAction = key == "C" || key == "⌫"
        Text(key)
            .font(.title3).fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                key == "C"
                    ? Color.red.opacity(0.12)
                    : isAction
                        ? Color(uiColor: .systemGray4)
                        : Color(uiColor: .systemGray5)
            )
            .foregroundStyle(
                key == "C" ? Color.red : Color.primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture { handleKey(key) }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            // 清除：重設為最小值
            buffer = ""
            value  = minVal
        case "⌫":
            // 退位
            let s = buffer.isEmpty ? "\(value)" : buffer
            let trimmed = String(s.dropLast())
            buffer = trimmed
            value  = trimmed.isEmpty ? minVal : max(minVal, min(Int(trimmed) ?? minVal, maxVal))
        default:
            // 數字鍵：追加到 buffer
            let next = (buffer.isEmpty && key == "0") ? "" : buffer + key   // 不允許前導零
            if let v = Int(next), v >= 1, v <= maxVal {
                buffer = next
                value  = v
            } else if next.isEmpty {
                buffer = ""
            }
            // 若超過上限，不做任何事（按鍵無效，給予觸覺提示）
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let appState = AppState(context: container.mainContext)
    GathererDetailSheet(
        npcDef:    GathererNpcDef.all[0],
        appState:  appState,
        viewModel: BaseViewModel()
    )
    .modelContainer(container)
}
