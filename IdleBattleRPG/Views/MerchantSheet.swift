// MerchantSheet.swift
// 商人固定商店 Sheet
//
// 功能：
//   - 顯示玩家當前金幣與各素材持有量
//   - 出售區：素材 → 金幣（MerchantTradeDef.all）
//   - 補給區：金幣 → 古代碎片（MerchantTradeDef.goldTrades）
//
// 設計原則：
//   - 固定商品、固定價格，無每日刷新、無隨機
//   - 資源不足時按鈕 disabled（不彈錯誤，一看就懂）
//   - 成功後 @Query 驅動畫面即時更新

import SwiftUI
import SwiftData

struct MerchantSheet: View {

    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]

    @State private var alertMessage: String?

    // MARK: - 計算屬性

    private var player:    PlayerStateModel?        { players.first }
    private var inventory: MaterialInventoryModel?  { inventories.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // ── 資源摘要 ─────────────────────────────────────────
                Section("目前資源") {
                    HStack {
                        Label("金幣", systemImage: "dollarsign.circle.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(player?.gold ?? 0)")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    if let inv = inventory {
                        ForEach(MaterialType.allCases, id: \.self) { mat in
                            let amount = inv.amount(of: mat)
                            HStack {
                                Text("\(mat.icon) \(mat.displayName)")
                                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                                Spacer()
                                Text("\(amount)")
                                    .monospacedDigit()
                                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                            }
                        }
                    }
                }

                // ── 出售（素材 → 金幣）──────────────────────────────
                Section {
                    ForEach(MerchantTradeDef.all, id: \.key) { trade in
                        if case .gold(let goldAmt) = trade.receive {
                            let have      = inventory?.amount(of: trade.giveMaterial) ?? 0
                            let canAfford = have >= trade.giveAmount

                            HStack(spacing: 10) {
                                // 給出
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(trade.giveMaterial.icon) \(trade.giveMaterial.displayName) ×\(trade.giveAmount)")
                                        .fontWeight(.medium)
                                        .foregroundStyle(canAfford ? .primary : .secondary)
                                    Text("持有 \(have)")
                                        .font(.caption2)
                                        .foregroundStyle(canAfford ? Color.secondary : Color.red)
                                }

                                Spacer()

                                // 獲得
                                Text("💰 +\(goldAmt)")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(canAfford ? .yellow : .secondary)

                                // 執行按鈕
                                Button("出售") {
                                    execute { MerchantService(context: context).executeSellTrade(tradeKey: trade.key) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(!canAfford)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("出售素材")
                } footer: {
                    Text("將多餘素材換成金幣。")
                        .font(.caption)
                }

                // ── 補給（金幣 → 稀有素材）──────────────────────────
                Section {
                    ForEach(MerchantTradeDef.goldTrades, id: \.key) { trade in
                        let gold      = player?.gold ?? 0
                        let canAfford = gold >= trade.goldCost

                        HStack(spacing: 10) {
                            // 給出
                            VStack(alignment: .leading, spacing: 2) {
                                Text("💰 金幣 ×\(trade.goldCost)")
                                    .fontWeight(.medium)
                                    .foregroundStyle(canAfford ? .primary : .secondary)
                                Text("持有 \(gold)")
                                    .font(.caption2)
                                    .foregroundStyle(canAfford ? Color.secondary : Color.red)
                            }

                            Spacer()

                            // 獲得
                            Text("\(trade.receiveMaterial.icon) +\(trade.receiveAmount)")
                                .fontWeight(.semibold)
                                .foregroundStyle(canAfford ? .purple : .secondary)

                            // 執行按鈕
                            Button("購買") {
                                execute { MerchantService(context: context).executeBuyTrade(tradeKey: trade.key) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .disabled(!canAfford)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("補給採購")
                } footer: {
                    Text("以高價購入稀有素材，作為補充手段。")
                        .font(.caption)
                }
            }
            .navigationTitle("商人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("關閉") { isPresented = false }
                }
            }
            .alert("交易失敗", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("確定", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Private

    /// 執行交易，失敗時設置 alert 訊息（成功時 @Query 自動刷新）
    private func execute(_ trade: () -> Result<Void, MerchantTradeError>) {
        if case .failure(let err) = trade() {
            alertMessage = err.message
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    MerchantSheet(isPresented: .constant(true))
        .modelContainer(container)
}
