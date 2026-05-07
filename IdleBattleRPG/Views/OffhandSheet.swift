// OffhandSheet.swift
// 鍛造學徒 Sheet（V10-1 T12）
//
// 功能：
//   - 顯示 .offhand slot 鑄造配方

import SwiftUI
import SwiftData

struct OffhandSheet: View {

    let appState:           AppState
    let player:             PlayerStateModel?
    let inventory:          MaterialInventoryModel?
    let progressionService: DungeonProgressionService

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var errorMessage: String?
    @State private var showError     = false

    // MARK: - Computed

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
        .filter { $0.slot == .offhand }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                NpcIntroSection(actorKey: AppConstants.Actor.weaponsmith)
                recipeSection(title: "副手", recipes: availableRecipes)
            }
            .navigationTitle(player?.npcDisplayName(for: AppConstants.Actor.weaponsmith) ?? "鍛造學徒")
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
        }
    }

    // MARK: - Recipe Section

    private func recipeSection(title: String, recipes: [CraftRecipeDef]) -> some View {
        Section(title) {
            if recipes.isEmpty {
                Text("尚無可用副手配方")
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
                Text(recipe.durationDisplay)
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
                ForEach(materials, id: \.material) { (req: MaterialRequirement) in
                    let have = inventory?.amount(of: req.material) ?? 0
                    Text("\(req.material.icon) ×\(req.amount)")
                        .font(.caption2)
                        .foregroundColor(have >= req.amount ? .secondary : .red)
                }
                if recipe.goldCost > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "coins").frame(width: 10, height: 10)
                        Text("×\(recipe.goldCost)")
                    }
                    .font(.caption2)
                    .foregroundColor((player?.gold ?? 0) >= recipe.goldCost ? .secondary : .red)
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
        let goldOk = player.gold >= recipe.goldCost
        return matOk && goldOk
    }

    private func startCraft(recipe: CraftRecipeDef) {
        do {
            try TaskCreationService(context: context).createOffhandCraftTask(recipeKey: recipe.key)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
    }
}
