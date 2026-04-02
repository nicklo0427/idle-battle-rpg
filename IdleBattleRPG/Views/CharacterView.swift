// CharacterView.swift
// 角色 Tab — Phase 8
//
// Segment Control：裝備 / 背包
//
// 裝備 Segment：
//   - 英雄狀態（等級、金幣、戰力、ATK/DEF/HP + 屬性點分配按鈕）
//   - 升級區塊（費用、升級按鈕）
//   - 已裝備欄位（3 部位，點擊 → 裝備選擇 Sheet）
//
// 背包 Segment：
//   - 素材庫存（5 種）
//   - 未裝備裝備列表（點擊 → 裝備）

import SwiftUI
import SwiftData

// MARK: - Segment 定義

private enum CharacterSegment: String, CaseIterable {
    case gear     = "裝備"
    case backpack = "背包"
}

// MARK: - CharacterView

struct CharacterView: View {

    @Environment(\.modelContext) private var context

    @Query private var players:     [PlayerStateModel]
    @Query private var equipments:  [EquipmentModel]
    @Query private var inventories: [MaterialInventoryModel]

    @State private var viewModel   = CharacterViewModel()
    @State private var segment     = CharacterSegment.gear
    @State private var alertMsg: String?

    // 裝備選擇 Sheet：記錄要切換的部位
    @State private var equipSheetSlot: EquipmentSlot?

    // MARK: - 計算屬性

