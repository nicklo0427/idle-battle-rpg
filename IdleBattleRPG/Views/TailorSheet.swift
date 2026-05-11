// TailorSheet.swift
// 裁縫師 Sheet（V10-1 T14）
//
// 功能：
//   - 顯示 .armor slot 鑄造配方
//   - step 5：材料不足引導（→ 冒險探索）
//   - step 7：教程防具鑄造（2 秒）

import SwiftUI
import SwiftData

struct TailorSheet: View {

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

    private var currentTier: Int { player?.tier(for: AppConstants.Actor.tailor) ?? 0 }

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
        }, tutorialArmorUnlocked: shouldShowTutorialArmorRecipe)
        .filter { $0.slot == .armor }
    }

    private var shouldShowTutorialArmorRecipe: Bool {
        guard let player else { return false }
        return player.tutorialArmorRecipeUnlocked || player.onboardingStep == 5 || player.onboardingStep == 7
    }

    private var tutorialDialogueRuns: [TutorialTextRun]? {
        switch player?.onboardingStep {
        case 5:
            return [
                .plain("你已經找到"),
                .action("裁縫師阿針"),
                .plain("。這件"),
                .equipment("護甲"),
                .plain("需要野外的"),
                .material("乾燥獸皮"),
                .plain("，先去"),
                .location("金穗之野"),
                .action("探索"),
                .plain("取得素材。"),
            ]
        case 7:
            return [
                .material("素材"),
                .plain("都到手了。交給"),
                .action("裁縫師阿針"),
                .plain("，縫製一件正式的"),
                .equipment("護甲"),
                .plain("。"),
            ]
        default:
            return nil
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                NPCDetailHeaderSection(
                    actorKey: AppConstants.Actor.tailor,
                    fallbackName: "裁縫師阿針",
                    roleName: "防具製作",
                    imageName: "npc_tailor",
                    color: .teal,
                    player: player,
                    currentTier: currentTier,
                    dialogueRichTextOverride: tutorialDialogueRuns,
                    onGrowth: { showGrowthSheet = true },
                    onIntroSeen: markIntroSeen
                )
                recipeSection(title: "防具", recipes: availableRecipes)
            }
            .navigationTitle(player?.npcDisplayName(for: AppConstants.Actor.tailor) ?? "裁縫師")
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
                    actorKey: AppConstants.Actor.tailor,
                    fallbackName: "裁縫師阿針",
                    roleName: "防具製作",
                    imageName: "npc_tailor",
                    color: .teal,
                    appState: appState,
                    viewModel: BaseViewModel()
                )
            }
        }
    }

    private func markIntroSeen() {
        player?.markNpcIntroSeen(for: AppConstants.Actor.tailor)
        try? context.save()
    }

    // MARK: - Recipe Section

    private func recipeSection(title: String, recipes: [CraftRecipeDef]) -> some View {
        Section(title) {
            if recipes.isEmpty {
                Text("尚無可用防具配方")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recipes, id: \.key) { recipe in
                    let canAfford = isTutorialArmorRecipe(recipe) || canAffordRecipe(recipe)
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
        let isTutorialRecipe = isTutorialArmorRecipe(recipe)
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
                    // 引導 step 7：標示目標配方
                    if player?.onboardingStep == 7, recipe.outputEquipmentKey == "wildland_armor" {
                        Text("推薦")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Text(isTutorialRecipe ? "2 秒" : effectiveDurationDisplay(for: recipe))
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

            if isTutorialRecipe {
                Label("教學製作不消耗素材與金幣", systemImage: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
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
        }
        .padding(.vertical, 4)
        .opacity(canAfford ? 1.0 : 0.6)
    }

    // MARK: - Helpers

    private func isTutorialArmorRecipe(_ recipe: CraftRecipeDef) -> Bool {
        player?.onboardingStep == 7 && recipe.outputEquipmentKey == "wildland_armor"
    }

    private func canAffordRecipe(_ recipe: CraftRecipeDef) -> Bool {
        guard let player, let inventory else { return false }
        let matOk  = recipe.requiredMaterials.allSatisfy { inventory.amount(of: $0.material) >= $0.amount }
        let goldOk = player.gold >= effectiveGoldCost(for: recipe)
        return matOk && goldOk
    }

    private func effectiveGoldCost(for recipe: CraftRecipeDef) -> Int {
        guard let player else { return recipe.goldCost }
        let actorKey = AppConstants.Actor.tailor
        let goldNode = ProducerSkillNodeDef.nodes(for: actorKey)
            .first { $0.goldReductionPerPoint > 0 }
        let level = goldNode.map { player.skillLevel(nodeKey: $0.key, actorKey: actorKey) } ?? 0
        let discount = Double(level) * (goldNode?.goldReductionPerPoint ?? 0)
        return max(0, Int(Double(recipe.goldCost) * (1.0 - discount)))
    }

    private func effectiveDurationDisplay(for recipe: CraftRecipeDef) -> String {
        guard let player else { return recipe.durationDisplay }
        let actorKey = AppConstants.Actor.tailor
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
            // 引導 step 7：wildland_armor 用 2 秒 tutorial 任務
            if player?.onboardingStep == 7, recipe.outputEquipmentKey == "wildland_armor" {
                try TaskCreationService(context: context).createTutorialArmorTask()
            } else {
                try TaskCreationService(context: context).createTailorCraftTask(recipeKey: recipe.key)
            }
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
    }
}
