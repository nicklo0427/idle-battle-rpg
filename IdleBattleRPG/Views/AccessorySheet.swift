// AccessorySheet.swift
// 飾品師 Sheet（V10-1 T13）
//
// 功能：
//   - 顯示 .accessory slot 鑄造配方

import SwiftUI
import SwiftData

struct AccessorySheet: View {

    let appState:           AppState
    let player:             PlayerStateModel?
    let inventory:          MaterialInventoryModel?
    let progressionService: DungeonProgressionService

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var errorMessage: String?
    @State private var showError     = false
    @State private var showGrowthSheet = false

    // MARK: - Computed

    private var currentTier: Int { player?.tier(for: AppConstants.Actor.jeweler) ?? 0 }

    private var availableRecipes: [CraftRecipeDef] {
        CraftRecipeDef.available(isCleared: { floorKey in
            guard let sep = floorKey.range(of: "_floor_") else { return false }
            let prefix   = String(floorKey[floorKey.startIndex..<sep.lowerBound])
            let indexStr = String(floorKey[sep.upperBound...])
            guard let index = Int(indexStr) else { return false }
            let regionKeyMap: [String: String] = [
                "wildland": "wildland",
                "mine":     "abandoned_mine",
                "ruins":    "ancient_ruins",
                "sunken":   "sunken_city",
            ]
            guard let regionKey = regionKeyMap[prefix] else { return false }
            return progressionService.isFloorCleared(regionKey: regionKey, floorIndex: index)
        }, tutorialArmorUnlocked: player?.tutorialArmorRecipeUnlocked ?? false)
        .filter { $0.slot == .accessory }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                NPCDetailHeaderSection(
                    actorKey: AppConstants.Actor.jeweler,
                    fallbackName: "飾品師銀鈴",
                    roleName: "飾品製作",
                    imageName: "npc_jeweler",
                    color: .purple,
                    player: player,
                    currentTier: currentTier,
                    onGrowth: { showGrowthSheet = true },
                    onIntroSeen: markIntroSeen
                )
                recipeSection(title: "飾品", recipes: availableRecipes)
            }
            .navigationTitle(player?.npcDisplayName(for: AppConstants.Actor.jeweler) ?? "飾品師")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("無法鑄造", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
            .sheet(isPresented: $showGrowthSheet) {
                NPCGrowthSheet(
                    actorKey: AppConstants.Actor.jeweler,
                    fallbackName: "飾品師銀鈴",
                    roleName: "飾品製作",
                    imageName: "npc_jeweler",
                    color: .purple,
                    appState: appState,
                    viewModel: BaseViewModel()
                )
            }
        }
    }

    private func markIntroSeen() {
        player?.markNpcIntroSeen(for: AppConstants.Actor.jeweler)
        try? context.save()
    }

    // MARK: - Recipe Section

    private func recipeSection(title: String, recipes: [CraftRecipeDef]) -> some View {
        Section(title) {
            if recipes.isEmpty {
                Text("尚無可用飾品配方")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recipes, id: \.key) { recipe in
                    let canAfford = canAffordRecipe(recipe)
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
    }

    @ViewBuilder
    private func recipeRow(_ recipe: CraftRecipeDef, canAfford: Bool) -> some View {
        let materials = recipe.requiredMaterials
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    if !canAfford {
                        Image(systemName: "lock.fill")
                            .font(.caption).foregroundStyle(.red.opacity(0.7))
                    }
                    Text(recipe.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? recipe.rarity.displayColor : Color.secondary)
                }
                Spacer()
                Text(effectiveDurationDisplay(for: recipe))
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }

            if !canAfford {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption2)
                    Text("資源不足").font(.caption2).fontWeight(.medium)
                }
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color.red.opacity(0.10))
                .foregroundStyle(.red)
                .clipShape(Capsule())
            }

            if let equip = EquipmentDef.find(key: recipe.outputEquipmentKey) {
                HStack(spacing: 8) {
                    if equip.atkBonus > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "sword").frame(width: 11, height: 11)
                            Text("+\(equip.atkBonus)")
                        }.font(.caption2).foregroundStyle(.secondary)
                    }
                    if equip.defBonus > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "shield.fill").frame(width: 11, height: 11)
                            Text("+\(equip.defBonus)")
                        }.font(.caption2).foregroundStyle(.secondary)
                    }
                    if equip.hpBonus > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill").frame(width: 11, height: 11)
                            Text("+\(equip.hpBonus)")
                        }.font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                let goldCost = effectiveGoldCost(for: recipe)
                ForEach(materials, id: \.material) { (req: MaterialRequirement) in
                    let have = inventory?.amount(of: req.material) ?? 0
                    Text("\(req.material.icon) ×\(req.amount)")
                        .font(.caption2)
                        .foregroundColor(have >= req.amount ? .secondary : .red)
                }
                if recipe.goldCost > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "coins").frame(width: 10, height: 10)
                        Text("×\(goldCost)")
                    }
                    .font(.caption2)
                    .foregroundColor((player?.gold ?? 0) >= goldCost ? .secondary : .red)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(canAfford ? 1.0 : 0.6)
    }

    // MARK: - Helpers

    private func canAffordRecipe(_ recipe: CraftRecipeDef) -> Bool {
        guard let player, let inventory else { return false }
        let matOk  = recipe.requiredMaterials.allSatisfy { inventory.amount(of: $0.material) >= $0.amount }
        let goldOk = player.gold >= effectiveGoldCost(for: recipe)
        return matOk && goldOk
    }

    private func effectiveGoldCost(for recipe: CraftRecipeDef) -> Int {
        guard let player else { return recipe.goldCost }
        let actorKey = AppConstants.Actor.jeweler
        let goldNode = ProducerSkillNodeDef.nodes(for: actorKey)
            .first { $0.goldReductionPerPoint > 0 }
        let level = goldNode.map { player.skillLevel(nodeKey: $0.key, actorKey: actorKey) } ?? 0
        let discount = Double(level) * (goldNode?.goldReductionPerPoint ?? 0)
        return max(0, Int(Double(recipe.goldCost) * (1.0 - discount)))
    }

    private func effectiveDurationDisplay(for recipe: CraftRecipeDef) -> String {
        guard let player else { return recipe.durationDisplay }
        let actorKey = AppConstants.Actor.jeweler
        let tierMult = NpcUpgradeDef.craftDurationMultiplier(tier: player.tier(for: actorKey))
        let speedNode = ProducerSkillNodeDef.nodes(for: actorKey)
            .first { $0.speedReductionPerPoint > 0 }
        let level = speedNode.map { player.skillLevel(nodeKey: $0.key, actorKey: actorKey) } ?? 0
        let skillMult = 1.0 - Double(level) * (speedNode?.speedReductionPerPoint ?? 0)
        let seconds = max(30, Int(Double(recipe.durationSeconds) * tierMult * skillMult))
        return formatDuration(seconds)
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) 秒" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        if remainder == 0 { return "\(minutes) 分鐘" }
        return "\(minutes) 分 \(remainder) 秒"
    }

    private func startCraft(recipe: CraftRecipeDef) {
        do {
            try TaskCreationService(context: context).createAccessoryCraftTask(recipeKey: recipe.key)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
    }
}
