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
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?
    let progressionService: DungeonProgressionService
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @State private var errorMessage: String?
    @State private var showError = false

    private var isFirstCraft: Bool {
        guard let player else { return false }
        return !player.hasUsedFirstCraftBoost
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
            }
            .navigationTitle("鑄造師")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .alert("無法鑄造", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
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
                // 名稱 + 不可用圖示
                HStack(spacing: 6) {
                    if !canAfford {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    Text(recipe.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(canAfford ? Color.primary : Color.secondary)
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
                        Text("⚔️ \(range.lowerBound)–\(range.upperBound)（浮動）")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    } else {
                        if equip.atkBonus > 0 {
                            Text("⚔️ +\(equip.atkBonus)")
                                .font(.caption2)
                                .foregroundStyle(Color.secondary)
                        }
                        if equip.defBonus > 0 {
                            Text("🛡 +\(equip.defBonus)")
                                .font(.caption2)
                                .foregroundStyle(Color.secondary)
                        }
                        if equip.hpBonus > 0 {
                            Text("❤️ +\(equip.hpBonus)")
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
                Text("💰×\(recipe.goldCost)")
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

    // MARK: - Action

    private func startCraft(recipe: CraftRecipeDef) {
        let result = viewModel.startCraftTask(recipeKey: recipe.key, context: context)
        switch result {
        case .success:
            isPresented = false
        case .failure(let error):
            errorMessage = error.errorDescription
            showError = true
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self, DungeonProgressionModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    CraftSheet(
        viewModel: BaseViewModel(),
        player: nil,
        inventory: nil,
        progressionService: DungeonProgressionService(context: container.mainContext),
        isPresented: $isPresented
    )
    .modelContainer(container)
}
