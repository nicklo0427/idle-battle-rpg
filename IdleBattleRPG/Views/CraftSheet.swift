// CraftSheet.swift
// 鑄造配方 Sheet
//
// 觸發：點擊閒置的鑄造師 NPC
// 功能：選擇鑄造配方 → 建立鑄造任務
//
// 設計：
//   - V1 配方（普通 / 精良）永遠顯示，共 6 個
//   - V2-1 配方（3 區域 × 4 部位）需首通對應樓層後顯示
//   - 顯示所需素材、金幣、時長
//   - 素材或金幣不足時 row disabled + 灰色提示
//   - 首件鑄造（hasUsedFirstCraftBoost == false）顯示「⚡ 特快 30 秒！」提示
//   - 建立成功後自動關閉 Sheet
//   - 建立失敗顯示錯誤 Alert

import SwiftUI
import SwiftData

struct CraftSheet: View {

    let viewModel: BaseViewModel
    let appState: AppState
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?
    let progressionService: DungeonProgressionService

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var upgradeExpanded: Bool = true
    @State private var detailTab:       DetailTab = .upgrade
    @State private var upgradeAlertMsg: String?
    @State private var errorMessage:    String?
    @State private var showError = false

    private enum DetailTab { case upgrade, skill }

    // MARK: - Computed

    private var currentTier: Int { player?.tier(for: AppConstants.Actor.blacksmith) ?? 0 }

