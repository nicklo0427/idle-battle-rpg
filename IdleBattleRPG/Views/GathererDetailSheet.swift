// GathererDetailSheet.swift
// 採集者詳細頁 Sheet
//
// 觸發：點擊採集者 NPC row（不論忙閒皆可點）
//
// 三個 Section：
//   目前狀態 — NPC 職業、目前 Tier、採集加成說明
//   升級     — 費用明細（EXP / 素材 / 金幣）+ 升級按鈕
//   派遣     — 閒置時顯示地點選擇；忙碌時顯示倒數 + 進度條

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

    @State private var selectedDurations: [String: Int] = [:]
    @State private var alertMsg: String?

    // MARK: - Computed

    private var player:    PlayerStateModel?     { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var activeTask: TaskModel? {
        tasks.first { $0.actorKey == npcDef.actorKey && $0.status == .inProgress }
    }

    private var currentTier: Int {
        player?.tier(for: npcDef.actorKey) ?? 0
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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                statusSection
                upgradeSection
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
            .onAppear {
                for loc in filteredLocations where selectedDurations[loc.key] == nil {
                    selectedDurations[loc.key] = loc.shortestDuration
                }
            }
        }
    }

    // MARK: - Section：目前狀態

    @ViewBuilder
    private var statusSection: some View {
        Section("目前狀態") {
            HStack {
                Image(systemName: npcDef.icon)
                    .foregroundStyle(.green)
                    .frame(width: 24)
                Text(npcDef.name)
                    .fontWeight(.medium)
                Spacer()
                TierBadgeView(tier: currentTier, alwaysShow: true, color: .green)
            }
            let bonus = NpcUpgradeDef.gatherBonus(tier: currentTier)
            Text(bonus > 0
                 ? "每次採集額外 +\(bonus) 產出"
                 : "無額外加成（升級後解鎖）")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section：升級

    @ViewBuilder
    private var upgradeSection: some View {
        Section("升級") {
            if currentTier >= NpcUpgradeDef.maxTier {
                Label("已達升級上限 T\(NpcUpgradeDef.maxTier)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
            } else if let cost = upgradeCost, let player {
                costRow(label: "EXP",
                        required: cost.expCost,
                        have: player.heroExp,
                        suffix: "")
                ForEach(cost.materialCosts, id: \.0) { mat, req in
                    costRow(label: "\(mat.icon) \(mat.displayName)",
                            required: req,
                            have: inventory?.amount(of: mat) ?? 0,
                            suffix: "")
                }
                goldCostRow(required: cost.goldCost, have: player.gold)

                Button("升至 T\(currentTier + 1)") {
                    performUpgrade()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
            }
        }
    }

    // MARK: - Section：派遣

    @ViewBuilder
    private var dispatchSection: some View {
        Section("派遣") {
            if let task = activeTask {
                if let locDef = GatherLocationDef.find(key: task.definitionKey) {
                    HStack {
                        Text("採集中：\(locDef.name)")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                    .font(.caption)
                    .foregroundStyle(.green)
                ProgressView(value: task.progress(relativeTo: appState.tick))
                    .tint(.green)
                    .scaleEffect(y: 0.7)
                    .padding(.top, 1)
            } else {
                ForEach(filteredLocations, id: \.key) { location in
                    locationRow(location)
                }
            }
        }
    }

    // MARK: - Location Row（複用 GatherSheet 結構）

    @ViewBuilder
    private func locationRow(_ location: GatherLocationDef) -> some View {
        let selected = selectedDurations[location.key] ?? location.shortestDuration

        VStack(alignment: .leading, spacing: 8) {

            Button {
                startGather(location: location, duration: selected)
            } label: {
                HStack(spacing: 12) {
                    Text(location.outputMaterial.icon)
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(AppConstants.DungeonDuration.displayName(for: selected))
                                .font(.caption)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(location.outputMaterial.displayName) \(location.outputRange.lowerBound)–\(location.outputRange.upperBound)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NPCDispatchButtonStyle())

            HStack(spacing: 6) {
                ForEach(location.durationOptions, id: \.self) { dur in
                    Button {
                        selectedDurations[location.key] = dur
                    } label: {
                        Text(AppConstants.DungeonDuration.displayName(for: dur))
                            .font(.caption)
                            .fontWeight(selected == dur ? .semibold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                selected == dur
                                    ? Color.green.opacity(0.18)
                                    : Color(uiColor: .systemGray5)
                            )
                            .foregroundStyle(selected == dur ? .green : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 48)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func goldCostRow(required: Int, have: Int) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "coins.fill").frame(width: 14, height: 14).foregroundStyle(.yellow)
                Text("金幣")
            }
            Spacer()
            Text("\(have) / \(required)")
                .font(.caption)
                .foregroundStyle(have >= required ? Color.secondary : Color.red)
                .monospacedDigit()
        }
    }

    private func costRow(label: String, required: Int, have: Int, suffix: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(have) / \(required)\(suffix.isEmpty ? "" : " \(suffix)")")
                .font(.caption)
                .foregroundStyle(have >= required ? Color.secondary : Color.red)
                .monospacedDigit()
        }
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
            // 採集成功 → 自動推進新手引導 step 0
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
}

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
