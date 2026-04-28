// PharmacySheet.swift
// 製藥師配方 Sheet（V7-4）
//
// 觸發：點擊閒置的製藥師 NPC
// 功能：選擇藥水配方 → 建立煉藥任務，完成後藥水進消耗品背包

import SwiftUI
import SwiftData

struct PharmacySheet: View {

    let viewModel: BaseViewModel
    let appState: AppState
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var upgradeExpanded: Bool = true
    @State private var detailTab:       DetailTab = .upgrade
    @State private var upgradeAlertMsg: String?

    private enum DetailTab { case upgrade, skill }
    @State private var errorMessage:    String?
    @State private var showError = false

    // MARK: - Computed

    private var currentTier: Int { player?.tier(for: AppConstants.Actor.pharmacist) ?? 0 }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: .pharmacist, actorKey: AppConstants.Actor.pharmacist, player: player)
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk  = player.heroExp >= cost.expCost
        let matOk  = cost.materialCosts.allSatisfy { inventory.amount(of: $0.0) >= $0.1 }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    var body: some View {
        NavigationStack {
            List {

                // ── 升級 Section（可收合）────────────────────────────────
                upgradeSection

                // ── 藥水配方 ─────────────────────────────────────────────
                Section {
                    ForEach(PotionDef.all, id: \.key) { potion in
                        let canAfford = viewModel.canAffordPotion(potion, player: player, inventory: inventory)
                        Button {
                            startBrewing(potion: potion)
                        } label: {
                            potionRow(potion, canAfford: canAfford)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAfford)
                    }
                } header: {
                    Text("選擇藥水")
                } footer: {
                    Text("同一時間只能有一個製藥任務。藥水完成後進入消耗品背包。")
                        .font(.caption)
                }
            }
            .navigationTitle("製藥師")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { upgradeAlertMsg != nil },
                set: { if !$0 { upgradeAlertMsg = nil } }
            )) {
                Button("確定", role: .cancel) { upgradeAlertMsg = nil }
            } message: {
                Text(upgradeAlertMsg ?? "")
            }
            .alert("無法煉製", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }

    // MARK: - Section：升級（可收合）

    @ViewBuilder
    private var upgradeSection: some View {
        Section {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "cross.vial.fill")
                        .foregroundStyle(.teal)
                        .frame(width: 22)
                    Text(currentTier < NpcUpgradeDef.maxTier
                         ? "升級後加快煉藥速度"
                         : "已達升級上限")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TierBadgeView(tier: currentTier, alwaysShow: true, color: .teal)
                    Image(systemName: "chevron.down")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(upgradeExpanded ? 0 : -90))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { upgradeExpanded.toggle() }
                }
                if upgradeExpanded {
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
            .animation(.easeInOut(duration: 0.2), value: upgradeExpanded)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
        }
    }

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
                .tint(.teal)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    // MARK: - 技能頁

    @ViewBuilder
    private var skillContent: some View {
        let nodes    = ProducerSkillNodeDef.nodes(for: AppConstants.Actor.pharmacist)
        let availPts = player?.skillPoints(for: AppConstants.Actor.pharmacist) ?? 0
        if availPts > 0 {
            HStack {
                Spacer()
                Text("可用點數：\(availPts)")
                    .font(.caption).foregroundStyle(.teal).fontWeight(.semibold)
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
        let level     = player?.skillLevel(nodeKey: node.key, actorKey: AppConstants.Actor.pharmacist) ?? 0
        let isMaxed   = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let p = player else { return true }
            return p.skillLevel(nodeKey: prereqKey, actorKey: AppConstants.Actor.pharmacist) >= node.prerequisiteLevel
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
                            .background(Color.teal.opacity(0.15))
                            .foregroundStyle(.teal).clipShape(Capsule())
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
                        nodeKey: node.key, actorKey: AppConstants.Actor.pharmacist,
                        player: player, context: context) {
                        upgradeAlertMsg = errMsg
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3).foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

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
            Image(systemName: "coins").imageScale(.small).foregroundStyle(.yellow)
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
            npcKind: .pharmacist, actorKey: AppConstants.Actor.pharmacist, player: player)
        if case .failure(let err) = result { upgradeAlertMsg = err.message }
    }

    // MARK: - Potion Row

    @ViewBuilder
    private func potionRow(_ potion: PotionDef, canAfford: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(potion.icon)
                    .font(.title3)
                HStack(spacing: 6) {
                    if !canAfford {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    Text(potion.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? Color.primary : Color.secondary)
                }
                Spacer()
                Text(potion.brewDurationDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if !canAfford {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text("資源不足")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.10))
                .foregroundStyle(.red)
                .clipShape(Capsule())
            }

            HStack(spacing: 4) {
                Image(systemName: "cross.circle")
                    .font(.caption2)
                Text("HP 回復 \(Int(potion.healPercent * 100))%")
                    .font(.caption)
            }
            .foregroundStyle(.green.opacity(0.85))

            HStack(spacing: 8) {
                ForEach(0..<potion.ingredients.count, id: \.self) { i in
                    let (mat, amount) = potion.ingredients[i]
                    let has = inventory?.amount(of: mat) ?? 0
                    Text("\(mat.icon)×\(amount)")
                        .font(.caption)
                        .foregroundStyle(has >= amount ? Color.primary : Color.red)
                }
                HStack(spacing: 3) {
                    Image(systemName: "coins").frame(width: 11, height: 11)
                    Text("×\(potion.goldCost)")
                }
                .font(.caption)
                .foregroundStyle((player?.gold ?? 0) >= potion.goldCost ? Color.primary : Color.red)
            }
        }
        .padding(.vertical, 4)
        .opacity(canAfford ? 1.0 : 0.55)
    }

    // MARK: - Action

    private func startBrewing(potion: PotionDef) {
        let result = viewModel.startAlchemyTask(recipeKey: potion.key, context: context)
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.errorDescription
            showError = true
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             ConsumableInventoryModel.self, EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let appState = AppState(context: container.mainContext)
    PharmacySheet(
        viewModel: BaseViewModel(),
        appState: appState,
        player: nil,
        inventory: nil
    )
    .modelContainer(container)
}
