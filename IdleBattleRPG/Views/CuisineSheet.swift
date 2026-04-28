// CuisineSheet.swift
// 廚師配方 Sheet（V7-3，T03 改版）
//
// 觸發：點擊閒置的廚師 NPC
// 功能：選擇料理配方 → 建立烹飪任務，完成後進入消耗品背包
//
// 設計：
//   - 顯示所有料理配方（4 種，無解鎖門檻）
//   - 顯示所需素材 + 金幣 + 烹飪時間 + Buff 效果
//   - 素材或金幣不足時 row disabled + 紅色提示
//   - 顯示消耗品背包持有量
//   - 建立成功後自動關閉 Sheet

import SwiftUI
import SwiftData

struct CuisineSheet: View {

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

    private var currentTier: Int { player?.tier(for: AppConstants.Actor.chef) ?? 0 }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: .chef, actorKey: AppConstants.Actor.chef, player: player)
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

                // ── 料理配方 ────────────────────────────────────────
                Section {
                    ForEach(CuisineDef.all, id: \.key) { cuisine in
                        let canAfford = viewModel.canAffordCuisine(cuisine, player: player, inventory: inventory)
                        Button {
                            startCooking(cuisine: cuisine)
                        } label: {
                            cuisineRow(cuisine, canAfford: canAfford)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAfford)
                    }
                } header: {
                    Text("選擇料理")
                } footer: {
                    Text("完成後料理進入消耗品背包，出征前選擇使用可獲得屬性加成。")
                        .font(.caption)
                }
            }
            .navigationTitle("廚師")
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
            .alert("無法烹飪", isPresented: $showError) {
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
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.purple)
                        .frame(width: 22)
                    Text(currentTier < NpcUpgradeDef.maxTier
                         ? "升級後加快烹飪速度"
                         : "已達升級上限")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TierBadgeView(tier: currentTier, alwaysShow: true, color: .purple)
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
                .tint(.purple)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    // MARK: - 技能頁

    @ViewBuilder
    private var skillContent: some View {
        let nodes    = ProducerSkillNodeDef.nodes(for: AppConstants.Actor.chef)
        let availPts = player?.skillPoints(for: AppConstants.Actor.chef) ?? 0
        if availPts > 0 {
            HStack {
                Spacer()
                Text("可用點數：\(availPts)")
                    .font(.caption).foregroundStyle(.purple).fontWeight(.semibold)
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
        let level     = player?.skillLevel(nodeKey: node.key, actorKey: AppConstants.Actor.chef) ?? 0
        let isMaxed   = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let p = player else { return true }
            return p.skillLevel(nodeKey: prereqKey, actorKey: AppConstants.Actor.chef) >= node.prerequisiteLevel
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
                            .background(Color.purple.opacity(0.15))
                            .foregroundStyle(.purple).clipShape(Capsule())
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
                        nodeKey: node.key, actorKey: AppConstants.Actor.chef,
                        player: player, context: context) {
                        upgradeAlertMsg = errMsg
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3).foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Cuisine Row

    @ViewBuilder
    private func cuisineRow(_ cuisine: CuisineDef, canAfford: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(cuisine.icon)
                    .font(.title3)
                HStack(spacing: 6) {
                    if !canAfford {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    Text(cuisine.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? Color.primary : Color.secondary)
                }
                Spacer()
                Text(cuisine.durationDisplay)
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
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text(buffText(cuisine))
                    .font(.caption)
            }
            .foregroundStyle(.purple.opacity(0.85))

            HStack(spacing: 8) {
                ForEach(0..<cuisine.ingredients.count, id: \.self) { i in
                    let (mat, amount) = cuisine.ingredients[i]
                    let has = inventory?.amount(of: mat) ?? 0
                    Text("\(mat.icon)×\(amount)")
                        .font(.caption)
                        .foregroundStyle(has >= amount ? Color.primary : Color.red)
                }
                HStack(spacing: 3) {
                    Image(systemName: "coins").frame(width: 11, height: 11)
                    Text("×\(cuisine.goldCost)")
                }
                .font(.caption)
                .foregroundStyle((player?.gold ?? 0) >= cuisine.goldCost ? Color.primary : Color.red)
            }
        }
        .padding(.vertical, 4)
        .opacity(canAfford ? 1.0 : 0.55)
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
            npcKind: .chef, actorKey: AppConstants.Actor.chef, player: player)
        if case .failure(let err) = result { upgradeAlertMsg = err.message }
    }

    private func buffText(_ cuisine: CuisineDef) -> String {
        var parts: [String] = []
        if cuisine.atkBonus > 0 { parts.append("ATK +\(cuisine.atkBonus)") }
        if cuisine.defBonus > 0 { parts.append("DEF +\(cuisine.defBonus)") }
        if cuisine.hpBonus  > 0 { parts.append("HP +\(cuisine.hpBonus)") }
        return parts.joined(separator: "  ")
    }

    // MARK: - Action

    private func startCooking(cuisine: CuisineDef) {
        let result = viewModel.startCuisineTask(recipeKey: cuisine.key, context: context)
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
    CuisineSheet(
        viewModel: BaseViewModel(),
        appState: appState,
        player: nil,
        inventory: nil
    )
    .modelContainer(container)
}
