// ContentView.swift
// App 主容器 — Phase 9
//
// 責任（嚴格限縮）：
//   1. 在 View 樹內初始化 AppState（此處可取得 @Environment(\.modelContext)）
//   2. 監聽 scenePhase：
//      - → .active   ：啟動前台 Timer + 掃描結算
//      - → .inactive / .background：停止前台 Timer
//   3. 持有正式 TabView（Base / Adventure / Character）
//   4. 綁定 AppState.shouldShowSettlement → 顯示 SettlementSheet
//
// ContentView 本身不做任何遊戲邏輯或資料讀取，只負責組裝與導覽。

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase)   private var scenePhase

    @State private var appState:     AppState?
    @State private var selectedTab:  Int = 0
    @Query private var players:      [PlayerStateModel]
    @Query private var tasks:        [TaskModel]

    private var hasDungeonTask: Bool {
        tasks.contains { $0.kind == .dungeon && $0.status == .inProgress }
    }

    private var hasGatherTask: Bool {
        tasks.contains { $0.kind == .gather && $0.status == .inProgress }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let player = players.first {
                if needsNewPlayerFlow(player) {
                    // V10-1：新玩家完整流程（敘事 → 命名 → 職業選擇）
                    // 在 ContentView 層決定，直接傳入已載入的 player 避免時序競態
                    NewPlayerFlowView(player: player)
                } else if let appState {
                    mainTabView(appState: appState)
                        .sheet(isPresented: Binding(
                            get: { appState.shouldShowSettlement },
                            set: { show in if !show { appState.claimAllCompleted() } }
                        )) {
                            SettlementSheet(appState: appState)
                        }
                } else {
                    Color.black.ignoresSafeArea()  // AppState 初始化前短暫過渡
                }
            } else {
                Color.black.ignoresSafeArea()  // 資料尚未 seed（首次啟動 task 尚未執行）
            }
        }
        .onAppear {
            guard appState == nil else { return }
            let state = AppState(context: context)
            appState = state
            state.scanAndSettle()
            state.checkForPendingBattles()
            state.startForegroundTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                appState?.scanAndSettle()
                appState?.checkForPendingBattles()
                appState?.startForegroundTimer()
            case .inactive, .background:
                appState?.stopForegroundTimer()
            @unknown default:
                break
            }
        }
    }

    private func needsNewPlayerFlow(_ player: PlayerStateModel) -> Bool {
        !player.hasSeenIntro || player.classKey.isEmpty
    }

    // MARK: - Main Tab View

    @ViewBuilder
    private func mainTabView(appState: AppState) -> some View {
        let adventureUnlocked = (players.first?.onboardingStep ?? 8) >= 4
        TabView(selection: $selectedTab) {
            BaseView(appState: appState, selectedTab: $selectedTab)
                .tabItem {
                    Label {
                        Text("基地")
                    } icon: {
                        Image(systemName: "house.fill")
                            .gatheringSymbolEffect(isActive: hasGatherTask)
                    }
                }
                .tag(0)

            if adventureUnlocked {
                AdventureView(appState: appState)
                    .tabItem {
                        Label {
                            Text("冒險")
                        } icon: {
                            Image(systemName: "map.fill")
                                .symbolEffect(.pulse, isActive: hasDungeonTask)
                        }
                    }
                    .tag(1)
            }

            CharacterView(appState: appState, selectedTab: $selectedTab)
                .tabItem {
                    Label("角色", systemImage: "person.fill")
                }
                .badge(players.first.map { max(0, $0.availableStatPoints + $0.availableTalentPoints + $0.availableSkillPoints) } ?? 0)
                .tag(2)
        }
        // ── 輕量 Toast 覆蓋（非阻擋，結算 Sheet 開啟時也可見）─────
        .overlay(alignment: .top) {
            if let msg = appState.toastMessage {
                ToastBanner(message: msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: appState.toastMessage)
                    .padding(.top, 8)
            }
        }
        // V6-3 T02：即時地下城戰鬥 Sheet（從 SettlementSheet 內「開始戰鬥」按鈕觸發）
        .sheet(item: Binding(
            get: { appState.pendingDungeonBattleTask },
            set: { task in if task == nil { appState.clearDungeonBattle() } }
        )) { task in
            DungeonBattleSheet(task: task, appState: appState)
        }
    }
}

// MARK: - ToastBanner（輕量任務完成提示，非阻擋）

private struct ToastBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            PlayerStateModel.self,
            MaterialInventoryModel.self,
            EquipmentModel.self,
            TaskModel.self,
        ], inMemory: true)
}
