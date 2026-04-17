// CharacterView.swift
// 角色 Tab — V2-2 Ticket 04 更新（加入強化 / 拆解 SwipeActions）
//
// Segment Control：裝備 / 背包
//
// 裝備 Segment：
//   - 英雄狀態（等級、金幣、戰力、ATK/DEF/HP + 屬性點分配按鈕）
//   - 升級區塊（費用、升級按鈕）
//   - 已裝備欄位（4 部位：武器 / 副手 / 防具 / 飾品，點擊 → 裝備選擇 Sheet）
//
// 背包 Segment：
//   - 素材庫存（5 種）
//   - 未裝備裝備列表（點擊 → 裝備）

import SwiftUI
import SwiftData

// MARK: - Segment 定義

private enum CharacterSegment: String, CaseIterable {
    case gear        = "裝備"
    case backpack    = "背包"
    case skills      = "技能"
    case achievement = "成就"
}

private enum BackpackTab: String, CaseIterable {
    case equipment    = "裝備"
    case basicMat     = "通用素材"
    case areaMat      = "區域素材"
}

// MARK: - CharacterView

struct CharacterView: View {

    @Environment(\.modelContext) private var context

    @Query private var players:            [PlayerStateModel]
    @Query private var equipments:         [EquipmentModel]
    @Query private var inventories:        [MaterialInventoryModel]
    @Query private var achievementModels:  [AchievementProgressModel]
    @Query private var tasks:              [TaskModel]

    @State private var viewModel    = CharacterViewModel()
    @State private var segment      = CharacterSegment.gear
    @State private var backpackTab  = BackpackTab.equipment
    @State private var alertMsg: String?

    /// 裝備槽顯示順序（武器→副手→防具→飾品）
    private let slotDisplayOrder: [EquipmentSlot] = [.weapon, .offhand, .armor, .accessory]

    // 裝備選擇 Sheet：記錄要切換的部位
    @State private var equipSheetSlot: EquipmentSlot?

    // 強化 / 拆解確認 Alert（V2-2）
    @State private var pendingEnhanceItem:     EquipmentModel?
    @State private var pendingDisassembleItem: EquipmentModel?
    // 屬性點重置確認
    @State private var showResetAlert = false

    // MARK: - 計算屬性

