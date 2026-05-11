// NPCGrowthSheet.swift
// 共用 NPC 養成彈窗：升級 / 技能

import SwiftUI
import SwiftData

struct NPCGrowthSheet: View {

    let actorKey: String
    let fallbackName: String
    let roleName: String
    let imageName: String
    let color: Color
    let appState: AppState
    let viewModel: BaseViewModel

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var players: [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]

    @State private var tab: GrowthTab = .upgrade
    @State private var alertMsg: String?

    private enum GrowthTab { case upgrade, skill }
    private enum SkillSource: Equatable { case gatherer, producer, unavailable }

    private var player: PlayerStateModel? { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }
    private var displayName: String { player?.npcDisplayName(for: actorKey) ?? fallbackName }
    private var currentTier: Int { player?.tier(for: actorKey) ?? 0 }
    private var npcKind: NpcKind? { player?.npcKind(for: actorKey) }
    private var source: SkillSource {
        if actorKey.hasPrefix("gatherer_") { return .gatherer }
        if !ProducerSkillNodeDef.nodes(for: actorKey).isEmpty { return .producer }
        return .unavailable
    }
    private var hasGrowth: Bool { npcKind != nil && source != .unavailable }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player, let npcKind else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: npcKind,
            actorKey: actorKey,
            player: player
        )
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk = player.heroExp >= cost.expCost
        let matOk = cost.materialCosts.allSatisfy { inventory.amount(of: $0.0) >= $0.1 }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    var body: some View {
        NavigationStack {
            List {
                headerSection

                if hasGrowth {
                    Section {
                        Picker("", selection: $tab) {
                            Text("升級").tag(GrowthTab.upgrade)
                            Text("技能").tag(GrowthTab.skill)
                        }
                        .pickerStyle(.segmented)

                        if tab == .upgrade {
                            upgradeContent
                        } else {
                            skillContent
                        }
                    }
                } else {
                    Section {
                        ContentUnavailableView(
                            "養成尚未開放",
                            systemImage: "lock.circle",
                            description: Text("這位 NPC 目前沒有升級或技能內容。")
                        )
                    }
                }
            }
            .navigationTitle("NPC 養成")
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
        }
        .onAppear {
            if player?.onboardingStep == 20, actorKey == AppConstants.Actor.gatherer1 {
                appState.onboardingService.prepareForCurrentStep()
                tab = .upgrade
            }
            if player?.onboardingStep == 21, actorKey == AppConstants.Actor.gatherer1 {
                tab = .skill
            }
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                NPCPortraitView(
                    imageName: imageName,
                    width: 88,
                    height: 88,
                    cornerRadius: 14,
                    padding: 7
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(roleName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TierBadgeView(tier: currentTier, alwaysShow: true, color: color)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var upgradeContent: some View {
        if currentTier >= NpcUpgradeDef.maxTier || upgradeCost == nil {
            HStack {
                Label("已達升級上限 T\(currentTier)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 10)
        } else if let cost = upgradeCost, let player {
            upgradeRow(label: "EXP", required: cost.expCost, have: player.heroExp)
            ForEach(cost.materialCosts, id: \.0) { mat, req in
                Divider()
                upgradeRow(label: "\(mat.icon) \(mat.displayName)", required: req, have: inventory?.amount(of: mat) ?? 0)
            }
            Divider()
            upgradeRow(label: "金幣", required: cost.goldCost, have: player.gold)
            Button("升至 T\(currentTier + 1)") { performUpgrade() }
                .buttonStyle(.borderedProminent)
                .tint(color)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade || (player.onboardingStep == 20 && actorKey != AppConstants.Actor.gatherer1))
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private var skillContent: some View {
        switch source {
        case .gatherer:
            gathererSkillContent
        case .producer:
            producerSkillContent
        case .unavailable:
            Text("尚無技能節點")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var gathererSkillContent: some View {
        let nodes = GathererSkillNodeDef.nodes(for: actorKey)
        let availPts = player?.skillPoints(for: actorKey) ?? 0
        VStack(spacing: 0) {
            skillPointHeader(availPts)
            ForEach(nodes, id: \.key) { node in
                gathererSkillNodeRow(node, availPoints: availPts)
                if node.key != nodes.last?.key { Divider() }
            }
        }
    }

    @ViewBuilder
    private var producerSkillContent: some View {
        let nodes = ProducerSkillNodeDef.nodes(for: actorKey)
        let availPts = player?.skillPoints(for: actorKey) ?? 0
        VStack(spacing: 0) {
            skillPointHeader(availPts)
            ForEach(nodes, id: \.key) { node in
                producerSkillNodeRow(node, availPoints: availPts)
                if node.key != nodes.last?.key { Divider() }
            }
        }
    }

    @ViewBuilder
    private func skillPointHeader(_ points: Int) -> some View {
        HStack {
            Spacer()
            Text("可用點數：\(points)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(points > 0 ? color : Color.secondary)
        }
        .padding(.vertical, 8)
        Divider()
    }

    @ViewBuilder
    private func gathererSkillNodeRow(_ node: GathererSkillNodeDef, availPoints: Int) -> some View {
        let level = player?.skillLevel(nodeKey: node.key, actorKey: actorKey) ?? 0
        let isMaxed = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let player else { return true }
            return player.skillLevel(nodeKey: prereqKey, actorKey: actorKey) >= node.prerequisiteLevel
        }()
        let canInvest = !isMaxed && prereqMet && availPoints > 0 && tutorialAllowsSkillInvest(nodeKey: node.key)
        skillRow(
            name: node.name,
            description: node.description,
            level: level,
            maxLevel: node.maxLevel,
            isMaxed: isMaxed,
            prereqText: prereqText(key: node.prerequisiteKey, level: node.prerequisiteLevel, isMet: prereqMet, gatherer: true),
            canInvest: canInvest,
            onInvest: {
                guard let player else { return }
                alertMsg = viewModel.investGathererSkillPoint(
                    nodeKey: node.key,
                    actorKey: actorKey,
                    player: player,
                    context: context
                )
                if alertMsg == nil,
                   player.onboardingStep == 21,
                   actorKey == AppConstants.Actor.gatherer1,
                   node.key == "g1_yield" {
                    appState.onboardingService.advance(player: player, from: 21, to: 22)
                    dismiss()
                }
            }
        )
    }

    @ViewBuilder
    private func producerSkillNodeRow(_ node: ProducerSkillNodeDef, availPoints: Int) -> some View {
        let level = player?.skillLevel(nodeKey: node.key, actorKey: actorKey) ?? 0
        let isMaxed = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let player else { return true }
            return player.skillLevel(nodeKey: prereqKey, actorKey: actorKey) >= node.prerequisiteLevel
        }()
        let canInvest = !isMaxed && prereqMet && availPoints > 0 && tutorialAllowsSkillInvest(nodeKey: node.key)
        skillRow(
            name: node.name,
            description: node.description,
            level: level,
            maxLevel: node.maxLevel,
            isMaxed: isMaxed,
            prereqText: prereqText(key: node.prerequisiteKey, level: node.prerequisiteLevel, isMet: prereqMet, gatherer: false),
            canInvest: canInvest,
            onInvest: {
                guard let player else { return }
                alertMsg = viewModel.investProducerSkillPoint(
                    nodeKey: node.key,
                    actorKey: actorKey,
                    player: player,
                    context: context
                )
            }
        )
    }

    private func skillRow(
        name: String,
        description: String,
        level: Int,
        maxLevel: Int,
        isMaxed: Bool,
        prereqText: String?,
        canInvest: Bool,
        onInvest: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name).fontWeight(.medium)
                    Text("Lv.\(level)/\(maxLevel)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    if isMaxed {
                        Text("已滿")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15))
                            .foregroundStyle(color)
                            .clipShape(Capsule())
                    }
                }
                Text(prereqText ?? description)
                    .font(.caption)
                    .foregroundStyle(prereqText == nil ? Color.secondary : Color(.tertiaryLabel))
            }
            Spacer()
            if canInvest {
                Button(action: onInvest) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(color)
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
            Text("\(have)/\(required)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(have >= required ? Color.secondary : Color.red)
        }
        .padding(.vertical, 8)
    }

    private func performUpgrade() {
        guard let player, let npcKind else { return }
        let result = appState.npcUpgradeService.upgrade(
            npcKind: npcKind,
            actorKey: actorKey,
            player: player
        )
        if case .failure(let error) = result {
            alertMsg = error.message
        } else if player.onboardingStep == 20, actorKey == AppConstants.Actor.gatherer1 {
            appState.onboardingService.advance(player: player, from: 20, to: 21)
            tab = .skill
        }
    }

    private func tutorialAllowsSkillInvest(nodeKey: String) -> Bool {
        guard let player, player.onboardingStep < OnboardingService.completedStep else { return true }
        if player.onboardingStep == 21 {
            return actorKey == AppConstants.Actor.gatherer1 && nodeKey == "g1_yield"
        }
        if player.onboardingStep == 20 {
            return false
        }
        return true
    }

    private func prereqText(key: String?, level: Int, isMet: Bool, gatherer: Bool) -> String? {
        guard !isMet, let key else { return nil }
        let name: String?
        if gatherer {
            name = GathererSkillNodeDef.find(key: key)?.name
        } else {
            name = ProducerSkillNodeDef.find(key: key)?.name
        }
        return "需先點「\(name ?? key)」達 \(level) 級"
    }
}
