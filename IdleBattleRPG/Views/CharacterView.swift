// CharacterView.swift

import SwiftUI
import SwiftData

// MARK: - Segment 定義

private enum CharacterSegment: String, CaseIterable {
    case status      = "狀態"
    case gear        = "裝備"
    case backpack    = "背包"
    case skills      = "技能"
    case achievement = "成就"
}

private enum SkillSubTab: String, CaseIterable {
    case active  = "主動技能"
    case talent  = "天賦樹"
}

private enum BackpackTab: String, CaseIterable {
    case equipment    = "裝備"
    case basicMat     = "通用素材"
    case areaMat      = "區域素材"
}

// MARK: - CharacterView

struct CharacterView: View {

    let appState: AppState
    @Binding var selectedTab: Int

    @Environment(\.modelContext) private var context

    @Query private var players:            [PlayerStateModel]
    @Query private var equipments:         [EquipmentModel]
    @Query private var inventories:        [MaterialInventoryModel]
    @Query private var achievementModels:  [AchievementProgressModel]
    @Query private var tasks:              [TaskModel]

    @State private var viewModel    = CharacterViewModel()
    @State private var segment      = CharacterSegment.status
    @State private var backpackTab  = BackpackTab.equipment
    @State private var skillSubTab  = SkillSubTab.active
    @State private var alertMsg: String?

    /// 裝備槽顯示順序（武器→副手→防具→飾品）
    private let slotDisplayOrder: [EquipmentSlot] = [.weapon, .offhand, .armor, .accessory]
    /// 背包裝備 3 欄 Grid（對齊商人商店）
    private let backpackGridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    // 裝備選擇 Sheet：記錄要切換的部位
    @State private var equipSheetSlot: EquipmentSlot?

    // 強化 / 拆解確認 Alert（V2-2）
    @State private var pendingEnhanceItem:     EquipmentModel?
    @State private var pendingDisassembleItem: EquipmentModel?
    // 屬性點重置確認
    @State private var showResetAlert = false
    // 天賦重置確認（T06）
    @State private var showResetTalentAlert = false

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

    // MARK: - T07 教程：解鎖冒險 Tab

