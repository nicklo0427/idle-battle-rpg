// BaseView.swift
// 基地 Tab — Phase 9
//
// 顯示內容：
//   - 玩家金幣、等級（收下後即時更新）
//   - 素材庫存（收下後即時更新）
//   - NPC 列表：採集者 ×2（點擊 → GathererDetailSheet）、鑄造師（點閒置 → CraftSheet）
//   - 開發模式（標示清楚，置底）

import SwiftUI
import SwiftData

struct BaseView: View {

    let appState: AppState

    @Environment(\.modelContext) private var context

    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]
    @Query private var tasks:       [TaskModel]

    @State private var viewModel = BaseViewModel()

    // V7-4 T06：NPC 分頁
    private enum BaseTab: String, CaseIterable {
        case gather  = "採集"
        case produce = "生產"
        case shop    = "商店"
    }

    // Sheet 狀態
    @State private var selectedGathererDef: GathererNpcDef?
    @State private var showCraftSheet     = false
    @State private var showCuisineSheet   = false   // V7-3
    @State private var showPharmacySheet  = false   // V7-4
    @State private var showMerchantSheet  = false
    @State private var showFarmerDetailSheet = false  // V7-4
    @State private var baseTab: BaseTab = .gather

    // NPC 升級確認 Alert
    @State private var pendingUpgradeInfo: NpcUpgradeRequest?

    var body: some View {
        NavigationStack {
            List {

                // ── Onboarding 引導 Banner（完成後自動隱藏）────────────
                if let player = players.first, player.onboardingStep < 3 {
                    OnboardingBannerView(step: player.onboardingStep) {
                        viewModel.advanceOnboarding(
                            expectedStep: player.onboardingStep,
                            player: player,
                            context: context
                        )
                    }
                }

                // ── NPC 分頁 Picker（V7-4 T06）────────────────────────
                Section {
                    Picker("分頁", selection: $baseTab) {
                        ForEach(BaseTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }

                switch baseTab {
                case .gather:  npcGatherSection()
                case .produce: npcProduceSection()
                case .shop:    npcShopSection()
                }

                // ── 開發模式（Debug build 限定）────────────────────────
                #if DEBUG
                Section {
                    // 金幣
                    Button { devAddGold(500) } label: {
                        Label("金幣 +500", systemImage: "dollarsign.circle")
                    }
                    Button { devAddGold(5000) } label: {
                        Label("金幣 +5,000", systemImage: "dollarsign.circle.fill")
                    }
                } header: {
                    Text("⚙️ 開發模式（Debug Only）")
                }

                Section("任務") {
                    Button { devExpireAllTasks() } label: {
                        Label("快速完成所有進行中任務", systemImage: "bolt.fill")
                    }
                    .tint(.orange)
                    Button { appState.scanAndSettle() } label: {
                        Label("手動觸發結算掃描", systemImage: "arrow.clockwise")
                    }
                }

                Section("素材") {
                    Button { devAddMaterials(10) } label: {
                        Label("各素材 +10", systemImage: "shippingbox.fill")
                    }
                }

                Section("角色") {
                    Button { devSetMaxLevel() } label: {
                        Label("升至最高等級 Lv.\(AppConstants.Game.heroMaxLevel)", systemImage: "arrow.up.forward.circle")
                    }
                    Button { devUnequipAll() } label: {
                        Label("卸除所有裝備（測試低戰力）", systemImage: "shield.slash")
                    }
                    .tint(.red)
                }

                Section("NPC 升級") {
                    Button { devResetNpcTiers() } label: {
                        Label("重置所有 NPC Tier 至 0", systemImage: "arrow.uturn.backward.circle")
                    }
                    .tint(.red)
                    Button { devResetFirstBoosts() } label: {
                        Label("重置首次加速 Flag（鑄造 / 出征）", systemImage: "flag.slash")
                    }
                    .tint(.red)
                }

                Section {
                    Button { devUnlockAllRegions() } label: {
                        Label("解鎖所有區域（標記所有 Boss 首通）", systemImage: "lock.open.fill")
                    }
                } header: {
                    Text("地下城")
                }

                Section {
                    Button { devSetupV8Test() } label: {
                        Label("V8-1 驗證資料（稀有/史詩裝備 + 素材 + 鑄造師 T3）", systemImage: "flask.fill")
                    }
                    .tint(.purple)
                } header: {
                    Text("V8-1 驗證")
                }

                Section {
                    Button { devSetupV8_2Test() } label: {
                        Label("V8-2 驗證資料（生產者技能 + 精良裝備 + 消耗品）", systemImage: "star.fill")
                    }
                    .tint(.purple)
                } header: {
                    Text("V8-2 驗證")
                } footer: {
                    Text("此區塊僅在 Debug build 顯示，Release / TestFlight 不可見。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .navigationTitle("基地")
            .sheet(item: $selectedGathererDef) { npc in
                GathererDetailSheet(
                    npcDef:   npc,
                    appState: appState,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showCraftSheet) {
                CraftSheet(
                    viewModel: viewModel,
                    appState: appState,
                    player: players.first,
                    inventory: inventories.first,
                    progressionService: appState.progressionService
                )
            }
            .sheet(isPresented: $showCuisineSheet) {
                CuisineSheet(
                    viewModel: viewModel,
                    appState: appState,
                    player: players.first,
                    inventory: inventories.first
                )
            }
            .sheet(isPresented: $showPharmacySheet) {
                PharmacySheet(
                    viewModel: viewModel,
                    appState: appState,
                    player: players.first,
                    inventory: inventories.first
                )
            }
            .sheet(isPresented: $showMerchantSheet) {
                MerchantSheet(isPresented: $showMerchantSheet)
            }
            .sheet(isPresented: $showFarmerDetailSheet) {
                FarmerDetailSheet(viewModel: viewModel, appState: appState)
            }
            .alert(item: $pendingUpgradeInfo) { info in
                let player = players.first
                let inventory = inventories.first
                let matDesc = info.cost.materialCosts
                    .map { "\($0.0.displayName) ×\($0.1)（持有：\(inventory?.amount(of: $0.0) ?? 0)）" }
                    .joined(separator: "\n")
                let expLine  = "EXP：\(info.cost.expCost)（持有：\(player?.heroExp ?? 0)）"
                let goldLine = "金幣：\(info.cost.goldCost)（持有：\(player?.gold ?? 0)）"
                let message  = [expLine, matDesc, goldLine].filter { !$0.isEmpty }.joined(separator: "\n")
                return Alert(
                    title: Text("升級 \(info.label)？"),
                    message: Text(message),
                    primaryButton: .default(Text("確認升級")) {
                        if let player {
                            appState.npcUpgradeService.upgrade(
                                npcKind: info.npcKind,
                                actorKey: info.actorKey,
                                player: player
                            )
                        }
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
        // V6-1：職業選擇（新遊戲 或 舊存檔 classKey = "" 時強制顯示）
        .fullScreenCover(isPresented: Binding(
            get: { players.first?.classKey.isEmpty == true },
            set: { _ in }   // 不允許外部關閉，必須選職業
        )) {
            ClassSelectionView()
        }
    }

    // MARK: - NPC Tab Sections（V9-2 T01）

    @ViewBuilder
    private func npcGatherSection() -> some View {
        Section("採集者營地") {
            ForEach(GathererNpcDef.all) { npc in
                npcGathererCard(def: npc, player: players.first)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            npcFarmerCard()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private func npcProduceSection() -> some View {
        Section("生產者小屋") {
            npcBlacksmithCard(player: players.first)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            npcChefCard(player: players.first)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            npcPharmacistCard(player: players.first)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private func npcShopSection() -> some View {
        Section("商人的市集") {
            npcMerchantCard()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    // MARK: - NPC Card: 共用狀態圓點（V9-2 T01）

    private func npcStatusBadge(isBusy: Bool) -> some View {
        Circle()
            .fill(isBusy ? Color.green : Color.secondary.opacity(0.3))
            .frame(width: 10, height: 10)
            .padding(6)
    }

    // MARK: - NPC Card: 採集者

    @ViewBuilder
    private func npcGathererCard(def: GathererNpcDef, player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.gatherTaskForActor(def.actorKey, from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: def.actorKey) ?? 0
        let caption: String = {
            guard let task = activeTask,
                  let locDef = GatherLocationDef.find(key: task.definitionKey) else { return "閒置中" }
            return "採集中：\(locDef.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()
        let progress = activeTask.map { $0.progress(relativeTo: appState.tick) }

        Button { selectedGathererDef = def } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_\(def.actorKey)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isBusy ? 0.85 : 1.0)
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: def.actorKey) ?? def.name)
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.green : .secondary)
                        .lineLimit(2)
                    if let progress {
                        ProgressView(value: progress)
                            .tint(.green)
                            .scaleEffect(y: 0.6)
                    }
                }

                Spacer()

                if isBusy {
                    Text("採集中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(Color.green)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 農夫

    @ViewBuilder
    private func npcFarmerCard() -> some View {
        let tier  = players.first?.gatherer5Tier ?? 0
        let plots = min(tier + 1, AppConstants.FarmerPlot.maxPlots)

        Button { showFarmerDetailSheet = true } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_farmer")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    npcStatusBadge(isBusy: false)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(players.first?.npcDisplayName(for: "farmer") ?? "農夫")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text("農田 \(plots) 塊 · 點擊管理")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 鑄造師

    @ViewBuilder
    private func npcBlacksmithCard(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.craftTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.blacksmith) ?? 0
        let caption: String = {
            guard let task = activeTask,
                  let def = CraftRecipeDef.find(key: task.definitionKey) else { return "閒置中，點擊委派" }
            return "鑄造中：\(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()
        let progress = activeTask.map { $0.progress(relativeTo: appState.tick) }

        Button { if !isBusy { showCraftSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_blacksmith")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isBusy ? 0.85 : 1.0)
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.blacksmith) ?? "鑄造師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.orange : .secondary)
                        .lineLimit(2)
                    if let progress {
                        ProgressView(value: progress)
                            .tint(.orange)
                            .scaleEffect(y: 0.6)
                    }
                }

                Spacer()

                if isBusy {
                    Text("鑄造中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 廚師

    @ViewBuilder
    private func npcChefCard(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.cuisineTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.chef) ?? 0
        let caption: String = {
            guard let task = activeTask,
                  let def = CuisineDef.find(task.definitionKey) else { return "閒置中，點擊委派" }
            return "烹飪中：\(def.icon) \(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()
        let progress = activeTask.map { $0.progress(relativeTo: appState.tick) }

        Button { if !isBusy { showCuisineSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_chef")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isBusy ? 0.85 : 1.0)
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.chef) ?? "廚師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.purple : .secondary)
                        .lineLimit(2)
                    if let progress {
                        ProgressView(value: progress)
                            .tint(.purple)
                            .scaleEffect(y: 0.6)
                    }
                }

                Spacer()

                if isBusy {
                    Text("烹飪中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(Color.purple)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 製藥師

    @ViewBuilder
    private func npcPharmacistCard(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.pharmacistTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.pharmacist) ?? 0
        let caption: String = {
            guard let task = activeTask,
                  let def = PotionDef.find(task.definitionKey) else { return "閒置中，點擊選擇" }
            return "製藥中：\(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()
        let progress = activeTask.map { $0.progress(relativeTo: appState.tick) }

        Button { if !isBusy { showPharmacySheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_pharmacist")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isBusy ? 0.85 : 1.0)
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.pharmacist) ?? "製藥師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.teal : .secondary)
                        .lineLimit(2)
                    if let progress {
                        ProgressView(value: progress)
                            .tint(.teal)
                            .scaleEffect(y: 0.6)
                    }
                }

                Spacer()

                if isBusy {
                    Text("製藥中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.teal.opacity(0.12))
                        .foregroundStyle(Color.teal)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 商人

    @ViewBuilder
    private func npcMerchantCard() -> some View {
        Button { showMerchantSheet = true } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(webp: "npc_merchant")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    npcStatusBadge(isBusy: false)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(players.first?.npcDisplayName(for: "merchant") ?? "商人")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                    Text("點擊開啟商店")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    private func devAddGold(_ amount: Int) {
        guard let player = players.first else { return }
        player.gold += amount
        try? context.save()
    }

    private func devAddMaterials(_ amount: Int) {
        guard let inv = inventories.first else { return }
        inv.wood             += amount
        inv.ore              += amount
        inv.hide             += amount
        inv.crystalShard     += amount
        inv.ancientFragment  += amount
        inv.ancientWood      += amount
        inv.refinedOre       += amount
        inv.herb             += amount
        inv.spiritHerb       += amount
        inv.freshFish        += amount
        inv.abyssFish        += amount
        // V7-4 種子
        inv.wheatSeed        += amount
        inv.vegetableSeed    += amount
        inv.fruitSeed        += amount
        inv.spiritGrainSeed  += amount
        try? context.save()
    }

    /// 把所有進行中任務的 endsAt 改為過去，讓 scanAndSettle 立即結算
    private func devExpireAllTasks() {
        let now = Date.now
        tasks.filter { $0.status == .inProgress }.forEach { task in
            let duration = task.endsAt.timeIntervalSince(task.startedAt)
            task.startedAt = now.addingTimeInterval(-duration - 2)
            task.endsAt    = now.addingTimeInterval(-2)
        }
        try? context.save()
        appState.scanAndSettle()
    }

    private func devUnequipAll() {
        let all = (try? context.fetch(FetchDescriptor<EquipmentModel>())) ?? []
        all.forEach { $0.isEquipped = false }
        try? context.save()
    }

    private func devSetMaxLevel() {
        guard let player = players.first else { return }
        player.heroLevel           = AppConstants.Game.heroMaxLevel
        player.availableStatPoints = 0
        try? context.save()
    }

    private func devResetNpcTiers() {
        guard let player = players.first else { return }
        player.gatherer1Tier  = 0
        player.gatherer2Tier  = 0
        player.blacksmithTier = 0
        player.gatherer3Tier  = 0
        player.gatherer4Tier  = 0
        player.chefTier       = 0
        player.gatherer5Tier  = 0   // V7-4 農夫
        player.pharmacistTier = 0   // V7-4 製藥師
        player.gatherer1SkillPoints = 0;  player.gatherer1SkillsRaw = ""
        player.gatherer2SkillPoints = 0;  player.gatherer2SkillsRaw = ""
        player.gatherer3SkillPoints = 0;  player.gatherer3SkillsRaw = ""
        player.gatherer4SkillPoints = 0;  player.gatherer4SkillsRaw = ""
        try? context.save()
    }

    private func devResetFirstBoosts() {
        guard let player = players.first else { return }
        player.hasUsedFirstCraftBoost   = false
        player.hasUsedFirstDungeonBoost = false
        try? context.save()
    }

    /// 標記所有地區所有樓層首通，解鎖全部區域
    private func devUnlockAllRegions() {
        let svc = appState.progressionService
        for region in DungeonRegionDef.all {
            for floor in region.floors {
                svc.markFloorCleared(regionKey: floor.regionKey, floorIndex: floor.floorIndex)
            }
        }
    }

    /// V8-2 驗證用：注入所有生產者技能（Lv2~3）+ 精良裝備已裝備 + 消耗品庫存
    private func devSetupV8_2Test() {
        guard let player = players.first,
              let inv    = inventories.first else { return }

        // ── 生產者 Tier ─────────────────────────────────────────────
        player.blacksmithTier  = 3
        player.chefTier        = 3
        player.pharmacistTier  = 3
        player.gatherer5Tier   = 3   // 農夫 tier

        // ── 生產者技能（直接注入 raw，全部 Lv2）────────────────────
        // bs_gold Lv2 → 鑄造金幣 -20%；bs_mastery Lv2 → 精良+以上屬性 ×1.10
        player.blacksmithSkillPoints = 0
        player.blacksmithSkillsRaw   = "bs_gold,bs_gold,bs_mastery,bs_mastery"

        // ch_portion Lv2 → 25% 多產料理；ch_flavor Lv2 → 料理 buff ×1.20
        player.chefSkillPoints = 0
        player.chefSkillsRaw   = "ch_portion,ch_portion,ch_flavor,ch_flavor"

        // ph_yield Lv2 → 20% 多產藥水；ph_potency Lv2 → 藥水回復 ×1.20
        player.pharmacistSkillPoints = 0
        player.pharmacistSkillsRaw   = "ph_yield,ph_yield,ph_potency,ph_potency"

        // fa_yield Lv2 → 60% 額外農作物；fa_quality Lv3 → 品質機率 +30%
        player.farmerSkillPoints = 0
        player.farmerSkillsRaw   = "fa_yield,fa_yield,fa_quality,fa_quality,fa_quality"

        // ── 金幣 + 素材（鑄造、料理、煉藥用）──────────────────────
        player.gold += 10_000
        inv.wood            += 50;  inv.ore             += 50
        inv.hide            += 50;  inv.crystalShard    += 50
        inv.ancientFragment += 50;  inv.herb            += 50
        inv.spiritHerb      += 50;  inv.freshFish       += 50
        inv.wheatSeed       += 20;  inv.vegetableSeed   += 20
        inv.fruitSeed       += 20;  inv.spiritGrainSeed += 20

        // ── 精良武器 + 防具（已裝備，用於驗證 bs_mastery）──────────
        let refinedWeapon = EquipmentModel(
            defKey: "refined_weapon", slot: .weapon,
            rarity: .refined, isEquipped: true
        )
        let refinedArmor = EquipmentModel(
            defKey: "refined_armor", slot: .armor,
            rarity: .refined, isEquipped: true
        )
        context.insert(refinedWeapon)
        context.insert(refinedArmor)

        // ── 消耗品（料理 + 藥水，用於驗證 ch_flavor / ph_potency）──
        let consumable = (try? context.fetch(FetchDescriptor<ConsumableInventoryModel>()))?.first
        consumable?.add(of: .fishStew)            // 魚肉燉鍋（料理 buff 驗證）
        consumable?.add(of: .fishStew)
        consumable?.add(of: .smallPotion)         // 小型藥水（藥水回復驗證）
        consumable?.add(of: .smallPotion)

        try? context.save()
    }

    /// V8-1 驗證用：注入稀有/史詩素材、鑄造師 Tier 3、稀有/史詩裝備各一件
    private func devSetupV8Test() {
        guard let player = players.first,
              let inv    = inventories.first else { return }

        // 金幣 + EXP（鑄造師第 4 階需 8000 金 + 2000 EXP）
        player.gold    += 30_000
        player.heroExp += 5_000

        // 鑄造師升到 Tier 3（可測試第 4 階升級）
        player.blacksmithTier = 3

        // 沉沒之城素材（稀有/史詩配方原料 + 鑄造師升階）
        inv.sunkenRuneShard      += 10
        inv.abyssalCrystalDrop   += 10
        inv.drownedCrownFragment += 10
        inv.sunkenKingSeal       += 10

        // V7 採集素材（稀有/史詩配方輔助原料）
        inv.spiritHerb  += 20
        inv.abyssFish   += 20
        inv.ancientWood += 20

        // 頂級農作物（史詩配方必需）
        inv.wheatTop       += 10
        inv.fruitTop       += 10
        inv.spiritGrainTop += 10

        // 稀有武器（enhancementLevel 5，可測試強化 +6/+7/+8）
        let rare = EquipmentModel(
            defKey: "rare_weapon", slot: .weapon, rarity: .rare,
            isEquipped: false, enhancementLevel: 5
        )
        context.insert(rare)

        // 史詩武器（未強化，測試顏色）
        let epic = EquipmentModel(
            defKey: "epic_weapon", slot: .weapon, rarity: .epic,
            isEquipped: false, enhancementLevel: 0
        )
        context.insert(epic)

        try? context.save()
    }
    #endif
}

// MARK: - NPC 升級請求（Alert Identifiable）

private struct NpcUpgradeRequest: Identifiable {
    let id = UUID()
    let npcKind: NpcKind
    let actorKey: String
    let label: String
    let cost: NpcUpgradeCostDef
}

#Preview {
    BaseView(appState: {
        let container = try! ModelContainer(
            for: PlayerStateModel.self, MaterialInventoryModel.self,
                 EquipmentModel.self, TaskModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return AppState(context: container.mainContext)
    }())
    .modelContainer(for: [
        PlayerStateModel.self, MaterialInventoryModel.self,
        EquipmentModel.self, TaskModel.self,
    ], inMemory: true)
}
