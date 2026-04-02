// CraftSheet.swift
// 鑄造配方 Sheet
//
// 觸發：點擊閒置的鑄造師 NPC
// 功能：選擇鑄造配方 → 建立鑄造任務
//
// 設計：
//   - 列出全部 6 個配方（普通 / 精良 分組）
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
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @State private var errorMessage: String?
    @State private var showError = false

    private var isFirstCraft: Bool {
        guard let player else { return false }
        return !player.hasUsedFirstCraftBoost
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
                    recipes: CraftRecipeDef.all.filter { $0.rarity == .common }
                )
                recipeSection(
                    title: "精良裝備",
                    recipes: CraftRecipeDef.all.filter { $0.rarity == .refined }
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
                Text(recipe.name)
                    .fontWeight(.semibold)
                    .foregroundStyle(canAfford ? Color.primary : Color.secondary)
                Spacer()
                Text(recipe.durationDisplay)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .monospacedDigit()
            }

            // 素材需求（range-based ForEach 避免 Binding<C> 推斷問題）
            HStack(spacing: 8) {
                ForEach(0..<materials.count, id: \.self) { i in
                    materialTag(materials[i])
                }
                Text("💰×\(recipe.goldCost)")
                    .font(.caption)
                    .foregroundStyle((player?.gold ?? 0) >= recipe.goldCost ? Color.primary : Color.red)
            }

            if !canAfford {
                Text("資源不足")
                    .font(.caption2)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.vertical, 2)
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
    CraftSheet(
        viewModel: BaseViewModel(),
        player: nil,
        inventory: nil,
        isPresented: $isPresented
    )
    .modelContainer(for: [
        PlayerStateModel.self, MaterialInventoryModel.self,
        EquipmentModel.self, TaskModel.self,
    ], inMemory: true)
}