    private var player: PlayerStateModel? { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var equippedItems: [EquipmentModel] {
        viewModel.equippedItems(from: equipments)
    }

    private var heroStats: HeroStats? {
        viewModel.heroStats(player: player, equipped: equippedItems)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // ── Segment Picker ───────────────────────────────────
                Picker("", selection: $segment) {
                    ForEach(CharacterSegment.allCases, id: \.self) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))

                switch segment {
                case .gear:     gearSegment
                case .backpack: backpackSegment
                }
            }
            .navigationTitle("角色")
            .alert("提示", isPresented: Binding(
                get: { alertMsg != nil },
                set: { if !$0 { alertMsg = nil } }
            )) {
                Button("確定", role: .cancel) { alertMsg = nil }
            } message: {
                Text(alertMsg ?? "")
            }
            // 裝備選擇 Sheet
            .sheet(item: $equipSheetSlot) { slot in
                EquipSelectSheet(
                    slot: slot,
                    candidates: viewModel.unequippedItems(slot: slot, from: equipments)
                ) { chosen in
                    if let item = chosen {
                        viewModel.equip(item, context: context)
                    }
                    equipSheetSlot = nil
                }
            }
        }
    }

    // MARK: - 裝備 Segment

    @ViewBuilder
    private var gearSegment: some View {

        // ── 英雄屬性 ────────────────────────────────────────────────
        Section {
            if let player {
                infoRow(label: "等級", value: "Lv.\(player.heroLevel)")
                infoRow(label: "金幣", value: "\(player.gold) 💰")
            }
            if let stats = heroStats {
                Divider()
                powerRow(stats.power)
                Divider()
                if let player {
                    statAllocRow(label: "⚔️ ATK", value: stats.totalATK, stat: .atk, player: player)
                    statAllocRow(label: "🛡 DEF",  value: stats.totalDEF, stat: .def, player: player)
                    statAllocRow(label: "❤️ HP",   value: stats.totalHP,  stat: .hp,  player: player)

                    if player.availableStatPoints > 0 {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            Text("可分配點數：\(player.availableStatPoints)")
                                .foregroundStyle(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Text("英雄屬性")
        }

        // ── 升級 ────────────────────────────────────────────────────
        if let player {
            Section {
                if viewModel.isMaxLevel(player: player) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.yellow)
                        Text("已達最高等級 Lv.\(AppConstants.Game.heroMaxLevel)")
                            .foregroundStyle(.secondary)
                    }
                } else if let cost = viewModel.nextLevelCost(player: player) {
                    let canAfford = player.gold >= cost
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("升至 Lv.\(player.heroLevel + 1)")
                                .fontWeight(.medium)
                            if canAfford {
                                Text("費用：\(cost) 金幣 · 獲得 \(AppConstants.Game.statPointsPerLevel) 屬性點")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("需要 \(cost) 金幣・還差 \(cost - player.gold) 枚")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Button("升級") {
                            if let msg = viewModel.levelUp(player: player, context: context) {
                                alertMsg = msg
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAfford)
                    }
                }
            } header: {
                Text("升級")
            }
        }

        // ── 已裝備欄位 ──────────────────────────────────────────────
        Section {
            ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                let item = equippedItems.first { $0.slot == slot }
                equippedSlotRow(slot: slot, item: item)
            }
        } header: {
            Text("已裝備（\(viewModel.equippedCount(from: equipments)) / 3）")
        } footer: {
            Text("點擊裝備欄位可切換，點擊已裝備圖示可卸除")
                .font(.caption)
        }
    }

    // MARK: - 背包 Segment

    @ViewBuilder
    private var backpackSegment: some View {

        // ── 素材庫存 ────────────────────────────────────────────────
        Section("素材庫存") {
            if let inv = inventory {
                ForEach(MaterialType.allCases, id: \.self) { mat in
                    HStack {
                        Text("\(mat.icon) \(mat.displayName)")
                        Spacer()
                        Text("\(inv.amount(for: mat))")
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                }
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }

        // ── 未裝備裝備 ──────────────────────────────────────────────
        let unequipped = viewModel.unequippedItems(from: equipments)
        Section {
            if unequipped.isEmpty {
                Text("背包中沒有裝備")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(unequipped) { item in
                    Button {
                        viewModel.equip(item, context: context)
                    } label: {
                        backpackItemRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("裝備（\(unequipped.count) 件未裝備）")
        } footer: {
            Text("點擊裝備可直接穿上")
                .font(.caption)
        }
    }

    // MARK: - Row Helpers

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func powerRow(_ power: Int) -> some View {
        HStack {
            Text("戰力").foregroundStyle(.secondary)
            Spacer()
            Text("\(power)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.yellow)
                .monospacedDigit()
        }
    }

    /// 屬性行 + 右側 +1 分配按鈕（有可用點數時顯示）
    @ViewBuilder
    private func statAllocRow(
        label: String, value: Int,
        stat: StatType, player: PlayerStateModel
    ) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .fontWeight(.semibold)
                .monospacedDigit()
            if player.availableStatPoints > 0 {
                Button {
                    viewModel.allocatePoint(to: stat, player: player, context: context)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 裝備槽 row：點整列 → 開 EquipSelectSheet；點右側卸除圖示 → 卸除
    @ViewBuilder
    private func equippedSlotRow(slot: EquipmentSlot, item: EquipmentModel?) -> some View {
        HStack {
            Text(slot.icon).frame(width: 28)
            Text(slot.displayName).foregroundStyle(.secondary)
            Spacer()
            if let item {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(item.displayName).fontWeight(.medium)
                    Text(item.rarity.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                // 卸除按鈕
                Button {
                    viewModel.unequip(item, context: context)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            } else {
                Text("未裝備")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            equipSheetSlot = slot
        }
    }

    @ViewBuilder
    private func backpackItemRow(_ item: EquipmentModel) -> some View {
        HStack {
            Text(item.slot.icon).frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName).fontWeight(.medium)
                Text(item.rarity.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                if item.atkBonus > 0 { Text("ATK +\(item.atkBonus)").font(.caption).foregroundStyle(.red) }
                if item.defBonus > 0 { Text("DEF +\(item.defBonus)").font(.caption).foregroundStyle(.blue) }
                if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").font(.caption).foregroundStyle(.pink) }
            }
            Image(systemName: "arrow.up.circle")
                .foregroundStyle(.green)
                .padding(.leading, 4)
        }
    }
}

// MARK: - EquipSelectSheet

/// 裝備選擇 Sheet：選擇同部位未裝備裝備，或直接關閉（維持現狀）
private struct EquipSelectSheet: View {

    let slot:       EquipmentSlot
    let candidates: [EquipmentModel]
    let onSelect:   (EquipmentModel?) -> Void

    var body: some View {
        NavigationStack {
            List {
                if candidates.isEmpty {
                    Text("背包中沒有「\(slot.displayName)」可切換")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(candidates) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName).fontWeight(.medium)
                                    Text(item.rarity.displayName)
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    if item.atkBonus > 0 { Text("ATK +\(item.atkBonus)").font(.caption).foregroundStyle(.red) }
                                    if item.defBonus > 0 { Text("DEF +\(item.defBonus)").font(.caption).foregroundStyle(.blue) }
                                    if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").font(.caption).foregroundStyle(.pink) }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("選擇\(slot.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onSelect(nil) }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - EquipmentSlot: Identifiable for sheet(item:)

extension EquipmentSlot: Identifiable {
    public var id: String { rawValue }
}

// MARK: - MaterialInventoryModel helper

private extension MaterialInventoryModel {
    func amount(for mat: MaterialType) -> Int {
        switch mat {
        case .wood:            return wood
        case .ore:             return ore
        case .hide:            return hide
        case .crystalShard:    return crystalShard
        case .ancientFragment: return ancientFragment
        // V2-1 區域素材：Ticket 02 擴充 SwiftData 欄位前委派回 amount(of:)（回傳 0）
        default:               return amount(of: mat)
        }
    }
}

// MARK: - Preview

#Preview {
    CharacterView()
        .modelContainer(for: [
            PlayerStateModel.self, MaterialInventoryModel.self,
            EquipmentModel.self, TaskModel.self,
        ], inMemory: true)
}