    @ViewBuilder
    private var tutorialUnlockAdventureSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundStyle(.orange)
                    Text("趁手的武器在手了。接下來，去挑戰荒野的菁英敵人，贏得防具鍛造材料。")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    guard let player else { return }
                    player.onboardingStep = 4
                    try? context.save()
                    selectedTab = 1   // 切換至冒險 Tab（tag 1）
                } label: {
                    Label("前往冒險（解鎖冒險頁）", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.vertical, 4)
        } header: {
            Text("🎯 引導任務")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // ── 教程引導（T07：step == 3）────────────────────────
                if player?.onboardingStep == 3 {
                    tutorialUnlockAdventureSection
                }

                // ── Segment Tab Bar（可滾動）──────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(CharacterSegment.allCases, id: \.self) { seg in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { segment = seg }
                            } label: {
                                Text(seg.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(segment == seg ? Color.accentColor : Color(.systemFill))
                                    .foregroundStyle(segment == seg ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))

                switch segment {
                case .status:      statusSegment
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
            // 天賦重置確認（T06）
            .alert("確認重置天賦？", isPresented: $showResetTalentAlert) {
                Button("重置", role: .destructive) {
                    if let p = player {
                        try? appState.talentService.resetAllTalents(player: p)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("將退還所有已投入的天賦點，並解除路線鎖定。\n消耗 500 金幣，此操作不可復原。")
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

    // MARK: - 狀態 Segment

    @ViewBuilder
    private var statusSegment: some View {

        // ── 職業徽章 ────────────────────────────────────────────────
        if let player, let classDef = ClassDef.find(key: player.classKey) {
            Section {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(classDef.themeColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(webp: "class_\(classDef.key)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
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
                iconInfoRow(webp: "icon_level", label: "等級", value: "Lv.\(player.heroLevel)")
                iconInfoRow(webp: "icon_gold",  label: "金幣", value: "\(player.gold)")
            }
            if let stats = heroStats {
                powerRow(stats.power)
                if let player {
                    statAllocRow(icon: "attr_atk", label: "ATK", value: stats.totalATK, pending: viewModel.pendingAtk, stat: .atk, player: player)
                    statAllocRow(icon: "attr_def", label: "DEF", value: stats.totalDEF, pending: viewModel.pendingDef, stat: .def, player: player)
                    statAllocRow(icon: "attr_hp",  label: "HP",  value: stats.totalHP,  pending: viewModel.pendingHp,  stat: .hp,  player: player)
                    statAllocRow(icon: "attr_agi", label: "AGI", hint: "ATB 速度", value: stats.totalAGI, pending: viewModel.pendingAgi, stat: .agi, player: player)
                    statAllocRow(icon: "attr_dex", label: "DEX", hint: "暴擊率",   value: stats.totalDEX, pending: viewModel.pendingDex, stat: .dex, player: player)

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
            if let player {
                let displayName = player.heroName.isEmpty ? "冒險者" : player.heroName
                Text("\(displayName) · 英雄屬性")
            } else {
                Text("英雄屬性")
            }
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
    }

    // MARK: - 裝備 Segment

    @ViewBuilder
    private var gearSegment: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(slotDisplayOrder, id: \.self) { slot in
                    let item = equippedItems.first { $0.slot == slot }
                    equippedSlotCard(slot: slot, item: item)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("已裝備（\(viewModel.equippedCount(from: equipments)) / 4）")
        } footer: {
            Text("點擊卡片可切換裝備 · 錘子圖示可強化")
                .font(.caption)
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
                LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                    ForEach(unequipped) { item in
                        backpackItemCard(item)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                Text("裝備（\(unequipped.count) 件未裝備）")
                rarityLegendView
            }
        } footer: {
            Text("點擊穿上 · 長按可強化或拆解")
                .font(.caption)
        }
    }

    // MARK: - 稀有度色彩說明條

    private var rarityLegendView: some View {
        HStack(spacing: 10) {
            ForEach(EquipmentRarity.allCases, id: \.self) { rarity in
                HStack(spacing: 3) {
                    Circle()
                        .fill(rarity == .common ? Color.secondary.opacity(0.5) : rarity.displayColor)
                        .frame(width: 6, height: 6)
                    Text(rarity.displayName)
                        .font(.caption2)
                        .foregroundStyle(rarity == .common ? Color.secondary : rarity.displayColor)
                }
            }
        }
        .textCase(nil)
    }

    // ── 通用素材 Tab ────────────────────────────────────────────────

    @ViewBuilder
    private var backpackBasicMaterialTab: some View {
        let basicMats = MaterialType.allCases.filter { !$0.isRegionMaterial }
        let hasAny    = inventory.map { inv in basicMats.contains { inv.amount(of: $0) > 0 } } ?? false

        Section("通用素材") {
            if let inv = inventory, hasAny {
                LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                    ForEach(basicMats.filter { inv.amount(of: $0) > 0 }, id: \.self) { mat in
                        materialCard(mat, amount: inv.amount(of: mat))
                    }
                }
                .padding(.vertical, 4)
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
                let ownedWildland   = wildland.filter   { inv.amount(of: $0) > 0 }
                let ownedMine       = mine.filter       { inv.amount(of: $0) > 0 }
                let ownedRuins      = ruins.filter      { inv.amount(of: $0) > 0 }
                let ownedSunkenCity = sunkenCity.filter { inv.amount(of: $0) > 0 }

                if !ownedWildland.isEmpty {
                    Section("荒野邊境") {
                        LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                            ForEach(ownedWildland, id: \.self) { mat in
                                materialCard(mat, amount: inv.amount(of: mat))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if !ownedMine.isEmpty {
                    Section("廢棄礦坑") {
                        LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                            ForEach(ownedMine, id: \.self) { mat in
                                materialCard(mat, amount: inv.amount(of: mat))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if !ownedRuins.isEmpty {
                    Section("古代遺跡") {
                        LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                            ForEach(ownedRuins, id: \.self) { mat in
                                materialCard(mat, amount: inv.amount(of: mat))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if !ownedSunkenCity.isEmpty {
                    Section("沉落王城") {
                        LazyVGrid(columns: backpackGridColumns, spacing: 10) {
                            ForEach(ownedSunkenCity, id: \.self) { mat in
                                materialCard(mat, amount: inv.amount(of: mat))
                            }
                        }
                        .padding(.vertical, 4)
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
        // 子選單 Picker（主動技能 / 天賦樹）
        Picker("", selection: $skillSubTab) {
            ForEach(SkillSubTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))

        if let player {
            switch skillSubTab {
            case .active: activeSkillsSection(player: player)
            case .talent: passiveSkillsSection(player: player)
            }
        } else {
            Section { Text("—").foregroundStyle(.secondary) }
        }
    }

    // MARK: - 主動技能 Section

    @ViewBuilder
    private func activeSkillsSection(player: PlayerStateModel) -> some View {
        let classKey       = player.classKey
        let heroLevel      = player.heroLevel
        let allClassSkills = SkillDef.all.filter { $0.classKey == classKey }
        let unlockedSkills = allClassSkills.filter { $0.requiredLevel <= heroLevel }
        let lockedSkills   = allClassSkills.filter { $0.requiredLevel > heroLevel }
        let equipped       = player.equippedSkillKeys

        // 可用技能點 badge
        Section {
            HStack {
                Image(systemName: "bolt.circle.fill").foregroundStyle(.orange)
                Text("可用技能點").foregroundStyle(.secondary)
                Spacer()
                Text("\(player.availableSkillPoints) 點")
                    .fontWeight(.semibold)
                    .foregroundStyle(player.availableSkillPoints > 0 ? .orange : .secondary)
            }
        } header: {
            Text("主動技能")
        }

        // 配備欄（4 格）
        Section {
            ForEach(0..<4, id: \.self) { slotIdx in
                if slotIdx < equipped.count, let def = SkillDef.find(key: equipped[slotIdx]) {
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
                                .font(.caption).foregroundStyle(.secondary)
                                .lineLimit(1).minimumScaleFactor(0.85)
                        }
                        Spacer()
                        Button("移除") {
                            var keys = player.equippedSkillKeys
                            keys.removeAll { $0 == def.key }
                            player.equippedSkillKeys = keys
                            try? context.save()
                        }
                        .font(.caption).buttonStyle(.bordered).tint(.secondary)
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
                        Text("空槽 \(slotIdx + 1)").foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            HStack {
                Text("配備欄")
                Spacer()
                Text("\(equipped.count) / 4").foregroundStyle(.secondary)
            }
        } footer: {
            if isOnExpedition {
                Label("出征中，技能配置已鎖定", systemImage: "lock.fill")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("最多配備 4 個技能，出征時全程生效").font(.caption)
            }
        }

        // 已解鎖技能（可收合）
        if !unlockedSkills.isEmpty {
            Section("已解鎖技能（\(unlockedSkills.count) 個）") {
                ForEach(unlockedSkills, id: \.key) { skill in
                    activeSkillDisclosure(skill: skill, player: player, equipped: equipped)
                }
            }
        }

        // 尚未解鎖
        if !lockedSkills.isEmpty {
            Section("尚未解鎖") {
                ForEach(lockedSkills, id: \.key) { def in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.06))
                                .frame(width: 32, height: 32)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13)).foregroundStyle(.tertiary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(def.name).fontWeight(.medium).foregroundStyle(.secondary)
                            Text(def.effectSummary).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                        }
                        Spacer()
                        Text("需 Lv.\(def.requiredLevel)")
                            .font(.caption2).foregroundStyle(.tertiary)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1)).clipShape(Capsule())
                    }
                }
            }
        }

        if classKey.isEmpty {
            Section {
                Label("請先選擇職業以解鎖技能", systemImage: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func activeSkillDisclosure(
        skill: SkillDef,
        player: PlayerStateModel,
        equipped: [String]
    ) -> some View {
        let currentLevel = player.level(of: skill.key)
        let isEquipped   = equipped.contains(skill.key)
        let canUpgrade   = appState.skillUpgradeService.canUpgrade(skillKey: skill.key, for: player)

        DisclosureGroup {
            // 每等效果文字
            ForEach(0..<skill.maxLevel, id: \.self) { idx in
                HStack {
                    Text("Lv.\(idx + 1)")
                        .frame(width: 36, alignment: .leading)
                    Spacer()
                    Text(skill.effectDescription(at: idx))
                        .foregroundStyle(currentLevel > idx ? Color.primary : Color.secondary.opacity(0.5))
                }
                .font(.caption)
            }

            // 升階預覽（T07）
            if canUpgrade {
                HStack {
                    Text("升階後").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text(skill.effectDescription(at: currentLevel))
                        .font(.caption2).foregroundStyle(.blue)
                }
                .padding(.top, 2)
            }

            // 升階 / 最高等級標示
            if currentLevel >= skill.maxLevel {
                Label("已達最高等級", systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.orange)
            } else if canUpgrade {
                Button("升階（-1 技能點）Lv.\(currentLevel) → \(currentLevel + 1)") {
                    try? appState.skillUpgradeService.upgradeSkill(skillKey: skill.key, for: player)
                }
                .font(.caption).buttonStyle(.bordered).tint(.orange)
            }

        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isEquipped ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: isEquipped ? "bolt.fill" : "bolt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isEquipped ? .orange : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(skill.name).fontWeight(.medium)
                        Text("Lv.\(currentLevel)/\(skill.maxLevel)")
                            .font(.caption2)
                            .foregroundStyle(currentLevel > 0 ? .orange : .secondary)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1)).clipShape(Capsule())
                    }
                    Text(skill.effectDescription(at: max(0, currentLevel - 1)))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                if isEquipped {
                    Button("移除") {
                        var keys = player.equippedSkillKeys
                        keys.removeAll { $0 == skill.key }
                        player.equippedSkillKeys = keys
                        try? context.save()
                    }
                    .font(.caption).buttonStyle(.bordered).tint(.secondary)
                    .disabled(isOnExpedition)
                } else {
                    Button("配備") {
                        guard equipped.count < 4 else { return }
                        var keys = player.equippedSkillKeys
                        keys.append(skill.key)
                        player.equippedSkillKeys = keys
                        try? context.save()
                    }
                    .font(.caption).buttonStyle(.bordered).tint(.orange)
                    .disabled(isOnExpedition || equipped.count >= 4)
                }
            }
        }
    }

    // MARK: - 被動技能（天賦）Section

    @ViewBuilder
    private func passiveSkillsSection(player: PlayerStateModel) -> some View {
        // 天賦點 badge
        Section {
            HStack {
                Image(systemName: "sparkles").foregroundStyle(.blue)
                Text("可用天賦點").foregroundStyle(.secondary)
                Spacer()
                Text("\(player.availableTalentPoints) 點")
                    .fontWeight(.semibold)
                    .foregroundStyle(player.availableTalentPoints > 0 ? .blue : .secondary)
            }
        } header: {
            Text("被動技能")
        }

        let routes = TalentRouteDef.all(for: player.classKey)

        if routes.isEmpty {
            Section {
                Label("請先選擇職業以解鎖天賦", systemImage: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(.secondary)
            }
        } else {
            ForEach(routes, id: \.key) { route in
                let isLocked = appState.talentService.isRouteLocked(route, for: player)
                passiveRouteSection(route: route, player: player, isLocked: isLocked)
            }

            // 天賦重置按鈕（T06）
            if !player.investedTalentKeys.isEmpty {
                Section {
                    Button {
                        showResetTalentAlert = true
                    } label: {
                        Label("重置所有天賦（-500 金幣）", systemImage: "arrow.uturn.backward")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered).tint(.secondary)
                    .disabled(player.gold < 500)
                    .frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    if player.gold < 500 {
                        Text("金幣不足，無法重置").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func passiveRouteSection(
        route: TalentRouteDef,
        player: PlayerStateModel,
        isLocked: Bool
    ) -> some View {
        Section {
            Text(route.themeDescription)
                .font(.caption).foregroundStyle(.secondary)
            ForEach(route.nodes, id: \.key) { node in
                passiveNodeDisclosure(node: node, player: player, isRouteLocked: isLocked)
            }
        } header: {
            HStack {
                Text(route.name).fontWeight(.semibold)
                Spacer()
                if isLocked {
                    Label("互斥鎖定", systemImage: "lock.fill")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isLocked)
    }

    @ViewBuilder
    private func passiveNodeDisclosure(
        node: TalentNodeDef,
        player: PlayerStateModel,
        isRouteLocked: Bool
    ) -> some View {
        let investedCount = node.currentLevel(in: player)
        let isMaxed       = node.isMaxed(in: player)
        let canInvest     = !isRouteLocked && appState.talentService.canInvest(nodeKey: node.key, for: player)

        DisclosureGroup {
            // 每等效果文字
            ForEach(1...node.maxLevel, id: \.self) { lv in
                HStack {
                    Text("Lv.\(lv)").frame(width: 36, alignment: .leading)
                    Spacer()
                    Text(node.effectSummary)
                        .foregroundStyle(investedCount >= lv ? Color.primary : Color.secondary.opacity(0.4))
                }
                .font(.caption)
            }

            // 戰力預覽（T07）
            if canInvest, let current = heroStats {
                let delta = current.applying(talentNodes: [node]).power - current.power
                if delta > 0 {
                    HStack {
                        Text("投入後").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("+\(delta) 戰力")
                            .font(.caption2).fontWeight(.semibold).foregroundStyle(.blue).monospacedDigit()
                    }
                    .padding(.top, 2)
                }
            }

            // 投入 / 已達上限標示
            if isMaxed {
                Label("已達上限", systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.green)
            } else if canInvest {
                Button("投入（-1 天賦點）") {
                    try? appState.talentService.investPoint(nodeKey: node.key, for: player)
                }
                .font(.caption).buttonStyle(.bordered).tint(.blue)
            }

        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isMaxed ? Color.green : (canInvest ? Color.blue : Color.secondary.opacity(0.25)))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).fontWeight(.medium)
                        .foregroundStyle(isMaxed || canInvest ? Color.primary : Color.secondary)
                    Text(node.effectSummary).font(.caption)
                        .foregroundStyle(isMaxed || canInvest ? Color.secondary : Color.secondary.opacity(0.4))
                }
                Spacer()
                Text("\(investedCount)/\(node.maxLevel)")
                    .font(.caption2)
                    .foregroundStyle(isMaxed ? .green : (investedCount > 0 ? .blue : .secondary))
                    .monospacedDigit()
            }
        }
    }

    // MARK: - 成就 Segment

    @ViewBuilder
    private var achievementSegment: some View {
        // ── 累計統計（從裝備頁搬來） ────────────────────────────────
        if let player {
            Section("累計統計") {
                statRow("coins",          label: "累計金幣收入", value: "\(player.totalGoldEarned)")
                statRow("figure.fencing", label: "地下城勝場",   value: "\(player.totalBattlesWon)")
                statRow("shield.fill",    label: "地下城敗場",   value: "\(player.totalBattlesLost)")
                statRow("hammer.fill",    label: "裝備獲得件數", value: "\(player.totalItemsCrafted)")
                statRow("bolt.fill",      label: "歷史最高戰力", value: "\(player.highestPowerReached)")
            }
        }

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

    // ── 素材方格卡片（商店風格，3 欄 Grid 用）────────────────────────

    @ViewBuilder
    private func materialCard(_ mat: MaterialType, amount: Int) -> some View {
        VStack(spacing: 5) {
            Text(mat.icon).font(.system(size: 26))
            Text(mat.displayName)
                .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
            Text("×\(amount)")
                .font(.caption2).fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.06))
        )
    }

    // ── 素材列 helper（保留供其他地方使用）─────────────────────────

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
    private func iconInfoRow(webp name: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(webp: name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .opacity(0.7)
                Text(label).foregroundStyle(.secondary)
            }
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
                Image(webp: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .opacity(0.7)
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

    /// 裝備槽卡片：點整卡 → 開 EquipSelectSheet；錘子 → 強化；× → 卸除
    @ViewBuilder
    private func equippedSlotCard(slot: EquipmentSlot, item: EquipmentModel?) -> some View {
        VStack(alignment: .center, spacing: 4) {
            // ① 部位 emoji
            Text(slot.icon).font(.system(size: 28))

            if let item {
                // ② 名稱
                HStack(spacing: 2) {
                    if item.isRolledBossWeapon {
                        Text("✦").font(.caption2).foregroundStyle(.yellow)
                    }
                    Text(item.displayName)
                        .font(.caption).fontWeight(.semibold)
                        .lineLimit(1).minimumScaleFactor(0.75)
                        .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : .primary)
                }
                // ③ 強化等級
                if item.enhancementLevel > 0 {
                    Text("+\(item.enhancementLevel)")
                        .font(.caption2).foregroundStyle(item.rarity.displayColor)
                }
                // ④ 屬性橫排
                HStack(spacing: 4) {
                    if item.atkBonus > 0 {
                        Text("ATK+\(item.atkBonus)")
                            .foregroundStyle(item.isRolledBossWeapon ? .yellow : .red)
                    }
                    if item.defBonus > 0 { Text("DEF+\(item.defBonus)").foregroundStyle(.blue) }
                    if item.hpBonus  > 0 { Text("HP+\(item.hpBonus)").foregroundStyle(.pink) }
                }
                .font(.caption2)
                // ⑤ 操作列
                if !isOnExpedition {
                    HStack {
                        if item.enhancementLevel < EnhancementDef.maxLevel {
                            Button { pendingEnhanceItem = item } label: {
                                Image(systemName: "hammer").font(.caption2)
                            }.buttonStyle(.bordered).tint(.orange)
                        }
                        Spacer()
                        Button { viewModel.unequip(item, context: context) } label: {
                            Image(systemName: "xmark").font(.caption2)
                        }.buttonStyle(.bordered).tint(.secondary)
                    }
                } else {
                    Label("出征中", systemImage: "lock.fill")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("未裝備").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.map {
                    $0.rarity.hasAccent
                        ? $0.rarity.displayColor.opacity(0.08)
                        : Color.secondary.opacity(0.06)
                } ?? Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(item.map {
                    $0.rarity.hasAccent
                        ? $0.rarity.displayColor.opacity(0.25)
                        : Color.clear
                } ?? Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            guard !isOnExpedition else { return }
            equipSheetSlot = slot
        }
    }

    @ViewBuilder
    private func backpackItemCard(_ item: EquipmentModel) -> some View {
        VStack(spacing: 5) {
            // ① 部位 emoji
            Text(item.slot.icon).font(.system(size: 26))
            // ② 名稱
            HStack(spacing: 2) {
                if item.isRolledBossWeapon {
                    Text("✦").font(.caption2).foregroundStyle(.yellow)
                }
                Text(item.displayName)
                    .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                    .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : .primary)
            }
            // ③ 強化等級
            if item.enhancementLevel > 0 {
                Text("+\(item.enhancementLevel)")
                    .font(.caption2).foregroundStyle(item.rarity.displayColor)
            }
            // ④ 屬性縱排
            VStack(spacing: 1) {
                if item.atkBonus > 0 {
                    Text("ATK +\(item.atkBonus)")
                        .foregroundStyle(item.isRolledBossWeapon ? Color.yellow : Color.red)
                }
                if item.defBonus > 0 { Text("DEF +\(item.defBonus)").foregroundStyle(Color.blue) }
                if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").foregroundStyle(Color.pink) }
            }
            .font(.caption2)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.rarity.hasAccent
                    ? item.rarity.displayColor.opacity(0.08)
                    : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(item.rarity.hasAccent
                    ? item.rarity.displayColor.opacity(0.25)
                    : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            viewModel.equip(item, context: context)
        }
        .contextMenu {
            if item.enhancementLevel < EnhancementDef.maxLevel {
                Button { pendingEnhanceItem = item } label: {
                    Label("強化", systemImage: "hammer.fill")
                }
            }
            if EnhancementDef.disassembleRefund(defKey: item.defKey) != nil {
                Button(role: .destructive) { pendingDisassembleItem = item } label: {
                    Label("拆解", systemImage: "trash.fill")
                }
            }
        }
    }

    @ViewBuilder
    private func diffBadge(_ diff: StatDiff) -> some View {
        HStack(spacing: 5) {
            if diff.atk != 0 {
                diffItem(icon: "figure.fencing", value: diff.atk)
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
                                    } else if item.rarity.hasAccent {
                                        Text("★").font(.caption2).foregroundStyle(item.rarity.displayColor)
                                    }
                                    Text(item.displayName)
                                        .fontWeight(.medium)
                                        .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : Color.primary)
                                    Spacer()
                                    Text(item.rarity.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : Color.secondary)
                                }

                                // 行 2：完整屬性數值
                                HStack(spacing: 8) {
                                    if item.totalAtk > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "figure.fencing").frame(width: 11, height: 11)
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
                    Image(systemName: "figure.fencing").frame(width: 10, height: 10)
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
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PlayerStateModel.self, MaterialInventoryModel.self,
                                        EquipmentModel.self, TaskModel.self,
                                        configurations: config)
    let appState  = AppState(context: container.mainContext)
    return CharacterView(appState: appState, selectedTab: .constant(2))
        .modelContainer(container)
}
