// PharmacySheet.swift
// 製藥師配方 Sheet（V7-4）
//
// 觸發：點擊閒置的製藥師 NPC
// 功能：選擇藥水配方 → 建立煉藥任務，完成後藥水進消耗品背包

import SwiftUI
import SwiftData

struct PharmacySheet: View {

    let viewModel: BaseViewModel
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @Query private var consumables: [ConsumableInventoryModel]
    private var consumable: ConsumableInventoryModel? { consumables.first }

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {

                // ── 消耗品背包（料理 + 藥水全顯示）──────────────────────
                Section("消耗品背包") {
                    ForEach(ConsumableType.allCases, id: \.self) { type in
                        let count = consumable?.amount(of: type) ?? 0
                        HStack {
                            Text("\(type.icon) \(type.displayName)")
                                .foregroundStyle(count > 0 ? .primary : .secondary)
                            Spacer()
                            Text("\(count)")
                                .monospacedDigit()
                                .foregroundStyle(count > 0 ? .primary : .secondary)
                        }
                    }
                }

                // ── 目前資源 ─────────────────────────────────────────────
                Section("目前資源") {
                    HStack {
                        Label("金幣", systemImage: "coins")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(player?.gold ?? 0)")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    let relatedMaterials: [MaterialType] = [.wheat, .vegetable, .fruit, .spiritGrain]
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .alert("無法煉製", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
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
             ConsumableInventoryModel.self, EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    PharmacySheet(
        viewModel: BaseViewModel(),
        player: nil,
        inventory: nil,
        isPresented: $isPresented
    )
    .modelContainer(container)
}
