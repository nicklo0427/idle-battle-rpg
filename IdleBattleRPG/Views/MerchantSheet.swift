// MerchantSheet.swift
// 商人固定商店 Sheet（V8-3 UX 優化）
//
// 功能：
//   - 賣出 Tab：子頁籤（素材 / 採集 / 農作物）+ 點選卡片 → 確認彈窗調整數量
//   - 購買 Tab：子頁籤（素材 / 種子）+ 點選卡片 → 確認彈窗調整數量
//
// 設計原則：
//   - 固定商品、固定價格，無每日刷新、無隨機
//   - 資源不足時卡片半透明 + disabled（不彈錯誤）
//   - @Query 驅動即時更新

import SwiftUI
import SwiftData

// MARK: - Tab 定義

private enum MerchantTab: String, CaseIterable {
    case sell = "賣出"
    case buy  = "購買"
}

private enum SellSubTab: String, CaseIterable {
    case material  = "素材"   // basicMaterial + areaMaterial + sunkenMaterial
    case gathering = "採集"   // gatherMaterial
    case crop      = "農作物"  // cropSell
}

private enum BuySubTab: String, CaseIterable {
    case rareMaterial = "素材"  // ancientFragment, spiritHerb, abyssFish
    case seed         = "種子"  // 4 seed types
}

// MARK: - Selection 包裝（sheet(item:) 用）

private struct SellTradeSelection: Identifiable {
    let id    = UUID()
    let trade: MerchantTradeDef
}

private struct BuyTradeSelection: Identifiable {
    let id:              UUID = UUID()
    let key:             String
    let goldCost:        Int
    let receiveMaterial: MaterialType
    let receiveAmount:   Int
}

// MARK: - MerchantSheet

