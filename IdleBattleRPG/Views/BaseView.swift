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
    @Binding var selectedTab: Int

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
    @State private var showOffhandSheet      = false  // V10-1 鍛造學徒
    @State private var showAccessorySheet    = false  // V10-1 飾品師
    @State private var showTailorSheet       = false  // V10-1 裁縫師
    @State private var baseTab: BaseTab = .gather

    // NPC 升級確認 Alert
    @State private var pendingUpgradeInfo: NpcUpgradeRequest?

    var body: some View {
        NavigationStack {
            List {

                // ── 教程進行中提示 ───────────────────────────────
                if let player = players.first, player.onboardingStep < OnboardingService.completedStep {
                    tutorialHintBanner(step: player.onboardingStep)
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
                        Label("重置教程 & 首次出征 Flag", systemImage: "flag.slash")
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
            .onAppear {
                syncBaseTabForOnboarding()
                appState.onboardingService.prepareForCurrentStep()
            }
            .onChange(of: players.first?.onboardingStep) { _, _ in
                syncBaseTabForOnboarding()
                appState.onboardingService.prepareForCurrentStep()
            }
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
                MerchantSheet(
                    isPresented: $showMerchantSheet,
                    appState: appState,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showFarmerDetailSheet) {
                FarmerDetailSheet(viewModel: viewModel, appState: appState)
            }
            .sheet(isPresented: $showOffhandSheet) {
                OffhandSheet(
                    appState:           appState,
                    player:             players.first,
                    inventory:          inventories.first,
                    progressionService: appState.progressionService
                )
            }
            .sheet(isPresented: $showAccessorySheet) {
                AccessorySheet(
                    appState:           appState,
                    player:             players.first,
                    inventory:          inventories.first,
                    progressionService: appState.progressionService
                )
            }
            .sheet(isPresented: $showTailorSheet) {
                TailorSheet(
                    appState:           appState,
                    player:             players.first,
                    inventory:          inventories.first,
                    progressionService: appState.progressionService
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
    }

    // MARK: - Tutorial（T06）

    private func tutorialStepInfo(step: Int) -> (hint: [TutorialTextRun], flavor: String)? {
        guard let info = OnboardingService.stepInfo(step: step) else { return nil }
        return (info.hint, info.flavor)
    }

    /// 教程進行中的頂部提示 Banner（P1 進度條 + P2 情境文字）
    @ViewBuilder
    private func tutorialHintBanner(step: Int) -> some View {
        if let info = tutorialStepInfo(step: step) {
            let totalSteps  = OnboardingService.totalSteps
            let currentStep = step + 1
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.orange)
                        TutorialRichText(runs: info.hint, font: .subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(currentStep)/\(totalSteps)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.orange.opacity(0.7))
                            .fontWeight(.semibold)
                    }
                    Text(info.flavor)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SmoothLinearProgressBar(
                        value: Double(currentStep),
                        total: Double(totalSteps),
                        tint: .orange,
                        height: 4
                    )
                }
                .listRowBackground(Color.orange.opacity(0.08))
            }
        }
    }

    /// 教程期間（step < 3）判斷 NPC 是否可互動
    private func isNpcUnlocked(actorKey: String, step: Int) -> Bool {
        if step >= 3 { return true }
        if step <= 1 { return actorKey == AppConstants.Actor.gatherer1 }
        // step == 2
        return actorKey == AppConstants.Actor.gatherer1 || actorKey == AppConstants.Actor.blacksmith
    }

    private func syncBaseTabForOnboarding() {
        guard let step = players.first?.onboardingStep else { return }
        switch step {
        case 0, 16, 20, 21:
            baseTab = .gather
        case 2, 5, 7, 17, 18:
            baseTab = .produce
        case 15:
            baseTab = .shop
        default:
            break
        }
    }

    // MARK: - NPC Tab Sections（V9-2 T01）

    @ViewBuilder
    private func npcGatherSection() -> some View {
        Section("採集者營地") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ],
                spacing: 10
            ) {
                ForEach(GathererNpcDef.all) { npc in
                    npcGathererMiniCard(def: npc, player: players.first)
                }
                npcFarmerMiniCard()
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private func npcProduceSection() -> some View {
        Section("生產者小屋") {
            let player = players.first
            let step = player?.onboardingStep ?? 3

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ],
                spacing: 10
            ) {
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.blacksmith,
                    fallbackName: "鑄造師老鐵",
                    imageName: "npc_blacksmith",
                    roleName: "⚔️ 主手武器",
                    color: .orange,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.blacksmith, step: step),
                    idleStatus: "閒置，點擊製作",
                    busyStatus: "鑄造中",
                    completedStatus: "裝備完成，等待收下",
                    player: player,
                    onOpen: { showCraftSheet = true }
                )
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.weaponsmith,
                    fallbackName: "鍛造學徒小錘",
                    imageName: "npc_weaponsmith",
                    roleName: "🛡️ 副手製作",
                    color: .orange,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.weaponsmith, step: step),
                    idleStatus: "閒置，點擊製作",
                    busyStatus: "鑄造中",
                    completedStatus: "副手完成，等待收下",
                    player: player,
                    onOpen: { showOffhandSheet = true }
                )
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.tailor,
                    fallbackName: "裁縫師阿針",
                    imageName: "npc_tailor",
                    roleName: "🧥 防具製作",
                    color: .teal,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.tailor, step: step),
                    idleStatus: "閒置，點擊製作",
                    busyStatus: "製作中",
                    completedStatus: "防具完成，等待收下",
                    player: player,
                    onOpen: { showTailorSheet = true }
                )
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.jeweler,
                    fallbackName: "飾品師銀鈴",
                    imageName: "npc_jeweler",
                    roleName: "💍 飾品製作",
                    color: .purple,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.jeweler, step: step),
                    idleStatus: "閒置，點擊製作",
                    busyStatus: "鑄造中",
                    completedStatus: "飾品完成，等待收下",
                    player: player,
                    onOpen: { showAccessorySheet = true }
                )
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.chef,
                    fallbackName: "廚師阿灶",
                    imageName: "npc_chef",
                    roleName: "🍲 料理烹飪",
                    color: .purple,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.chef, step: step),
                    idleStatus: "閒置，點擊烹飪",
                    busyStatus: "烹飪中",
                    completedStatus: "料理完成，等待收下",
                    player: player,
                    onOpen: { showCuisineSheet = true }
                )
                npcProducerMiniCard(
                    actorKey: AppConstants.Actor.pharmacist,
                    fallbackName: "藥師白芷",
                    imageName: "npc_pharmacist",
                    roleName: "🧪 藥水煉製",
                    color: .teal,
                    unlocked: isNpcUnlocked(actorKey: AppConstants.Actor.pharmacist, step: step),
                    idleStatus: "閒置，點擊煉製",
                    busyStatus: "製藥中",
                    completedStatus: "藥水完成，等待收下",
                    player: player,
                    onOpen: { showPharmacySheet = true }
                )
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 8, trailing: 16))
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

    // MARK: - 採集雙欄小卡（V10-4A）

    @ViewBuilder
    private func npcGathererMiniCard(def: GathererNpcDef, player: PlayerStateModel?) -> some View {
        let step          = player?.onboardingStep ?? 3
        let unlocked      = isNpcUnlocked(actorKey: def.actorKey, step: step)
        let activeTask    = viewModel.gatherTaskForActor(def.actorKey, from: tasks)
        let completedTask = tasks.first {
            $0.actorKey == def.actorKey && $0.kind == .gather && $0.status == .completed
        }
        let tier          = player?.tier(for: def.actorKey) ?? 0
        let color         = gathererColor(for: def.role)
        let locName       = activeTask.flatMap { GatherLocationDef.find(key: $0.definitionKey)?.name }
        let primaryOutput = primaryOutputText(for: def)
        let isTutorialTarget = OnboardingService.targetActor(for: step) == def.actorKey
        let statusText: String = {
            if !unlocked { return gathererLockedText(step: step) }
            if completedTask != nil { return "已完成，等待收下" }
            if let activeTask {
                return "\(locName ?? "採集中") · \(TaskCountdown.remaining(for: activeTask, relativeTo: appState.tick))"
            }
            if isTutorialTarget { return "下一步，點擊查看" }
            return "閒置，點擊派遣"
        }()

        Button {
            guard unlocked else { return }
            if completedTask != nil {
                appState.presentCompletedTasksIfNeeded()
            } else {
                selectedGathererDef = def
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_\(def.actorKey)",
                        height: 96,
                        cornerRadius: 10,
                        padding: 5,
                        imageOpacity: unlocked ? 1.0 : 0.45,
                        fillWidth: true
                    )

                    miniStatusBadge(
                        title: completedTask != nil ? "完成" : activeTask != nil ? "工作中" : isTutorialTarget ? "下一步" : unlocked ? "閒置" : "鎖定",
                        color: completedTask != nil ? .orange : activeTask != nil ? color : isTutorialTarget ? .orange : unlocked ? .secondary : .gray
                    )
                    .padding(6)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 {
                        TierBadgeView(tier: tier, color: color)
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(player?.npcDisplayName(for: def.actorKey) ?? def.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(minHeight: 32, alignment: .topLeading)

                    Text(primaryOutput)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(completedTask != nil ? .semibold : .regular)
                        .foregroundStyle(completedTask != nil ? Color.orange : activeTask != nil ? color : .secondary)
                        .lineLimit(2)
                        .frame(minHeight: 30, alignment: .topLeading)

                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: color, height: 4)
                    } else {
                        SmoothLinearProgressBar(
                            value: completedTask != nil ? 1.0 : 0.0,
                            tint: completedTask != nil ? .orange : color.opacity(0.25),
                            height: 4
                        )
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 212, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke((completedTask != nil || isTutorialTarget ? Color.orange : Color.clear).opacity(0.55), lineWidth: 1)
            }
            .opacity(unlocked ? 1.0 : 0.62)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func npcFarmerMiniCard() -> some View {
        let step           = players.first?.onboardingStep ?? 3
        let unlocked       = isNpcUnlocked(actorKey: "farmer", step: step)
        let tier           = players.first?.gatherer5Tier ?? 0
        let plots          = min(tier + 1, AppConstants.FarmerPlot.maxPlots)
        let activeTasks    = tasks.filter {
            AppConstants.FarmerPlot.keys.contains($0.actorKey) &&
            $0.kind == .farming &&
            $0.status == .inProgress
        }
        let completedTask  = tasks.first {
            AppConstants.FarmerPlot.keys.contains($0.actorKey) &&
            $0.kind == .farming &&
            $0.status == .completed
        }
        let activeTask     = activeTasks.first
        let isTutorialTarget = OnboardingService.targetActor(for: step) == "farmer"
        let statusText: String = {
            if !unlocked { return gathererLockedText(step: step) }
            if completedTask != nil { return "作物成熟，等待收下" }
            if let activeTask {
                return "農作中 \(activeTasks.count)/\(plots) · \(TaskCountdown.remaining(for: activeTask, relativeTo: appState.tick))"
            }
            if isTutorialTarget { return "下一步，種下小麥" }
            return "農田管理，點擊查看"
        }()

        Button {
            guard unlocked else { return }
            if completedTask != nil {
                appState.presentCompletedTasksIfNeeded()
            } else {
                showFarmerDetailSheet = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_farmer",
                        height: 96,
                        cornerRadius: 10,
                        padding: 5,
                        imageOpacity: unlocked ? 1.0 : 0.45,
                        fillWidth: true
                    )

                    miniStatusBadge(
                        title: completedTask != nil ? "完成" : activeTask != nil ? "工作中" : isTutorialTarget ? "下一步" : unlocked ? "管理" : "鎖定",
                        color: completedTask != nil ? .orange : activeTask != nil ? .yellow : isTutorialTarget ? .orange : unlocked ? .secondary : .gray
                    )
                    .padding(6)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 {
                        TierBadgeView(tier: tier, color: .yellow)
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(players.first?.npcDisplayName(for: "farmer") ?? "農夫老禾")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(minHeight: 32, alignment: .topLeading)

                    Text("🌾 農田 \(plots) 塊")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(completedTask != nil ? .semibold : .regular)
                        .foregroundStyle(completedTask != nil ? Color.orange : activeTask != nil ? Color.yellow : .secondary)
                        .lineLimit(2)
                        .frame(minHeight: 30, alignment: .topLeading)

                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: .yellow, height: 4)
                    } else {
                        SmoothLinearProgressBar(
                            value: completedTask != nil ? 1.0 : 0.0,
                            tint: completedTask != nil ? .orange : .yellow.opacity(0.25),
                            height: 4
                        )
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 212, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke((completedTask != nil || isTutorialTarget ? Color.orange : Color.clear).opacity(0.55), lineWidth: 1)
            }
            .opacity(unlocked ? 1.0 : 0.62)
        }
        .buttonStyle(.plain)
    }

    private func miniStatusBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial)
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func gathererColor(for role: GathererRole) -> Color {
        switch role {
        case .woodcutter: return .green
        case .miner:      return .gray
        case .herbalist:  return .mint
        case .fisherman:  return .cyan
        }
    }

    private func primaryOutputText(for def: GathererNpcDef) -> String {
        guard let material = def.locationKeys
            .compactMap({ GatherLocationDef.find(key: $0)?.outputMaterial })
            .first else {
            return "素材採集"
        }
        return "\(material.icon) \(material.displayName)"
    }

    private func gathererLockedText(step: Int) -> String {
        step < 3 ? "完成初始武器教程解鎖" : "尚未解鎖"
    }

    // MARK: - 生產雙欄小卡（V10-4B）

    @ViewBuilder
    private func npcProducerMiniCard(
        actorKey: String,
        fallbackName: String,
        imageName: String,
        roleName: String,
        color: Color,
        unlocked: Bool,
        idleStatus: String,
        busyStatus: String,
        completedStatus: String,
        player: PlayerStateModel?,
        onOpen: @escaping () -> Void
    ) -> some View {
        let activeTask = productionActiveTask(actorKey: actorKey)
        let completedTask = productionCompletedTask(actorKey: actorKey)
        let tier = player?.tier(for: actorKey) ?? 0
        let taskName = activeTask.map { productionTaskName($0) }
        let isTutorialTarget = OnboardingService.targetActor(for: player?.onboardingStep ?? 3) == actorKey
        let statusText: String = {
            if !unlocked { return gathererLockedText(step: player?.onboardingStep ?? 0) }
            if completedTask != nil { return completedStatus }
            if let activeTask {
                return "\(taskName ?? "製作中") · \(TaskCountdown.remaining(for: activeTask, relativeTo: appState.tick))"
            }
            if isTutorialTarget { return "下一步，點擊開始" }
            return idleStatus
        }()

        Button {
            guard unlocked else { return }
            if completedTask != nil {
                appState.presentCompletedTasksIfNeeded()
            } else if activeTask == nil {
                onOpen()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: imageName,
                        height: 96,
                        cornerRadius: 10,
                        padding: 5,
                        imageOpacity: unlocked ? 1.0 : 0.45,
                        fillWidth: true
                    )

                    miniStatusBadge(
                        title: completedTask != nil ? "完成" : activeTask != nil ? "工作中" : isTutorialTarget ? "下一步" : unlocked ? "閒置" : "鎖定",
                        color: completedTask != nil ? .orange : activeTask != nil ? color : isTutorialTarget ? .orange : unlocked ? .secondary : .gray
                    )
                    .padding(6)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 {
                        TierBadgeView(tier: tier, color: color)
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(player?.npcDisplayName(for: actorKey) ?? fallbackName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(minHeight: 32, alignment: .topLeading)

                    Text(roleName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(completedTask != nil ? .semibold : .regular)
                        .foregroundStyle(completedTask != nil ? Color.orange : activeTask != nil ? color : .secondary)
                        .lineLimit(2)
                        .frame(minHeight: 30, alignment: .topLeading)

                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: color, height: 4)
                    } else {
                        SmoothLinearProgressBar(
                            value: completedTask != nil ? 1.0 : 0.0,
                            tint: completedTask != nil ? .orange : color.opacity(0.25),
                            height: 4
                        )
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 212, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke((completedTask != nil || isTutorialTarget ? Color.orange : Color.clear).opacity(0.55), lineWidth: 1)
            }
            .opacity(unlocked ? 1.0 : 0.62)
        }
        .buttonStyle(.plain)
    }

    private func productionActiveTask(actorKey: String) -> TaskModel? {
        tasks.first { $0.actorKey == actorKey && $0.status == .inProgress }
    }

    private func productionCompletedTask(actorKey: String) -> TaskModel? {
        tasks.first { $0.actorKey == actorKey && $0.status == .completed }
    }

    private func productionTaskName(_ task: TaskModel) -> String {
        switch task.kind {
        case .craft:
            return CraftRecipeDef.find(key: task.definitionKey)?.name ?? "裝備製作"
        case .cuisine:
            if let cuisine = CuisineDef.find(task.definitionKey) {
                return "\(cuisine.icon) \(cuisine.name)"
            }
            return "料理烹飪"
        case .alchemy:
            return PotionDef.find(task.definitionKey)?.name ?? "藥水煉製"
        case .farming:
            return "農作"
        case .gather:
            return GatherLocationDef.find(key: task.definitionKey)?.name ?? "採集"
        case .dungeon:
            return "探索"
        }
    }

    // MARK: - NPC Card: 採集者

    @ViewBuilder
    private func npcGathererCard(def: GathererNpcDef, player: PlayerStateModel?) -> some View {
        let step       = player?.onboardingStep ?? 3
        let unlocked   = isNpcUnlocked(actorKey: def.actorKey, step: step)
        let activeTask = viewModel.gatherTaskForActor(def.actorKey, from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: def.actorKey) ?? 0
        let caption: String = {
            if !unlocked { return "完成引導後解鎖" }
            guard let task = activeTask,
                  let locDef = GatherLocationDef.find(key: task.definitionKey) else { return "閒置中" }
            return "採集中：\(locDef.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if unlocked { selectedGathererDef = def } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_\(def.actorKey)",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: def.actorKey) ?? def.name)
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(unlocked && isBusy ? Color.green : .secondary)
                        .lineLimit(2)
                    if let activeTask, unlocked && isBusy {
                        SmoothLinearProgressBar(task: activeTask, tint: .green, height: 4)
                    }
                }

                Spacer()

                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundStyle(.tertiary)
                } else if isBusy {
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
            .opacity(unlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 農夫

    @ViewBuilder
    private func npcFarmerCard() -> some View {
        let step     = players.first?.onboardingStep ?? 3
        let unlocked = isNpcUnlocked(actorKey: "farmer", step: step)
        let tier     = players.first?.gatherer5Tier ?? 0
        let plots    = min(tier + 1, AppConstants.FarmerPlot.maxPlots)

        Button { if unlocked { showFarmerDetailSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_farmer",
                        width: 80,
                        height: 80
                    )
                    npcStatusBadge(isBusy: false)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(players.first?.npcDisplayName(for: "farmer") ?? "農夫")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(unlocked ? "農田 \(plots) 塊 · 點擊管理" : "完成引導後解鎖")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(unlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 鑄造師

    @ViewBuilder
    private func npcBlacksmithCard(player: PlayerStateModel?) -> some View {
        let step       = player?.onboardingStep ?? 3
        let unlocked   = isNpcUnlocked(actorKey: AppConstants.Actor.blacksmith, step: step)
        let activeTask = viewModel.craftTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.blacksmith) ?? 0
        let caption: String = {
            if !unlocked { return "完成引導後解鎖" }
            guard let task = activeTask,
                  let def = CraftRecipeDef.find(key: task.definitionKey) else { return "閒置中，點擊委派" }
            return "鑄造中：\(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy && unlocked { showCraftSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_blacksmith",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.blacksmith) ?? "鑄造師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(unlocked && isBusy ? Color.orange : .secondary)
                        .lineLimit(2)
                    if let activeTask, unlocked && isBusy {
                        SmoothLinearProgressBar(task: activeTask, tint: .orange, height: 4)
                    }
                }

                Spacer()

                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundStyle(.tertiary)
                } else if isBusy {
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
            .opacity(unlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 廚師

    @ViewBuilder
    private func npcChefCard(player: PlayerStateModel?) -> some View {
        let step       = player?.onboardingStep ?? 3
        let unlocked   = isNpcUnlocked(actorKey: AppConstants.Actor.chef, step: step)
        let activeTask = viewModel.cuisineTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.chef) ?? 0
        let caption: String = {
            if !unlocked { return "完成引導後解鎖" }
            guard let task = activeTask,
                  let def = CuisineDef.find(task.definitionKey) else { return "閒置中，點擊委派" }
            return "烹飪中：\(def.icon) \(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy && unlocked { showCuisineSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_chef",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.chef) ?? "廚師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(unlocked && isBusy ? Color.purple : .secondary)
                        .lineLimit(2)
                    if let activeTask, unlocked && isBusy {
                        SmoothLinearProgressBar(task: activeTask, tint: .purple, height: 4)
                    }
                }

                Spacer()

                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundStyle(.tertiary)
                } else if isBusy {
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
            .opacity(unlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 製藥師

    @ViewBuilder
    private func npcPharmacistCard(player: PlayerStateModel?) -> some View {
        let step       = player?.onboardingStep ?? 3
        let unlocked   = isNpcUnlocked(actorKey: AppConstants.Actor.pharmacist, step: step)
        let activeTask = viewModel.pharmacistTask(from: tasks)
        let isBusy     = activeTask != nil
        let tier       = player?.tier(for: AppConstants.Actor.pharmacist) ?? 0
        let caption: String = {
            if !unlocked { return "完成引導後解鎖" }
            guard let task = activeTask,
                  let def = PotionDef.find(task.definitionKey) else { return "閒置中，點擊選擇" }
            return "製藥中：\(def.name)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy && unlocked { showPharmacySheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_pharmacist",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }
                .overlay(alignment: .topLeading) {
                    if tier > 0 { TierBadgeView(tier: tier).padding(4) }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.pharmacist) ?? "製藥師")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(unlocked && isBusy ? Color.teal : .secondary)
                        .lineLimit(2)
                    if let activeTask, unlocked && isBusy {
                        SmoothLinearProgressBar(task: activeTask, tint: .teal, height: 4)
                    }
                }

                Spacer()

                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundStyle(.tertiary)
                } else if isBusy {
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
            .opacity(unlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 鍛造學徒（V10-1 T12）

    @ViewBuilder
    private func npcWeaponsmithCard(player: PlayerStateModel?) -> some View {
        let activeTask = tasks.first { $0.actorKey == AppConstants.Actor.weaponsmith && $0.status == .inProgress }
        let isBusy     = activeTask != nil
        let caption: String = {
            guard let task = activeTask else { return "閒置中，點擊委派" }
            let recipeName = CraftRecipeDef.find(key: task.definitionKey)?.name ?? "副手"
            return "鑄造中：\(recipeName)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy { showOffhandSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_weaponsmith",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.weaponsmith) ?? "鍛造學徒")
                        .font(.subheadline).fontWeight(.medium).lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.orange : .secondary)
                        .lineLimit(2)
                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: .orange, height: 4)
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
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 飾品師（V10-1 T13）

    @ViewBuilder
    private func npcJewelerCard(player: PlayerStateModel?) -> some View {
        let activeTask = tasks.first { $0.actorKey == AppConstants.Actor.jeweler && $0.status == .inProgress }
        let isBusy     = activeTask != nil
        let caption: String = {
            guard let task = activeTask else { return "閒置中，點擊委派" }
            let recipeName = CraftRecipeDef.find(key: task.definitionKey)?.name ?? "飾品"
            return "鑄造中：\(recipeName)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy { showAccessorySheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_jeweler",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.jeweler) ?? "飾品師")
                        .font(.subheadline).fontWeight(.medium).lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.purple : .secondary)
                        .lineLimit(2)
                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: .purple, height: 4)
                    }
                }

                Spacer()

                if isBusy {
                    Text("鑄造中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(Color.purple)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - NPC Card: 裁縫師（V10-1 T14）

    @ViewBuilder
    private func npcTailorCard(player: PlayerStateModel?) -> some View {
        let activeTask = tasks.first { $0.actorKey == AppConstants.Actor.tailor && $0.status == .inProgress }
        let isBusy     = activeTask != nil
        let caption: String = {
            guard let task = activeTask else { return "閒置中，點擊委派" }
            let recipeName = CraftRecipeDef.find(key: task.definitionKey)?.name ?? "防具"
            return "製作中：\(recipeName)\n\(TaskCountdown.remaining(for: task, relativeTo: appState.tick))"
        }()

        Button { if !isBusy { showTailorSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_tailor",
                        width: 80,
                        height: 80,
                        imageOpacity: isBusy ? 0.85 : 1.0
                    )
                    npcStatusBadge(isBusy: isBusy)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(player?.npcDisplayName(for: AppConstants.Actor.tailor) ?? "裁縫師")
                        .font(.subheadline).fontWeight(.medium).lineLimit(1)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(isBusy ? Color.teal : .secondary)
                        .lineLimit(2)
                    if let activeTask {
                        SmoothLinearProgressBar(task: activeTask, tint: .teal, height: 4)
                    }
                }

                Spacer()

                if isBusy {
                    Text("製作中")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.teal.opacity(0.12))
                        .foregroundStyle(Color.teal)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
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
        let step     = players.first?.onboardingStep ?? 3
        let unlocked = isNpcUnlocked(actorKey: "merchant", step: step)
        let isTutorialTarget = OnboardingService.targetActor(for: step) == "merchant"

        Button { if unlocked { showMerchantSheet = true } } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    NPCPortraitView(
                        imageName: "npc_merchant",
                        width: 80,
                        height: 80
                    )
                    if isTutorialTarget {
                        miniStatusBadge(title: "下一步", color: .orange)
                    } else {
                        npcStatusBadge(isBusy: false)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(players.first?.npcDisplayName(for: "merchant") ?? "商人")
                        .font(.subheadline).fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text(isTutorialTarget ? "下一步：購買小麥種子" : unlocked ? "點擊開啟商店" : "完成引導後解鎖")
                        .font(.caption2)
                        .foregroundStyle(isTutorialTarget ? Color.orange : .secondary)
                }

                Spacer()

                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isTutorialTarget ? Color.orange.opacity(0.55) : Color.clear, lineWidth: 1)
            }
            .opacity(unlocked ? 1.0 : 0.5)
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
        MaterialType.allCases.forEach { inv.add(amount, of: $0) }
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
        player.weaponsmithTier = 0
        player.tailorTier      = 0
        player.jewelerTier     = 0
        player.gatherer1SkillPoints = 0;  player.gatherer1SkillsRaw = ""
        player.gatherer2SkillPoints = 0;  player.gatherer2SkillsRaw = ""
        player.gatherer3SkillPoints = 0;  player.gatherer3SkillsRaw = ""
        player.gatherer4SkillPoints = 0;  player.gatherer4SkillsRaw = ""
        player.farmerSkillPoints = 0;      player.farmerSkillsRaw = ""
        player.blacksmithSkillPoints = 0;  player.blacksmithSkillsRaw = ""
        player.chefSkillPoints = 0;        player.chefSkillsRaw = ""
        player.pharmacistSkillPoints = 0;  player.pharmacistSkillsRaw = ""
        player.weaponsmithSkillPoints = 0; player.weaponsmithSkillsRaw = ""
        player.tailorSkillPoints = 0;      player.tailorSkillsRaw = ""
        player.jewelerSkillPoints = 0;     player.jewelerSkillsRaw = ""
        try? context.save()
    }

    private func devResetFirstBoosts() {
        guard let player = players.first else { return }
        player.onboardingStep = 0
        // 清除所有裝備，模擬教程前的無武器狀態
        let allEquip = (try? context.fetch(FetchDescriptor<EquipmentModel>())) ?? []
        allEquip.forEach { context.delete($0) }
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
        player.weaponsmithTier = 3
        player.tailorTier      = 3
        player.jewelerTier     = 3
        player.chefTier        = 3
        player.pharmacistTier  = 3
        player.gatherer5Tier   = 3   // 農夫 tier

        // ── 生產者技能（直接注入 raw，全部 Lv2）────────────────────
        // bs_gold Lv2 → 鑄造金幣 -20%；bs_mastery Lv2 → 精良+以上屬性 ×1.10
        player.blacksmithSkillPoints = 0
        player.blacksmithSkillsRaw   = "bs_gold,bs_gold,bs_mastery,bs_mastery"
        player.weaponsmithSkillPoints = 0
        player.weaponsmithSkillsRaw   = "ws_gold,ws_gold,ws_mastery,ws_mastery"
        player.tailorSkillPoints = 0
        player.tailorSkillsRaw   = "ta_gold,ta_gold,ta_mastery,ta_mastery"
        player.jewelerSkillPoints = 0
        player.jewelerSkillsRaw   = "jw_gold,jw_gold,jw_mastery,jw_mastery"

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
    }(), selectedTab: .constant(0))
    .modelContainer(for: [
        PlayerStateModel.self, MaterialInventoryModel.self,
        EquipmentModel.self, TaskModel.self,
    ], inMemory: true)
}
