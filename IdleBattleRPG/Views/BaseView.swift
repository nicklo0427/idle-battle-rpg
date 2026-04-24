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
    @State private var showFarmerSheet    = false   // V7-4
    @State private var farmerSheetPlotIndex: Int = 0
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

                // ── 玩家狀態 ─────────────────────────────────────────
                Section("玩家狀態") {
                    if let player = players.first {
                        HStack {
                            Label("金幣", systemImage: "dollarsign.circle.fill")
                                .foregroundStyle(.yellow)
                            Spacer()
                            Text("\(player.gold)")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        HStack {
                            Label("等級", systemImage: "star.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("Lv.\(player.heroLevel)")
                                .fontWeight(.semibold)
                        }
                    } else {
                        Label {
                            Text("尚無玩家資料")
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill").frame(width: 16, height: 16)
                        }
                        .foregroundStyle(.red)
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
                    player: players.first,
                    inventory: inventories.first,
                    progressionService: appState.progressionService,
                    isPresented: $showCraftSheet
                )
            }
            .sheet(isPresented: $showCuisineSheet) {
                CuisineSheet(
                    viewModel: viewModel,
                    player: players.first,
                    inventory: inventories.first,
                    isPresented: $showCuisineSheet
                )
            }
            .sheet(isPresented: $showPharmacySheet) {
                PharmacySheet(
                    viewModel: viewModel,
                    player: players.first,
                    inventory: inventories.first,
                    isPresented: $showPharmacySheet
                )
            }
            .sheet(isPresented: $showMerchantSheet) {
                MerchantSheet(isPresented: $showMerchantSheet)
            }
            .sheet(isPresented: $showFarmerSheet) {
                FarmerPlotSheet(
                    viewModel: viewModel,
                    plotIndex: farmerSheetPlotIndex,
                    player: players.first,
                    inventory: inventories.first,
                    isPresented: $showFarmerSheet
                )
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

    // MARK: - NPC Tab Sections（V7-4 T06）

    @ViewBuilder
    private func npcGatherSection() -> some View {
        Section("採集者") {
            ForEach(GathererNpcDef.all) { npc in
                npcGathererRow(def: npc, player: players.first)
            }
        }
        npcFarmerSection()
    }

    @ViewBuilder
    private func npcProduceSection() -> some View {
        Section("生產") {
            npcBlacksmithRow(player: players.first)
            npcChefRow(player: players.first)
            npcPharmacistRow(player: players.first)
        }
    }

    @ViewBuilder
    private func npcShopSection() -> some View {
        Section("商店") {
            npcMerchantRow()
        }
    }

    // MARK: - NPC Row: 製藥師（V7-4 T06）

    @ViewBuilder
    private func npcPharmacistRow(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.pharmacistTask(from: tasks)
        let tier = player?.tier(for: AppConstants.Actor.pharmacist) ?? 0

        if let task = activeTask {
            // 製藥中 — 進度條 + 倒數
            HStack(spacing: 12) {
                Image(systemName: "cross.vial.fill")
                    .symbolEffect(.pulse, isActive: true)
                    .foregroundStyle(Color.teal.opacity(0.7))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("製藥師")
                        .fontWeight(.medium)
                    Text("製藥中：\(PotionDef.find(task.definitionKey)?.name ?? task.definitionKey)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                        .font(.caption)
                        .foregroundStyle(.teal)
                    ProgressView(value: task.progress(relativeTo: appState.tick))
                        .tint(.teal)
                        .scaleEffect(y: 0.7)
                        .padding(.top, 1)
                }
                Spacer()
                TierBadgeView(tier: tier)
                Text("製藥中")
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.teal.opacity(0.12))
                    .foregroundStyle(.teal)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 2)
        } else {
            // 閒置 — 點擊開啟 PharmacySheet
            Button(action: { showPharmacySheet = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "cross.vial.fill")
                        .foregroundStyle(Color.teal)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("製藥師")
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("閒置中，點擊選擇配方")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    TierBadgeView(tier: tier)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(NPCDispatchButtonStyle(enabled: true))
            .contextMenu {
                if let player,
                   let cost = appState.npcUpgradeService.nextUpgradeCost(
                       npcKind: .pharmacist, actorKey: AppConstants.Actor.pharmacist, player: player) {
                    let inventory  = inventories.first
                    let canExp     = player.heroExp >= cost.expCost
                    let canMat     = cost.materialCosts.allSatisfy { (mat, req) in (inventory?.amount(of: mat) ?? 0) >= req }
                    let canGold    = player.gold >= cost.goldCost
                    let canUpgrade = canExp && canMat && canGold
                    let matDesc    = cost.materialCosts.map { "\($0.0.icon)×\($0.1)" }.joined(separator: " ")
                    let label      = "升級到 T\(tier + 1)（EXP \(cost.expCost) · \(matDesc) · \(cost.goldCost)金）"
                    Button(canUpgrade ? label : label + "（資源不足）") {
                        pendingUpgradeInfo = NpcUpgradeRequest(
                            npcKind: .pharmacist, actorKey: AppConstants.Actor.pharmacist,
                            label: "製藥師", cost: cost)
                    }
                    .disabled(!canUpgrade)
                } else {
                    Text("已達升級上限").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - NPC Row: 採集者

    @ViewBuilder
    private func npcGathererRow(def: GathererNpcDef, player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.gatherTaskForActor(def.actorKey, from: tasks)
        let isBusy = activeTask != nil
        let tier = player?.tier(for: def.actorKey) ?? 0

        Button(action: { selectedGathererDef = def }) {
            HStack(spacing: 12) {
                Image(systemName: def.icon)
                    .gatheringSymbolEffect(isActive: isBusy)   // T02 採集動畫（iOS 18 呼吸 / iOS 17 脈衝）
                    .foregroundStyle(Color.green.opacity(isBusy ? 0.7 : 1.0))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(def.name)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let task = activeTask, let locDef = GatherLocationDef.find(key: task.definitionKey) {
                        Text("採集中：\(locDef.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.green)
                        ProgressView(value: task.progress(relativeTo: appState.tick))
                            .tint(.green)
                            .scaleEffect(y: 0.7)
                            .padding(.top, 1)
                    } else {
                        Text("閒置中，點擊查看")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                TierBadgeView(tier: tier)

                if isBusy {
                    Text("採集中")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(NPCDispatchButtonStyle(enabled: true))
    }

    // MARK: - NPC Row: 鑄造師

    @ViewBuilder
    private func npcBlacksmithRow(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.craftTask(from: tasks)
        let isBusy = activeTask != nil
        let tier = player?.tier(for: AppConstants.Actor.blacksmith) ?? 0

        Button(action: { if !isBusy { showCraftSheet = true } }) {
            HStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .symbolEffect(.pulse, isActive: isBusy)    // T02 動畫
                    .foregroundStyle(Color.orange.opacity(isBusy ? 0.7 : 1.0))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("鑄造師")
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let task = activeTask, let def = CraftRecipeDef.find(key: task.definitionKey) {
                        Text("鑄造中：\(def.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.orange)
                        ProgressView(value: task.progress(relativeTo: appState.tick))
                            .tint(.orange)
                            .scaleEffect(y: 0.7)
                            .padding(.top, 1)
                    } else {
                        Text("閒置中，點擊委派")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                TierBadgeView(tier: tier)

                if isBusy {
                    Text("鑄造中")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(NPCDispatchButtonStyle(enabled: !isBusy))
        .contextMenu {
            if let player,
               let cost = appState.npcUpgradeService.nextUpgradeCost(
                   npcKind: .blacksmith, actorKey: AppConstants.Actor.blacksmith, player: player) {
                let inventory   = inventories.first
                let canExp      = player.heroExp >= cost.expCost
                let canMat      = cost.materialCosts.allSatisfy { (mat, req) in (inventory?.amount(of: mat) ?? 0) >= req }
                let canGold     = player.gold >= cost.goldCost
                let canUpgrade  = canExp && canMat && canGold
                let matDesc     = cost.materialCosts.map { "\($0.0.icon)×\($0.1)" }.joined(separator: " ")
                let label       = "升級到 T\(tier + 1)（EXP \(cost.expCost) · \(matDesc) · \(cost.goldCost)金）"
                Button(canUpgrade ? label : label + "（資源不足）") {
                    pendingUpgradeInfo = NpcUpgradeRequest(
                        npcKind: .blacksmith, actorKey: AppConstants.Actor.blacksmith, label: "鑄造師", cost: cost)
                }
                .disabled(!canUpgrade)
            } else {
                Text("已達升級上限").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - NPC Row: 廚師（V7-3）

    @ViewBuilder
    private func npcChefRow(player: PlayerStateModel?) -> some View {
        let activeTask = viewModel.cuisineTask(from: tasks)
        let isBusy = activeTask != nil
        let tier = player?.tier(for: AppConstants.Actor.chef) ?? 0

        Button(action: { if !isBusy { showCuisineSheet = true } }) {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .symbolEffect(.pulse, isActive: isBusy)
                    .foregroundStyle(Color.purple.opacity(isBusy ? 0.7 : 1.0))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("廚師")
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let task = activeTask, let def = CuisineDef.find(task.definitionKey) {
                        Text("烹飪中：\(def.icon) \(def.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.purple)
                        ProgressView(value: task.progress(relativeTo: appState.tick))
                            .tint(.purple)
                            .scaleEffect(y: 0.7)
                            .padding(.top, 1)
                    } else {
                        Text("閒置中，點擊委派")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                TierBadgeView(tier: tier)

                if isBusy {
                    Text("烹飪中")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(NPCDispatchButtonStyle(enabled: !isBusy))
        .contextMenu {
            if let player,
               let cost = appState.npcUpgradeService.nextUpgradeCost(
                   npcKind: .chef, actorKey: AppConstants.Actor.chef, player: player) {
                let inventory   = inventories.first
                let canExp      = player.heroExp >= cost.expCost
                let canMat      = cost.materialCosts.allSatisfy { (mat, req) in (inventory?.amount(of: mat) ?? 0) >= req }
                let canGold     = player.gold >= cost.goldCost
                let canUpgrade  = canExp && canMat && canGold
                let matDesc     = cost.materialCosts.map { "\($0.0.icon)×\($0.1)" }.joined(separator: " ")
                let label       = "升級到 T\(tier + 1)（EXP \(cost.expCost) · \(matDesc) · \(cost.goldCost)金）"
                Button(canUpgrade ? label : label + "（資源不足）") {
                    pendingUpgradeInfo = NpcUpgradeRequest(
                        npcKind: .chef, actorKey: AppConstants.Actor.chef, label: "廚師", cost: cost)
                }
                .disabled(!canUpgrade)
            } else {
                Text("已達升級上限").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - NPC Section: 農夫（V7-4）

    @ViewBuilder
    private func npcFarmerSection() -> some View {
        let player = players.first
        let availablePlots = (player?.gatherer5Tier ?? 0) + 1

        Section {
            ForEach(0..<min(availablePlots, AppConstants.FarmerPlot.maxPlots), id: \.self) { index in
                farmerPlotRow(plotIndex: index, player: player)
            }

            // 升級提示（尚未達上限時顯示）
            if let player, player.gatherer5Tier < NpcUpgradeDef.maxTier {
                let nextTier = player.gatherer5Tier + 1
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("升至 T\(nextTier) 解鎖農田 \(nextTier + 1)（長按農田行升級）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("農夫")
            }
        }
    }

    @ViewBuilder
    private func farmerPlotRow(plotIndex: Int, player: PlayerStateModel?) -> some View {
        let plotKey    = AppConstants.FarmerPlot.key(for: plotIndex)
        let activeTask = viewModel.farmingTask(plotKey: plotKey, from: tasks)
        let tier       = player?.gatherer5Tier ?? 0

        // 可收穫（completed 且非 battlePending）
        let completedTask = tasks.first {
            $0.actorKey == plotKey && $0.kind == .farming && $0.status == .completed
        }

        if let completed = completedTask {
            // 狀態：可收穫 → 高亮，點擊收下
            Button {
                appState.claimAllCompleted()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "basket.fill")
                        .foregroundStyle(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("農田 \(plotIndex + 1)")
                            .fontWeight(.medium)
                        Text("✅ 可收穫！點擊收下")
                            .font(.caption)
                            .foregroundStyle(.green)
                        if let seedType = MaterialType(rawValue: completed.definitionKey) {
                            Text("種植：\(seedType.icon) \(seedType.displayName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("收穫")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(NPCDispatchButtonStyle(enabled: true))

        } else if let task = activeTask {
            // 狀態：生長中 → 顯示進度
            HStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .symbolEffect(.pulse, isActive: true)
                    .foregroundStyle(Color.green.opacity(0.7))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("農田 \(plotIndex + 1)")
                        .fontWeight(.medium)
                    if let seedType = MaterialType(rawValue: task.definitionKey) {
                        Text("生長中：\(seedType.icon) \(seedType.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                        .font(.caption)
                        .foregroundStyle(.green)
                    ProgressView(value: task.progress(relativeTo: appState.tick))
                        .tint(.green)
                        .scaleEffect(y: 0.7)
                        .padding(.top, 1)
                }
                Spacer()
                Text("生長中")
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 2)

        } else {
            // 狀態：空閒 → 點擊種植
            Button {
                farmerSheetPlotIndex = plotIndex
                showFarmerSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .foregroundStyle(Color.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("農田 \(plotIndex + 1)")
                            .fontWeight(.medium)
                        Text("空閒，點擊種植")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    TierBadgeView(tier: tier)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(NPCDispatchButtonStyle(enabled: true))
            .contextMenu {
                if let player,
                   let cost = appState.npcUpgradeService.nextUpgradeCost(
                       npcKind: .farmer, actorKey: plotKey, player: player) {
                    let inventory  = inventories.first
                    let canExp     = player.heroExp >= cost.expCost
                    let canMat     = cost.materialCosts.allSatisfy { (mat, req) in (inventory?.amount(of: mat) ?? 0) >= req }
                    let canGold    = player.gold >= cost.goldCost
                    let canUpgrade = canExp && canMat && canGold
                    let matDesc    = cost.materialCosts.map { "\($0.0.icon)×\($0.1)" }.joined(separator: " ")
                    let label      = "升級到 T\(tier + 1)（EXP \(cost.expCost) · \(matDesc) · \(cost.goldCost)金）"
                    Button(canUpgrade ? label : label + "（資源不足）") {
                        pendingUpgradeInfo = NpcUpgradeRequest(
                            npcKind: .farmer, actorKey: plotKey, label: "農夫", cost: cost)
                    }
                    .disabled(!canUpgrade)
                } else {
                    Text("已達升級上限").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - NPC Row: 商人

    @ViewBuilder
    private func npcMerchantRow() -> some View {
        Button(action: { showMerchantSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "storefront.fill")
                    .foregroundStyle(Color.yellow)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("商人")
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("點擊開啟商店")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(NPCDispatchButtonStyle(enabled: true))
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
