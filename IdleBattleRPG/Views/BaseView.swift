// BaseView.swift
// 基地 Tab — Phase 9
//
// 顯示內容：
//   - 玩家金幣、等級（收下後即時更新）
//   - 素材庫存（收下後即時更新）
//   - NPC 列表：採集者 ×2（點閒置 → GatherSheet）、鑄造師（點閒置 → CraftSheet）
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

    // Sheet 狀態
    @State private var showGatherSheet1  = false
    @State private var showGatherSheet2  = false
    @State private var showCraftSheet    = false
    @State private var showMerchantSheet = false

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
                        Text("⚠️ 尚無玩家資料").foregroundStyle(.red)
                    }
                }

                // ── 素材庫存 ─────────────────────────────────────────
                Section("素材庫存") {
                    if let inv = inventories.first {
                        ForEach(MaterialType.allCases, id: \.self) { mat in
                            let amount = inv.amount(of: mat)
                            HStack {
                                Text("\(mat.icon) \(mat.displayName)")
                                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                                Spacer()
                                Text("\(amount)")
                                    .fontWeight(amount > 0 ? .semibold : .regular)
                                    .foregroundStyle(amount > 0 ? .primary : .secondary)
                                    .monospacedDigit()
                            }
                        }
                    } else {
                        Text("⚠️ 尚無素材資料").foregroundStyle(.red)
                    }
                }

                // ── NPC 列表 ─────────────────────────────────────────
                Section("NPC") {
                    npcGathererRow(
                        actorKey: AppConstants.Actor.gatherer1,
                        name: "採集者 1",
                        onTap: { showGatherSheet1 = true }
                    )
                    npcGathererRow(
                        actorKey: AppConstants.Actor.gatherer2,
                        name: "採集者 2",
                        onTap: { showGatherSheet2 = true }
                    )
                    npcBlacksmithRow()
                    npcMerchantRow()
                }

                // ── 開發模式（Debug build 限定）────────────────────────
                #if DEBUG
                Section {
                    Button {
                        addShortTestTask()
                    } label: {
                        Label("新增短時採集任務（5 秒）", systemImage: "plus.circle")
                    }
                    Button {
                        appState.scanAndSettle()
                    } label: {
                        Label("手動觸發結算掃描", systemImage: "arrow.clockwise")
                    }
                    Button {
                        devUnequipAll()
                    } label: {
                        Label("卸除所有裝備（測試低戰力）", systemImage: "shield.slash")
                    }
                    Button {
                        devSetMaxLevel()
                    } label: {
                        Label("升至最高等級 Lv.\(AppConstants.Game.heroMaxLevel)", systemImage: "arrow.up.forward.circle")
                    }
                    if appState.lastSettledCount > 0 {
                        HStack {
                            Text("最近結算").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(appState.lastSettledCount) 筆").fontWeight(.medium)
                        }
                    }
                    Button("DEBUG: 印出 Progression 狀態") {
                            let svc = appState.progressionService
                            print("wildland 解鎖：", svc.isRegionUnlocked("wildland"))
                            print("mine 解鎖：", svc.isRegionUnlocked("abandoned_mine"))
                            print("ruins 解鎖：", svc.isRegionUnlocked("ancient_ruins"))
                            print("wildland floor1 可挑：", svc.isFloorUnlocked(regionKey: "wildland", floorIndex: 1))
                            print("wildland floor2 可挑：", svc.isFloorUnlocked(regionKey: "wildland", floorIndex: 2))
                            print("wildland 已完成：", svc.isRegionCompleted("wildland"))
                        }

                        Button("DEBUG: 標記 wildland floor1 首通") {
                            appState.progressionService.markFloorCleared(regionKey: "wildland", floorIndex: 1)
                        }

                        Button("DEBUG: 標記 wildland Boss 首通") {
                            appState.progressionService.markFloorCleared(regionKey: "wildland", floorIndex: 4)
                        }
                } header: {
                    Text("⚙️ 開發模式（Debug Only）")
                } footer: {
                    Text("此區塊僅在 Debug build 顯示，Release / TestFlight 不可見。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .navigationTitle("基地")
            .sheet(isPresented: $showGatherSheet1) {
                GatherSheet(
                    actorKey: AppConstants.Actor.gatherer1,
                    actorName: "採集者 1",
                    viewModel: viewModel,
                    isPresented: $showGatherSheet1
                )
            }
            .sheet(isPresented: $showGatherSheet2) {
                GatherSheet(
                    actorKey: AppConstants.Actor.gatherer2,
                    actorName: "採集者 2",
                    viewModel: viewModel,
                    isPresented: $showGatherSheet2
                )
            }
            .sheet(isPresented: $showCraftSheet) {
                CraftSheet(
                    viewModel: viewModel,
                    player: players.first,
                    inventory: inventories.first,
                    isPresented: $showCraftSheet
                )
            }
            .sheet(isPresented: $showMerchantSheet) {
                MerchantSheet(isPresented: $showMerchantSheet)
            }
        }
    }

    // MARK: - NPC Row: 採集者

    @ViewBuilder
    private func npcGathererRow(actorKey: String, name: String, onTap: @escaping () -> Void) -> some View {
        let activeTask = viewModel.gatherTaskForActor(actorKey, from: tasks)
        let isBusy = activeTask != nil

        Button(action: { if !isBusy { onTap() } }) {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.green.opacity(isBusy ? 0.4 : 1.0))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let task = activeTask, let def = GatherLocationDef.find(key: task.definitionKey) {
                        Text("採集中：\(def.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("閒置中，點擊派遣")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

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
        .buttonStyle(NPCRowButtonStyle(enabled: !isBusy))
    }

    // MARK: - NPC Row: 鑄造師

    @ViewBuilder
    private func npcBlacksmithRow() -> some View {
        let activeTask = viewModel.craftTask(from: tasks)
        let isBusy = activeTask != nil

        Button(action: { if !isBusy { showCraftSheet = true } }) {
            HStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(Color.orange.opacity(isBusy ? 0.4 : 1.0))
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
                    } else {
                        Text("閒置中，點擊委派")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

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
        .buttonStyle(NPCRowButtonStyle(enabled: !isBusy))
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
        .buttonStyle(NPCRowButtonStyle(enabled: true))
    }

    // MARK: - Private Helpers

    #if DEBUG
    /// 插入 5 秒後到期的採集任務（開發模式驗證用，Debug build 限定）
    private func addShortTestTask() {
        let now = Date.now
        let task = TaskModel(
            kind:          .gather,
            actorKey:      AppConstants.Actor.gatherer1,
            definitionKey: GatherLocationDef.all[0].key,
            startedAt:     now,
            endsAt:        now.addingTimeInterval(5)
        )
        context.insert(task)
        try? context.save()
    }

    /// 卸除所有裝備，讓戰力降至基礎值（測試低勝率用）
    private func devUnequipAll() {
        let all = (try? context.fetch(FetchDescriptor<EquipmentModel>())) ?? []
        all.forEach { $0.isEquipped = false }
        try? context.save()
    }

    /// 直接升至最高等級，屬性點清零（測試 Lv.10 上限用）
    private func devSetMaxLevel() {
        guard let player = players.first else { return }
        player.heroLevel          = AppConstants.Game.heroMaxLevel
        player.availableStatPoints = 0
        try? context.save()
    }
    
    #endif
}

// MARK: - Button Style

/// NPC row 按壓回饋：整行可點（contentShape 已設）+ 按壓時輕微淡出
/// enabled = false（忙碌中）時按壓無視覺變化，強調不可互動
private struct NPCRowButtonStyle: ButtonStyle {
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(enabled && configuration.isPressed ? 0.55 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
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
