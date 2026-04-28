// FarmerDetailSheet.swift
// 農夫詳細頁 Sheet（農場重構）
//
// Section 結構（同 GathererDetailSheet 風格）：
//   農夫資訊（可收合）— Tier badge + 升級費用
//   農地             — 2 欄 LazyVGrid，4 格（含鎖定）

import SwiftUI
import SwiftData

struct FarmerDetailSheet: View {

    let viewModel: BaseViewModel
    let appState:  AppState

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]
    @Query private var tasks:       [TaskModel]

    @State private var detailExpanded: Bool = true
    @State private var detailTab:      DetailTab = .upgrade
    @State private var alertMsg:       String?
    @State private var plantingPlot:   PendingPlot?

    private enum DetailTab { case upgrade, skill }

    private struct PendingPlot: Identifiable {
        let id = UUID()
        let plotIndex: Int
    }

    // MARK: - Computed

    private var player:    PlayerStateModel?       { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var currentTier: Int { player?.gatherer5Tier ?? 0 }

    private var availablePlots: Int {
        min(currentTier + 1, AppConstants.FarmerPlot.maxPlots)
    }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: .farmer,
            actorKey: AppConstants.FarmerPlot.key(for: 0),
            player: player
        )
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk  = player.heroExp >= cost.expCost
        let matOk  = cost.materialCosts.allSatisfy { inventory.amount(of: $0.0) >= $0.1 }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                detailSection
                farmPlotsSection
            }
            .navigationTitle("農場")
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
            .sheet(item: $plantingPlot) { pending in
                FarmerPlotSheet(
                    viewModel: viewModel,
                    plotIndex: pending.plotIndex,
                    player:    player,
                    inventory: inventory
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Section：農夫資訊（可收合）

    @ViewBuilder
    private var detailSection: some View {
        Section {
            VStack(spacing: 0) {

                // ── 標題列 ─────────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                        .frame(width: 22)
                    Text(currentTier < NpcUpgradeDef.maxTier
                         ? "升級後解鎖更多農田"
                         : "農田已全部解鎖")
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
                    if detailTab == .upgrade { upgradeContent } else { skillContent }
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

    // MARK: - 技能頁

    @ViewBuilder
    private var skillContent: some View {
        let nodes    = ProducerSkillNodeDef.nodes(for: "farmer")
        let availPts = player?.skillPoints(for: "farmer") ?? 0
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
    private func skillNodeRow(_ node: ProducerSkillNodeDef, availPoints: Int) -> some View {
        let level     = player?.skillLevel(nodeKey: node.key, actorKey: "farmer") ?? 0
        let isMaxed   = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let p = player else { return true }
            return p.skillLevel(nodeKey: prereqKey, actorKey: "farmer") >= node.prerequisiteLevel
        }()
        let canInvest = !isMaxed && prereqMet && availPoints > 0

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(node.name).fontWeight(.medium)
                        .foregroundStyle(prereqMet ? .primary : .secondary)
                    Text("Lv.\(level)/\(node.maxLevel)")
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    if isMaxed {
                        Text("已滿").font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green).clipShape(Capsule())
                    }
                }
                if !prereqMet, let prereqKey = node.prerequisiteKey,
                   let prereqNode = ProducerSkillNodeDef.find(key: prereqKey) {
                    Text("需先點「\(prereqNode.name)」達 \(node.prerequisiteLevel) 級")
                        .font(.caption).foregroundStyle(.tertiary)
                } else {
                    Text(node.description).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if canInvest {
                Button {
                    guard let player else { return }
                    if let errMsg = viewModel.investProducerSkillPoint(
                        nodeKey: node.key, actorKey: "farmer",
                        player: player, context: context) {
                        alertMsg = errMsg
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3).foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section：農地 Grid

    @ViewBuilder
    private var farmPlotsSection: some View {
        Section("農田") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(0 ..< AppConstants.FarmerPlot.maxPlots, id: \.self) { i in
                    farmerPlotCard(plotIndex: i)
                }
            }
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - 農地卡片

    @ViewBuilder
    private func farmerPlotCard(plotIndex: Int) -> some View {
        let plotKey       = AppConstants.FarmerPlot.key(for: plotIndex)
        let isLocked      = plotIndex >= availablePlots
        let completedTask = tasks.first { $0.actorKey == plotKey && $0.kind == .farming && $0.status == .completed }
        let activeTask    = tasks.first { $0.actorKey == plotKey && $0.kind == .farming && $0.status == .inProgress }

        if isLocked {
            lockedPlotCard(plotIndex: plotIndex)
        } else if let completed = completedTask {
            harvestPlotCard(plotIndex: plotIndex, task: completed)
        } else if let task = activeTask {
            growingPlotCard(plotIndex: plotIndex, task: task)
        } else {
            idlePlotCard(plotIndex: plotIndex)
        }
    }

    // 鎖定
    private func lockedPlotCard(plotIndex: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("農田 \(plotIndex + 1)")
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("升至 T\(plotIndex) 解鎖")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .systemGray6).opacity(0.6))
        )
    }

    // 可收穫
    private func harvestPlotCard(plotIndex: Int, task: TaskModel) -> some View {
        Button { appState.claimAllCompleted() } label: {
            VStack(spacing: 6) {
                Image(systemName: "basket.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("農田 \(plotIndex + 1)")
                    .font(.caption).fontWeight(.medium)
                if let seedType = MaterialType(rawValue: task.definitionKey) {
                    Text("\(seedType.icon) \(seedType.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("點擊收穫")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 生長中
    private func growingPlotCard(plotIndex: Int, task: TaskModel) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf.circle.fill")
                .symbolEffect(.pulse, isActive: true)
                .font(.title2)
                .foregroundStyle(Color.green.opacity(0.8))
            Text("農田 \(plotIndex + 1)")
                .font(.caption).fontWeight(.medium)
            if let seedType = MaterialType(rawValue: task.definitionKey) {
                Text("🌱 \(seedType.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: task.progress(relativeTo: appState.tick))
                .tint(.green)
                .frame(maxWidth: .infinity)
            Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                .font(.caption2).monospacedDigit()
                .foregroundStyle(.green)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    // 空閒
    private func idlePlotCard(plotIndex: Int) -> some View {
        Button { plantingPlot = PendingPlot(plotIndex: plotIndex) } label: {
            VStack(spacing: 8) {
                Image(systemName: "leaf")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("農田 \(plotIndex + 1)")
                    .font(.caption).fontWeight(.medium)
                Text("空閒")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("點擊種植")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    private func performUpgrade() {
        guard let player else { return }
        let result = appState.npcUpgradeService.upgrade(
            npcKind:  .farmer,
            actorKey: AppConstants.FarmerPlot.key(for: 0),
            player:   player
        )
        if case .failure(let err) = result {
            alertMsg = err.message
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
    FarmerDetailSheet(viewModel: BaseViewModel(), appState: appState)
        .modelContainer(container)
}
