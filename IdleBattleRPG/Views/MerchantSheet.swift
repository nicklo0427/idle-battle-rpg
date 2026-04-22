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

                // ── 資源摘要（只顯示持有量 > 0 的素材，保持畫面簡潔）────
                Section("目前資源") {
                    HStack {
                        Label {
                        Text("金幣")
                    } icon: {
                        Image(systemName: "coins").frame(width: 16, height: 16)
                    }
                    .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(player?.gold ?? 0)")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    if let inv = inventory {
                        let ownedMats = MaterialType.allCases.filter { inv.amount(of: $0) > 0 }
                        if ownedMats.isEmpty {
                            Text("尚無素材")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        } else {
                            ForEach(ownedMats, id: \.self) { mat in
                                HStack {
                                    Text("\(mat.icon) \(mat.displayName)")
                                    Spacer()
                                    Text("\(inv.amount(of: mat))")
                                        .fontWeight(.medium)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                // ── 基礎素材出售（素材 → 金幣）──────────────────────
                Section {
                    ForEach(MerchantTradeDef.all.filter { $0.category == .basicMaterial }, id: \.key) { trade in
                        tradeRow(trade)
                    }
                } header: {
                    Text("基礎素材出售")
                } footer: {
                    Text("將多餘素材換成金幣。")
                        .font(.caption)
                }

                // ── 區域素材出售（V2-1 區域素材 → 金幣）────────────────
                Section {
                    ForEach(MerchantTradeDef.all.filter { $0.category == .areaMaterial }, id: \.key) { trade in
                        tradeRow(trade)
                    }
                } header: {
                    Text("區域素材出售")
                } footer: {
                    Text("地下城掉落的區域素材，可出售換取金幣。")
                        .font(.caption)
                }

                // ── 採集素材出售（V7-1 採集素材 → 金幣）────────────────
                Section {
                    ForEach(MerchantTradeDef.all.filter { $0.category == .gatherMaterial }, id: \.key) { trade in
                        tradeRow(trade)
                    }
                } header: {
                    Text("採集素材出售")
                } footer: {
                    Text("採集者帶回的素材，可出售換取金幣。")
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
                                HStack(spacing: 4) {
                                Image(systemName: "coins").frame(width: 14, height: 14)
                                Text("金幣 ×\(trade.goldCost)")
                                    .fontWeight(.medium)
                            }
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

    @ViewBuilder
    private func tradeRow(_ trade: MerchantTradeDef) -> some View {
        if case .gold(let goldAmt) = trade.receive {
            let have      = inventory?.amount(of: trade.giveMaterial) ?? 0
            let canAfford = have >= trade.giveAmount

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(trade.giveMaterial.icon) \(trade.giveMaterial.displayName) ×\(trade.giveAmount)")
                        .fontWeight(.medium)
                        .foregroundStyle(canAfford ? .primary : .secondary)
                    Text("持有 \(have)")
                        .font(.caption2)
                        .foregroundStyle(canAfford ? Color.secondary : Color.red)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "coins").frame(width: 14, height: 14)
                    Text("+\(goldAmt)")
                }
                .fontWeight(.semibold)
                .foregroundStyle(canAfford ? .yellow : .secondary)

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