    private var isFirstCraft: Bool {
        guard let player else { return false }
        return !player.hasUsedFirstCraftBoost
    }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let player else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: .blacksmith, actorKey: AppConstants.Actor.blacksmith, player: player)
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk  = player.heroExp >= cost.expCost
        let matOk  = cost.materialCosts.allSatisfy { inventory.amount(of: $0.0) >= $0.1 }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    /// 已解鎖的所有配方（V1 全顯示；V2-1 需首通樓層）
    private var availableRecipes: [CraftRecipeDef] {
        CraftRecipeDef.available { floorKey in
            // floorKey 格式："{prefix}_floor_{index}"
            // prefix → regionKey 對照表
            guard let sep = floorKey.range(of: "_floor_") else { return false }
            let prefix    = String(floorKey[floorKey.startIndex..<sep.lowerBound])
            let indexStr  = String(floorKey[sep.upperBound...])
            guard let index = Int(indexStr) else { return false }
            let regionKeyMap: [String: String] = [
                "wildland": "wildland",
                "mine":     "abandoned_mine",
                "ruins":    "ancient_ruins",
                "sunken":   "sunken_city",
            ]
            guard let regionKey = regionKeyMap[prefix] else { return false }
            return progressionService.isFloorCleared(regionKey: regionKey, floorIndex: index)
        }
    }

    var body: some View {
        NavigationStack {
            List {

                // ── 升級 Section（可收合）────────────────────────────────
                upgradeSection

                // ── 首件鑄造特快提示 ──────────────────────────────────────
                if isFirstCraft {
                    Section {
                        Label("首件鑄造特快！委派後 30 秒即可完成。", systemImage: "bolt.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                recipeSection(
                    title: "普通裝備",
                    recipes: availableRecipes.filter { $0.rarity == .common }
                )
                recipeSection(
                    title: "精良裝備",
                    recipes: availableRecipes.filter { $0.rarity == .refined }
                )
                recipeSection(
                    title: "稀有裝備",
                    recipes: availableRecipes.filter { $0.rarity == .rare }
                )
                recipeSection(
                    title: "史詩裝備",
                    recipes: availableRecipes.filter { $0.rarity == .epic }
                )
            }
            .navigationTitle("鑄造師")
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
            .alert("無法鑄造", isPresented: $showError) {
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
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 22)
                    Text(currentTier < NpcUpgradeDef.maxTier
                         ? "升級後加快鑄造速度"
                         : "已達升級上限")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TierBadgeView(tier: currentTier, alwaysShow: true, color: .orange)
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
                .tint(.orange)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    // MARK: - 技能頁

    @ViewBuilder
    private var skillContent: some View {
        let nodes    = ProducerSkillNodeDef.nodes(for: AppConstants.Actor.blacksmith)
        let availPts = player?.skillPoints(for: AppConstants.Actor.blacksmith) ?? 0
        if availPts > 0 {
            HStack {
                Spacer()
                Text("可用點數：\(availPts)")
                    .font(.caption).foregroundStyle(.orange).fontWeight(.semibold)
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
        let level     = player?.skillLevel(nodeKey: node.key, actorKey: AppConstants.Actor.blacksmith) ?? 0
        let isMaxed   = level >= node.maxLevel
        let prereqMet: Bool = {
            guard let prereqKey = node.prerequisiteKey, let p = player else { return true }
            return p.skillLevel(nodeKey: prereqKey, actorKey: AppConstants.Actor.blacksmith) >= node.prerequisiteLevel
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
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange).clipShape(Capsule())
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
                        nodeKey: node.key, actorKey: AppConstants.Actor.blacksmith,
                        player: player, context: context) {
                        upgradeAlertMsg = errMsg
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3).foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section Helper

    @ViewBuilder
    private func recipeSection(title: String, recipes: [CraftRecipeDef]) -> some View {
        Section(title) {
            ForEach(recipes, id: \.key) { recipe in
                let canAfford = viewModel.canAffordRecipe(recipe, player: player, inventory: inventory)
                Button {
                    startCraft(recipe: recipe)
                } label: {
                    recipeRow(recipe, canAfford: canAfford)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)
            }
        }
    }

    // MARK: - Recipe Row

    @ViewBuilder
    private func recipeRow(_ recipe: CraftRecipeDef, canAfford: Bool) -> some View {
        let materials = recipe.requiredMaterials
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // 名稱 + 不可用圖示 + 稀有度 badge
                HStack(spacing: 6) {
                    if !canAfford {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    Text(recipe.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? recipe.rarity.displayColor : Color.secondary)
                    if recipe.rarity == .rare || recipe.rarity == .epic {
                        Text(recipe.rarity.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(recipe.rarity.displayColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(recipe.rarity.displayColor.opacity(0.12), in: Capsule())
                    }
                }
                Spacer()
                // 時長永遠顯示（讓玩家知道等待成本）
                Text(recipe.durationDisplay)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .monospacedDigit()
            }

            // 不可用 badge（獨立一行，不搶奪時長位置）
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

            // 裝備屬性預覽
            if let equip = EquipmentDef.find(key: recipe.outputEquipmentKey) {
                HStack(spacing: 8) {
                    if equip.isBossWeapon, let range = equip.atkRange {
                        HStack(spacing: 3) {
                            Image(systemName: "figure.fencing").frame(width: 11, height: 11)
                            Text("\(range.lowerBound)–\(range.upperBound)（浮動）")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                    } else {
                        if equip.atkBonus > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "figure.fencing").frame(width: 11, height: 11)
                                Text("+\(equip.atkBonus)")
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        }
                        if equip.defBonus > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "shield.fill").frame(width: 11, height: 11)
                                Text("+\(equip.defBonus)")
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        }
                        if equip.hpBonus > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill").frame(width: 11, height: 11)
                                Text("+\(equip.hpBonus)")
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }

            // 素材需求
            HStack(spacing: 8) {
                ForEach(0..<materials.count, id: \.self) { i in
                    materialTag(materials[i])
                }
                HStack(spacing: 3) {
                    Image(systemName: "coins").frame(width: 11, height: 11)
                    Text("×\(recipe.goldCost)")
                }
                .font(.caption)
                .foregroundStyle((player?.gold ?? 0) >= recipe.goldCost ? Color.primary : Color.red)
            }
        }
        .padding(.vertical, 4)
        // 不可用時整行半透明 + 淡出
        .opacity(canAfford ? 1.0 : 0.55)
    }

    // MARK: - Material Tag Helper

    @ViewBuilder
    private func materialTag(_ req: MaterialRequirement) -> some View {
        let has = inventory?.amount(of: req.material) ?? 0
        Text("\(req.material.icon)×\(req.amount)")
            .font(.caption)
            .foregroundStyle(has >= req.amount ? Color.primary : Color.red)
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
            npcKind: .blacksmith, actorKey: AppConstants.Actor.blacksmith, player: player)
        if case .failure(let err) = result { upgradeAlertMsg = err.message }
    }

    // MARK: - Action

    private func startCraft(recipe: CraftRecipeDef) {
        let result = viewModel.startCraftTask(recipeKey: recipe.key, context: context)
        switch result {
        case .success:
            // 鑄造成功 → 自動推進新手引導 step 1
            if let player {
                viewModel.advanceOnboarding(expectedStep: 1, player: player, context: context)
            }
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
             EquipmentModel.self, TaskModel.self, DungeonProgressionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let appState = AppState(context: container.mainContext)
    CraftSheet(
        viewModel: BaseViewModel(),
        appState: appState,
        player: nil,
        inventory: nil,
        progressionService: DungeonProgressionService(context: container.mainContext)
    )
    .modelContainer(container)
}