    private var player: PlayerStateModel? { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var equippedItems: [EquipmentModel] {
        viewModel.equippedItems(from: equipments)
    }

    private var heroStats: HeroStats? {
        viewModel.heroStats(player: player, equipped: equippedItems)
    }

    /// 英雄出征中（有進行中的 .dungeon 任務）→ 禁止切換裝備
    private var isOnExpedition: Bool {
        tasks.contains { $0.kind == .dungeon && $0.status == .inProgress }
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
                case .gear:        gearSegment
                case .backpack:    backpackSegment
                case .skills:      skillsSegment
                case .achievement: achievementSegment
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
            // 強化確認 Alert（V2-2）
            .alert(
                "強化確認",
                isPresented: Binding(
                    get: { pendingEnhanceItem != nil },
                    set: { if !$0 { pendingEnhanceItem = nil } }
                ),
                presenting: pendingEnhanceItem
            ) { item in
                Button("確認") {
                    if let p = player {
                        if let msg = viewModel.enhance(equipment: item, player: p, context: context) {
                            alertMsg = msg
                        }
                    }
                    pendingEnhanceItem = nil
                }
                Button("取消", role: .cancel) { pendingEnhanceItem = nil }
            } message: { item in
                let cost = EnhancementDef.goldCost(fromLevel: item.enhancementLevel) ?? 0
                Text("將 \(item.displayName) 強化至 +\(item.enhancementLevel + 1)\n消耗：\(cost) 金幣\n目前金幣：\(player?.gold ?? 0)")
            }
            // 拆解確認 Alert（V2-2）
            .alert(
                "確認拆解",
                isPresented: Binding(
                    get: { pendingDisassembleItem != nil },
                    set: { if !$0 { pendingDisassembleItem = nil } }
                ),
                presenting: pendingDisassembleItem
            ) { item in
                Button("確認拆解", role: .destructive) {
                    if let p = player {
                        if let msg = viewModel.disassemble(equipment: item, player: p, context: context) {
                            alertMsg = msg
                        }
                    }
                    pendingDisassembleItem = nil
                }
                Button("取消", role: .cancel) { pendingDisassembleItem = nil }
            } message: { item in
                let refund = EnhancementDef.disassembleRefund(defKey: item.defKey) ?? 0
                Text("拆解 \(item.displayName)？\n退還：\(refund) 金幣（強化費用不退）\n此操作不可復原。")
            }
            // 重置屬性點確認
            .alert("確認重置？", isPresented: $showResetAlert) {
                Button("重置", role: .destructive) {
                    if let p = player { viewModel.resetAllStats(player: p, context: context) }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("所有已分配的屬性點將全部退回，可重新分配。此操作不可復原。")
            }
            // 裝備選擇 Sheet
            .sheet(item: $equipSheetSlot) { slot in
                EquipSelectSheet(
                    slot: slot,
                    candidates: viewModel.unequippedItems(slot: slot, from: equipments),
                    allEquipped: equippedItems,
                    viewModel: viewModel
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

        // ── 職業徽章 ────────────────────────────────────────────────
        if let player, let classDef = ClassDef.find(key: player.classKey) {
            Section {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(classDef.themeColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: classDef.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(classDef.themeColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(classDef.name)
                            .fontWeight(.semibold)
                            .foregroundStyle(classDef.themeColor)
                        Text(classDef.bonusSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("職業")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(classDef.themeColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            } header: {
                Text("職業")
            }
        }

        // ── 英雄屬性 ────────────────────────────────────────────────
        Section {
            if let player {
                infoRow(label: "等級", value: "Lv.\(player.heroLevel)")
                infoRow(label: "金幣", value: "\(player.gold)")
            }
            if let stats = heroStats {
                powerRow(stats.power)
                if let player {
                    statAllocRow(icon: "sword",    label: "ATK", value: stats.totalATK, pending: viewModel.pendingAtk, stat: .atk, player: player)
                    statAllocRow(icon: "shield.fill",   label: "DEF", value: stats.totalDEF, pending: viewModel.pendingDef, stat: .def, player: player)
                    statAllocRow(icon: "heart.fill",    label: "HP",  value: stats.totalHP,  pending: viewModel.pendingHp,  stat: .hp,  player: player)
                    statAllocRow(icon: "figure.run",    label: "AGI", hint: "ATB 速度", value: stats.totalAGI, pending: viewModel.pendingAgi, stat: .agi, player: player)
                    statAllocRow(icon: "scope",         label: "DEX", hint: "暴擊率",   value: stats.totalDEX, pending: viewModel.pendingDex, stat: .dex, player: player)

                    let remaining = viewModel.remainingPendingPoints(player: player)
                    if remaining > 0 {
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(.orange)
                            Text("可分配點數：\(remaining)")
                                .foregroundStyle(.orange)
                                .fontWeight(.semibold)
                        }
                    }

                    if viewModel.hasPendingAllocations {
                        HStack(spacing: 12) {
                            Button("確認加點") {
                                viewModel.commitAllocations(player: player, context: context)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)

                            Button("取消") { viewModel.cancelAllocations() }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                        }
                    }

                    let usedPoints = player.atkPoints + player.defPoints + player.hpPoints
                                   + player.agiPoints + player.dexPoints
                    if usedPoints > 0 {
                        Button {
                            showResetAlert = true
                        } label: {
                            Label("重置所有屬性點", systemImage: "arrow.uturn.backward")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                } else if let required = viewModel.nextLevelExpRequired(player: player) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Lv.\(player.heroLevel) → Lv.\(player.heroLevel + 1)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("自動升級")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: min(1.0, Double(player.heroExp) / Double(required)))
                            .tint(.purple)
                        Text("EXP \(player.heroExp) / \(required) · 升級獲得 \(AppConstants.Game.statPointsPerLevel) 屬性點")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("升級")
            }
        }

        // ── 已裝備欄位 ──────────────────────────────────────────────
        Section {
            ForEach(slotDisplayOrder, id: \.self) { slot in
                let item = equippedItems.first { $0.slot == slot }
                equippedSlotRow(slot: slot, item: item)
            }
        } header: {
            Text("已裝備（\(viewModel.equippedCount(from: equipments)) / 4）")
        } footer: {
            Text("點擊裝備欄位可切換，點擊已裝備圖示可卸除")
                .font(.caption)
        }

        // ── 累計統計 ────────────────────────────────────────────────
        if let player {
            Section("累計統計") {
                statRow("coins",       label: "累計金幣收入", value: "\(player.totalGoldEarned)")
                statRow("sword",       label: "地下城勝場",   value: "\(player.totalBattlesWon)")
                statRow("shield.fill",      label: "地下城敗場",   value: "\(player.totalBattlesLost)")
                statRow("hammer.fill",      label: "裝備獲得件數", value: "\(player.totalItemsCrafted)")
                statRow("bolt.fill",        label: "歷史最高戰力", value: "\(player.highestPowerReached)")
            }
        }
    }

    // MARK: - 背包 Segment

    @ViewBuilder
    private var backpackSegment: some View {

        // ── 分類 Tab ────────────────────────────────────────────────
        Picker("", selection: $backpackTab) {
            ForEach(BackpackTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))

        switch backpackTab {
        case .equipment:  backpackEquipmentTab
        case .basicMat:   backpackBasicMaterialTab
        case .areaMat:    backpackAreaMaterialTab
        }
    }

    // ── 裝備 Tab ────────────────────────────────────────────────────

    @ViewBuilder
    private var backpackEquipmentTab: some View {
        let unequipped = viewModel.unequippedItems(from: equipments)
        Section {
            if unequipped.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("背包中沒有裝備")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("鑄造師打造裝備後會出現在這裡")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(unequipped) { item in
                    Button {
                        viewModel.equip(item, context: context)
                    } label: {
                        backpackItemRow(item)
                    }
                    .buttonStyle(.plain)
                    // 右滑 → 強化（滿強化時不顯示）
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if item.enhancementLevel < EnhancementDef.maxLevel {
                            Button {
                                pendingEnhanceItem = item
                            } label: {
                                Label("強化", systemImage: "hammer.fill")
                            }
                            .tint(.orange)
                        }
                    }
                    // 左滑 → 拆解（不可拆解的裝備不顯示）
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if EnhancementDef.disassembleRefund(defKey: item.defKey) != nil {
                            Button(role: .destructive) {
                                pendingDisassembleItem = item
                            } label: {
                                Label("拆解", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        } header: {
            Text("裝備（\(unequipped.count) 件未裝備）")
        } footer: {
            Text("點擊穿上 · 右滑強化 · 左滑拆解")
                .font(.caption)
        }
    }

    // ── 通用素材 Tab ────────────────────────────────────────────────

    @ViewBuilder
    private var backpackBasicMaterialTab: some View {
        let basicMats = MaterialType.allCases.filter { !$0.isRegionMaterial }
        let hasAny    = inventory.map { inv in basicMats.contains { inv.amount(of: $0) > 0 } } ?? false

        Section("通用素材") {
            if let inv = inventory, hasAny {
                ForEach(basicMats, id: \.self) { mat in
                    materialRow(mat, inventory: inv)
                }
            } else {
                Text("尚無通用素材")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    // ── 區域素材 Tab ────────────────────────────────────────────────

    @ViewBuilder
    private var backpackAreaMaterialTab: some View {
        let wildland:   [MaterialType] = [.oldPostBadge, .driedHideBundle, .splitHornBone, .riftFangRoyalBadge]
        let mine:       [MaterialType] = [.mineLampCopperClip, .tunnelIronClip, .veinStoneSlab, .stoneSwallowCore]
        let ruins:      [MaterialType] = [.relicSealRing, .oathInscriptionShard, .foreShrineClip, .ancientKingCore]
        let sunkenCity: [MaterialType] = [.sunkenRuneShard, .abyssalCrystalDrop, .drownedCrownFragment, .sunkenKingSeal]

        if let inv = inventory {
            let hasAny = (wildland + mine + ruins + sunkenCity).contains { inv.amount(of: $0) > 0 }
            if hasAny {
                let hasWildland   = wildland.contains   { inv.amount(of: $0) > 0 }
                let hasMine       = mine.contains       { inv.amount(of: $0) > 0 }
                let hasRuins      = ruins.contains      { inv.amount(of: $0) > 0 }
                let hasSunkenCity = sunkenCity.contains { inv.amount(of: $0) > 0 }

                if hasWildland {
                    Section("荒野邊境") {
                        ForEach(wildland, id: \.self) { mat in materialRow(mat, inventory: inv) }
                    }
                }
                if hasMine {
                    Section("廢棄礦坑") {
                        ForEach(mine, id: \.self) { mat in materialRow(mat, inventory: inv) }
                    }
                }
                if hasRuins {
                    Section("古代遺跡") {
                        ForEach(ruins, id: \.self) { mat in materialRow(mat, inventory: inv) }
                    }
                }
                if hasSunkenCity {
                    Section("沉落王城") {
                        ForEach(sunkenCity, id: \.self) { mat in materialRow(mat, inventory: inv) }
                    }
                }
            } else {
                Section {
                    Text("尚無區域素材")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
        } else {
            Section { Text("—").foregroundStyle(.secondary) }
        }
    }

    // MARK: - 技能 Segment

    @ViewBuilder
    private var skillsSegment: some View {
        if let player {
            skillsContent(player: player)
        } else {
            Section { Text("—").foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    private func skillsContent(player: PlayerStateModel) -> some View {
        let classKey  = player.classKey
        let heroLevel = player.heroLevel
        let allClassSkills = SkillDef.all.filter { $0.classKey == classKey }
        let unlockedSkills = allClassSkills.filter { $0.requiredLevel <= heroLevel }
        let lockedSkills   = allClassSkills.filter { $0.requiredLevel > heroLevel }
        let equipped       = player.equippedSkillKeys

        // ── 嵌入格（最多 4 個）─────────────────────────────────────
        Section {
            ForEach(0..<4, id: \.self) { slotIdx in
                if slotIdx < equipped.count,
                   let def = SkillDef.find(key: equipped[slotIdx]) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name).fontWeight(.medium)
                            Text(def.effectSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        Spacer()
                        Button("移除") {
                            var keys = player.equippedSkillKeys
                            keys.removeAll { $0 == def.key }
                            player.equippedSkillKeys = keys
                            try? context.save()
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .font(.caption)
                        .disabled(isOnExpedition)
                    }
                } else {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        Text("空槽 \(slotIdx + 1)")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            HStack {
                Text("配備技能")
                Spacer()
                Text("\(equipped.count) / 4")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if isOnExpedition {
                Label("出征中，技能配置已鎖定", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("最多配備 4 個技能，出征時全程生效")
                    .font(.caption)
            }
        }

        // ── 已解鎖（可配備）──────────────────────────────────────────
        if !unlockedSkills.isEmpty {
            Section {
                ForEach(unlockedSkills, id: \.key) { def in
                    let isEquipped = equipped.contains(def.key)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isEquipped ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.08))
                                .frame(width: 32, height: 32)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isEquipped ? .orange : .secondary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(def.name).fontWeight(.medium)
                                Text("Lv.\(def.requiredLevel)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            Text(def.effectSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        Spacer()
                        if isEquipped {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 16))
                        } else {
                            Button("配備") {
                                guard equipped.count < 4 else { return }
                                var keys = player.equippedSkillKeys
                                keys.append(def.key)
                                player.equippedSkillKeys = keys
                                try? context.save()
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .font(.caption)
                            .disabled(isOnExpedition || equipped.count >= 4)
                        }
                    }
                }
            } header: {
                Text("已解鎖技能（\(unlockedSkills.count) 個）")
            }
        }

        // ── 尚未解鎖 ─────────────────────────────────────────────────
        if !lockedSkills.isEmpty {
            Section {
                ForEach(lockedSkills, id: \.key) { def in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.06))
                                .frame(width: 32, height: 32)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(def.effectSummary)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        Spacer()
                        Text("需 Lv.\(def.requiredLevel)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            } header: {
                Text("尚未解鎖")
            }
        }

        // ── 尚未選擇職業 ─────────────────────────────────────────────
        if classKey.isEmpty {
            Section {
                Label("請先選擇職業以解鎖技能", systemImage: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 成就 Segment

    @ViewBuilder
    private var achievementSegment: some View {
        let progress       = achievementModels.first
        let unlockedKeys   = progress?.unlockedKeys ?? []
        let unlockedCount  = AchievementDef.all.filter { unlockedKeys.contains($0.key) }.count
        let total          = AchievementDef.all.count

        Section {
            HStack {
                Text("已解鎖成就")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(unlockedCount) / \(total)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            ProgressView(value: Double(unlockedCount), total: Double(total))
                .tint(.yellow)
        } header: {
            Text("成就進度")
        }

        Section("成就列表") {
            ForEach(AchievementDef.all) { achievement in
                let unlocked = unlockedKeys.contains(achievement.key)
                achievementRow(achievement, unlocked: unlocked)
            }
        }
    }

    @ViewBuilder
    private func achievementRow(_ achievement: AchievementDef, unlocked: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(achievement.icon)
                .font(.title2)
                .frame(width: 36, height: 36)
                .opacity(unlocked ? 1.0 : 0.3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .fontWeight(unlocked ? .semibold : .regular)
                        .foregroundStyle(unlocked ? Color.primary : Color.secondary)
                    if unlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    // ── 素材列 helper ────────────────────────────────────────────────

    @ViewBuilder
    private func materialRow(_ mat: MaterialType, inventory inv: MaterialInventoryModel) -> some View {
        let amount = inv.amount(of: mat)
        if amount > 0 {
            HStack {
                Text("\(mat.icon) \(mat.displayName)")
                Spacer()
                Text("\(amount)")
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Row Helpers

    @ViewBuilder
    private func statRow(_ icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.secondary)
                Text(label)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

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
    /// pending > 0 時以橙色預覽 "value → +pending = total"
    @ViewBuilder
    private func statAllocRow(
        icon: String, label: String, hint: String? = nil, value: Int, pending: Int,
        stat: StatType, player: PlayerStateModel
    ) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).foregroundStyle(.secondary)
                    if let hint {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            if pending > 0 {
                Text("\(value)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                // 橙色 badge：+N → total
                HStack(spacing: 3) {
                    Text("+\(pending)")
                        .fontWeight(.bold)
                    Text("→")
                        .font(.caption2)
                        .opacity(0.7)
                    Text("\(value + pending)")
                        .fontWeight(.bold)
                }
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            } else {
                Text("\(value)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            if viewModel.remainingPendingPoints(player: player) > 0 {
                Button {
                    viewModel.addPendingPoint(to: stat, player: player)
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
                    // Boss 武器加 ✦ 表示浮動值
                    HStack(spacing: 2) {
                        if item.isRolledBossWeapon {
                            Text("✦").font(.caption2).foregroundStyle(.yellow)
                        }
                        Text(item.displayName)
                            .fontWeight(.medium)
                            .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.primary)  // T03 精良金色
                    }
                    HStack(spacing: 4) {
                        Text(item.rarity.displayName)
                            .font(.caption2)
                            .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.secondary)  // T03 精良金色
                        if item.atkBonus > 0 {
                            Text("ATK +\(item.atkBonus)")
                                .font(.caption2)
                                .foregroundStyle(item.isRolledBossWeapon ? .yellow : .red)
                        }
                    }
                }
                if isOnExpedition {
                    // 出征中：顯示鎖定標記，禁止任何操作
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                        Text("出征中")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                } else {
                    // 強化按鈕（滿強化 +5 時不顯示）
                    if item.enhancementLevel < EnhancementDef.maxLevel {
                        Button {
                            pendingEnhanceItem = item
                        } label: {
                            Image(systemName: "hammer")
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
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
                }
            } else {
                Text("未裝備")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isOnExpedition else { return }
            equipSheetSlot = slot
        }
    }

    @ViewBuilder
    private func backpackItemRow(_ item: EquipmentModel) -> some View {
        HStack {
            Text(item.slot.icon).frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    if item.isRolledBossWeapon {
                        Text("✦").font(.caption2).foregroundStyle(.yellow)
                    }
                    Text(item.displayName)
                        .fontWeight(.medium)
                        .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.primary)  // T03 精良金色
                }
                Text(item.rarity.displayName)
                    .font(.caption2)
                    .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.secondary)   // T03 精良金色
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                if item.atkBonus > 0 {
                    Text("ATK +\(item.atkBonus)")
                        .font(.caption)
                        .foregroundStyle(item.isRolledBossWeapon ? .yellow : .red)
                }
                if item.defBonus > 0 { Text("DEF +\(item.defBonus)").font(.caption).foregroundStyle(.blue) }
                if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").font(.caption).foregroundStyle(.pink) }
            }
            let diff = viewModel.equipDiff(
                candidate: item,
                equipped: equipments.filter { $0.isEquipped }
            )
            if diff.hasAnyChange {
                diffBadge(diff)
            }
            Image(systemName: "arrow.up.circle")
                .foregroundStyle(.green)
                .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private func diffBadge(_ diff: StatDiff) -> some View {
        HStack(spacing: 5) {
            if diff.atk != 0 {
                diffItem(icon: "sword", value: diff.atk)
            }
            if diff.def != 0 {
                diffItem(icon: "shield.fill", value: diff.def)
            }
            if diff.hp != 0 {
                diffItem(icon: "heart.fill", value: diff.hp)
            }
        }
        .font(.caption2)
    }

    @ViewBuilder
    private func diffItem(icon: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .frame(width: 10, height: 10)
            Text(value > 0 ? "+\(value)" : "\(value)")
        }
        .foregroundStyle(value > 0 ? Color.green : Color.red)
    }
}

// MARK: - EquipSelectSheet

/// 裝備選擇 Sheet：選擇同部位未裝備裝備，或直接關閉（維持現狀）
private struct EquipSelectSheet: View {

    let slot:        EquipmentSlot
    let candidates:  [EquipmentModel]
    let allEquipped: [EquipmentModel]
    let viewModel:   CharacterViewModel
    let onSelect:    (EquipmentModel?) -> Void

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
                            VStack(alignment: .leading, spacing: 2) {
                                // 行 1：名稱 + 稀有度
                                HStack {
                                    if item.isRolledBossWeapon {
                                        Text("✦").font(.caption2).foregroundStyle(.yellow)
                                    }
                                    Text(item.displayName)
                                        .fontWeight(.medium)
                                        .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.primary)  // T03 精良金色
                                    Spacer()
                                    Text(item.rarity.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(item.rarity == .refined ? Color.rarityRefined : Color.secondary)  // T03 精良金色
                                }

                                // 行 2：完整屬性數值
                                HStack(spacing: 8) {
                                    if item.totalAtk > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "sword").frame(width: 11, height: 11)
                                            Text("\(item.totalAtk)")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(item.isRolledBossWeapon ? Color.yellow : Color.secondary)
                                    }
                                    if item.totalDef > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "shield.fill").frame(width: 11, height: 11)
                                            Text("\(item.totalDef)")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                    }
                                    if item.totalHp > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "heart.fill").frame(width: 11, height: 11)
                                            Text("\(item.totalHp)")
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                    }
                                }

                                // 行 3：換裝差值
                                let diff = viewModel.equipDiff(candidate: item, equipped: allEquipped)
                                if diff.hasAnyChange {
                                    diffBadge(diff)
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

    @ViewBuilder
    private func diffBadge(_ diff: StatDiff) -> some View {
        HStack(spacing: 5) {
            if diff.atk != 0 {
                HStack(spacing: 2) {
                    Image(systemName: "sword").frame(width: 10, height: 10)
                    Text(diff.atk > 0 ? "+\(diff.atk)" : "\(diff.atk)")
                }
                .foregroundStyle(diff.atk > 0 ? Color.green : Color.red)
            }
            if diff.def != 0 {
                HStack(spacing: 2) {
                    Image(systemName: "shield.fill").frame(width: 10, height: 10)
                    Text(diff.def > 0 ? "+\(diff.def)" : "\(diff.def)")
                }
                .foregroundStyle(diff.def > 0 ? Color.green : Color.red)
            }
            if diff.hp != 0 {
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill").frame(width: 10, height: 10)
                    Text(diff.hp > 0 ? "+\(diff.hp)" : "\(diff.hp)")
                }
                .foregroundStyle(diff.hp > 0 ? Color.green : Color.red)
            }
        }
        .font(.caption2)
    }
}

// MARK: - EquipmentSlot: Identifiable for sheet(item:)

extension EquipmentSlot: Identifiable {
    public var id: String { rawValue }
}


// MARK: - Preview

#Preview {
    CharacterView()
        .modelContainer(for: [
            PlayerStateModel.self, MaterialInventoryModel.self,
            EquipmentModel.self, TaskModel.self,
        ], inMemory: true)
}