struct MerchantSheet: View {

    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]

    @State private var tab        = MerchantTab.sell
    @State private var sellSubTab = SellSubTab.material
    @State private var buySubTab  = BuySubTab.rareMaterial

    @State private var selectedSellTrade: SellTradeSelection?
    @State private var selectedBuyTrade:  BuyTradeSelection?
    @State private var alertMessage:      String?

    private var player:    PlayerStateModel?       { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                goldHeaderView
                Divider()
                mainTabPicker
                Divider()
                subTabPicker
                Divider()
                ScrollView {
                    switch tab {
                    case .sell: sellGrid
                    case .buy:  buyGrid
                    }
                }
            }
            .navigationTitle("商人的市集")
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
            // 賣出確認 Sheet
            .sheet(item: $selectedSellTrade) { sel in
                SellConfirmSheet(
                    trade:     sel.trade,
                    inventory: inventory,
                    onConfirm: { times in
                        if case .failure(let err) = MerchantService(context: context)
                            .executeSellTrade(tradeKey: sel.trade.key, times: times) {
                            alertMessage = err.message
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            // 購買確認 Sheet
            .sheet(item: $selectedBuyTrade) { sel in
                BuyConfirmSheet(
                    trade:     sel,
                    player:    player,
                    onConfirm: { times in
                        if case .failure(let err) = MerchantService(context: context)
                            .executeBuyTrade(tradeKey: sel.key, times: times) {
                            alertMessage = err.message
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 金幣頭部

    private var goldHeaderView: some View {
        HStack {
            Image(systemName: "coins")
                .foregroundStyle(.yellow)
            Text("金幣")
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(player?.gold ?? 0)")
                .font(.title3).fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // MARK: - 主 Tab

    private var mainTabPicker: some View {
        Picker("", selection: $tab) {
            ForEach(MerchantTab.allCases, id: \.self) { t in
                Text(t.rawValue).tag(t)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 子 Tab

    @ViewBuilder
    private var subTabPicker: some View {
        switch tab {
        case .sell:
            Picker("", selection: $sellSubTab) {
                ForEach(SellSubTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        case .buy:
            Picker("", selection: $buySubTab) {
                ForEach(BuySubTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - 賣出 Grid

    @ViewBuilder
    private var sellGrid: some View {
        let trades: [MerchantTradeDef] = {
            switch sellSubTab {
            case .material:
                return MerchantTradeDef.all.filter {
                    $0.category == .basicMaterial ||
                    $0.category == .areaMaterial  ||
                    $0.category == .sunkenMaterial
                }
            case .gathering:
                return MerchantTradeDef.all.filter { $0.category == .gatherMaterial }
            case .crop:
                return MerchantTradeDef.all.filter { $0.category == .cropSell }
            }
        }()

        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(trades, id: \.key) { trade in
                let owned   = inventory?.amount(of: trade.giveMaterial) ?? 0
                let canSell = owned >= trade.giveAmount
                SellCard(
                    trade:   trade,
                    owned:   owned,
                    canSell: canSell,
                    onTap:   {
                        guard canSell else { return }
                        selectedSellTrade = SellTradeSelection(trade: trade)
                    }
                )
            }
        }
        .padding()
    }

    // MARK: - 購買 Grid

    @ViewBuilder
    private var buyGrid: some View {
        let trades: [(key: String, goldCost: Int, receiveMaterial: MaterialType, receiveAmount: Int)] = {
            // 前 3 = 稀有素材（ancientFragment, spiritHerb, abyssFish）
            // 後 4 = 種子
            let all = MerchantTradeDef.goldTrades
            switch buySubTab {
            case .rareMaterial: return Array(all.prefix(3))
            case .seed:         return Array(all.dropFirst(3))
            }
        }()

        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(trades, id: \.key) { trade in
                let canAfford = (player?.gold ?? 0) >= trade.goldCost
                BuyCard(
                    trade:     trade,
                    canAfford: canAfford,
                    onTap: {
                        guard canAfford else { return }
                        selectedBuyTrade = BuyTradeSelection(
                            key: trade.key, goldCost: trade.goldCost,
                            receiveMaterial: trade.receiveMaterial,
                            receiveAmount: trade.receiveAmount)
                    }
                )
            }
        }
        .padding()
    }
}

// MARK: - SellCard

private struct SellCard: View {
    let trade:   MerchantTradeDef
    let owned:   Int
    let canSell: Bool
    let onTap:   () -> Void

    private var priceText: String {
        if case .gold(let g) = trade.receive {
            return "×\(trade.giveAmount) → \(g)💰"
        }
        return ""
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(trade.giveMaterial.icon).font(.system(size: 26))
                Text(trade.giveMaterial.displayName)
                    .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                Text("持有 \(owned)")
                    .font(.caption2)
                    .foregroundStyle(canSell ? Color.secondary : Color.red)
                Text(priceText)
                    .font(.caption2)
                    .foregroundStyle(Color.orange)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(canSell ? Color.green.opacity(0.08) : Color.secondary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(canSell ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1))
            .opacity(canSell ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!canSell)
    }
}

// MARK: - BuyCard

private struct BuyCard: View {
    let trade:     (key: String, goldCost: Int, receiveMaterial: MaterialType, receiveAmount: Int)
    let canAfford: Bool
    let onTap:     () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(trade.receiveMaterial.icon).font(.system(size: 26))
                Text(trade.receiveMaterial.displayName)
                    .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                Text("×\(trade.receiveAmount)").font(.caption2).foregroundStyle(Color.secondary)
                Text("\(trade.goldCost)💰")
                    .font(.caption2)
                    .foregroundStyle(canAfford ? Color.orange : Color.red)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(canAfford ? Color.purple.opacity(0.08) : Color.secondary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(canAfford ? Color.purple.opacity(0.2) : Color.clear, lineWidth: 1))
            .opacity(canAfford ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!canAfford)
    }
}

// MARK: - SellConfirmSheet

private struct SellConfirmSheet: View {

    let trade:     MerchantTradeDef
    let inventory: MaterialInventoryModel?
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var qty: Int = 1

    private var owned:     Int    { inventory?.amount(of: trade.giveMaterial) ?? 0 }
    private var maxTimes:  Int    { max(1, owned / trade.giveAmount) }
    private var goldPerBatch: Int {
        if case .gold(let g) = trade.receive { return g }
        return 0
    }
    private var totalGold: Int { qty * goldPerBatch }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 商品資訊
                VStack(spacing: 8) {
                    Text(trade.giveMaterial.icon)
                        .font(.system(size: 52))
                    Text(trade.giveMaterial.displayName)
                        .font(.title3).fontWeight(.semibold)
                }
                .padding(.top, 8)

                Divider()

                // 說明行
                VStack(spacing: 6) {
                    infoRow(label: "持有數量", value: "\(owned) 個")
                    infoRow(label: "批次大小", value: "×\(trade.giveAmount) 個 → \(goldPerBatch) 💰")
                }
                .padding(.horizontal)

                Divider()

                // 數量 Stepper
                VStack(spacing: 8) {
                    HStack {
                        Text("賣出批次")
                            .fontWeight(.medium)
                        Spacer()
                        Stepper("\(qty) 批", value: $qty, in: 1...maxTimes)
                            .labelsHidden()
                        Text("\(qty) 批")
                            .monospacedDigit()
                            .frame(minWidth: 44, alignment: .trailing)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("預計獲得")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(totalGold) 💰")
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // 操作按鈕
                HStack(spacing: 16) {
                    Button("取消") { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    Button("確認賣出") {
                        onConfirm(qty)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("賣出")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { qty = 1 }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
    }
}

// MARK: - BuyConfirmSheet

private struct BuyConfirmSheet: View {

    let trade:     BuyTradeSelection
    let player:    PlayerStateModel?
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var qty: Int = 1

    private var currentGold: Int { player?.gold ?? 0 }
    private var maxTimes:    Int { max(1, currentGold / trade.goldCost) }
    private var totalCost:   Int { qty * trade.goldCost }
    private var totalReceive:Int { qty * trade.receiveAmount }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 商品資訊
                VStack(spacing: 8) {
                    Text(trade.receiveMaterial.icon)
                        .font(.system(size: 52))
                    Text(trade.receiveMaterial.displayName)
                        .font(.title3).fontWeight(.semibold)
                }
                .padding(.top, 8)

                Divider()

                // 說明行
                VStack(spacing: 6) {
                    infoRow(label: "目前金幣", value: "\(currentGold) 💰")
                    infoRow(label: "每次獲得", value: "×\(trade.receiveAmount) 個 / \(trade.goldCost) 💰")
                }
                .padding(.horizontal)

                Divider()

                // 數量 Stepper
                VStack(spacing: 8) {
                    HStack {
                        Text("購買次數")
                            .fontWeight(.medium)
                        Spacer()
                        Stepper("\(qty) 次", value: $qty, in: 1...maxTimes)
                            .labelsHidden()
                        Text("\(qty) 次")
                            .monospacedDigit()
                            .frame(minWidth: 44, alignment: .trailing)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("花費 / 獲得")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(totalCost) 💰  ×\(totalReceive) 個")
                            .fontWeight(.semibold)
                            .foregroundStyle(totalCost <= currentGold ? .orange : .red)
                            .monospacedDigit()
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // 操作按鈕
                HStack(spacing: 16) {
                    Button("取消") { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    Button("確認購買") {
                        onConfirm(qty)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .frame(maxWidth: .infinity)
                    .disabled(totalCost > currentGold)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("購買")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { qty = 1 }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    MerchantSheet(isPresented: .constant(true))
        .modelContainer(container)
}
