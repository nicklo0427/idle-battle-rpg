// CuisineSheet.swift
// 廚師配方 Sheet（V7-3）
//
// 觸發：點擊閒置的廚師 NPC
// 功能：選擇料理配方 → 建立烹飪任務，完成後獲得限時英雄 Buff
//
// 設計：
//   - 顯示所有料理配方（4 種，無解鎖門檻）
//   - 顯示所需素材 + 金幣 + 烹飪時間 + Buff 效果
//   - 素材或金幣不足時 row disabled + 紅色提示
//   - 顯示目前生效中的 Buff（若有）
//   - 建立成功後自動關閉 Sheet

import SwiftUI
import SwiftData

struct CuisineSheet: View {

    let viewModel: BaseViewModel
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {

                // ── 目前 Buff 狀態 ──────────────────────────────────────
                if let player, !player.activeCuisineKey.isEmpty,
                   player.cuisineBuffExpiresAt > Date().timeIntervalSinceReferenceDate,
                   let cuisine = CuisineDef.find(player.activeCuisineKey) {
                    Section("目前生效的料理 Buff") {
                        HStack(spacing: 12) {
                            Text(cuisine.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(cuisine.name)
                                    .fontWeight(.semibold)
                                Text(buffText(cuisine))
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                                Text("剩餘：\(CuisineDef.buffRemainingDisplay(expiresAt: player.cuisineBuffExpiresAt))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.purple)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // ── 目前資源摘要 ─────────────────────────────────────
                Section("目前資源") {
                    HStack {
                        Label("金幣", systemImage: "coins")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(player?.gold ?? 0)")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    // 顯示料理相關素材
                    let relatedMaterials: [MaterialType] = [.freshFish, .abyssFish, .herb, .spiritHerb, .ancientWood]
                    ForEach(relatedMaterials, id: \.self) { mat in
                        let amount = inventory?.amount(of: mat) ?? 0
                        HStack {
                            Text("\(mat.icon) \(mat.displayName)")
                                .foregroundStyle(amount > 0 ? .primary : .secondary)
                            Spacer()
                            Text("\(amount)")
                                .fontWeight(.medium)
                                .monospacedDigit()
                                .foregroundStyle(amount > 0 ? .primary : .secondary)
                        }
                    }
                }

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
                    Text("同一時間只能有一個料理 Buff，新 Buff 會覆蓋舊 Buff。")
                        .font(.caption)
                }
            }
            .navigationTitle("廚師")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .alert("無法烹飪", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
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

            // 不可用 badge
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

            // Buff 效果說明
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text(buffText(cuisine))
                    .font(.caption)
                Text("持續 \(buffDurationDisplay(cuisine.buffDuration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.purple.opacity(0.85))

            // 素材需求
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

    private func buffText(_ cuisine: CuisineDef) -> String {
        var parts: [String] = []
        if cuisine.atkBonus > 0 { parts.append("ATK +\(cuisine.atkBonus)") }
        if cuisine.defBonus > 0 { parts.append("DEF +\(cuisine.defBonus)") }
        if cuisine.hpBonus  > 0 { parts.append("HP +\(cuisine.hpBonus)") }
        return parts.joined(separator: "  ")
    }

    private func buffDurationDisplay(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 && m > 0 { return "\(h) 小時 \(m) 分" }
        if h > 0 { return "\(h) 小時" }
        return "\(m) 分鐘"
    }

    // MARK: - Action

    private func startCooking(cuisine: CuisineDef) {
        let result = viewModel.startCuisineTask(recipeKey: cuisine.key, context: context)
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
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    CuisineSheet(
        viewModel: BaseViewModel(),
        player: nil,
        inventory: nil,
        isPresented: $isPresented
    )
    .modelContainer(container)
}
