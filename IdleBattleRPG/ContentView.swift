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

    @State private var appState: AppState?

    // MARK: - Body

    var body: some View {
        Group {
            if let appState {
                mainTabView(appState: appState)
                    // 結算 Sheet：由 AppState.shouldShowSettlement 驅動
                    .sheet(isPresented: Binding(
                        get: { appState.shouldShowSettlement },
                        set: { show in if !show { appState.claimAllCompleted() } }
                    )) {
                        SettlementSheet(appState: appState)
                    }
            } else {
                // AppState 初始化前的短暫過渡（通常不可見）
                ProgressView()
            }
        }
        .onAppear {
            guard appState == nil else { return }
            let state = AppState(context: context)
            appState = state
            // 啟動後首次掃描，補跑離線期間到期的任務
            state.scanAndSettle()
            state.startForegroundTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // App 回到前景：先補跑離線到期任務，再啟動 Timer
                appState?.scanAndSettle()
                appState?.startForegroundTimer()
            case .inactive, .background:
                // App 進入背景：停止 Timer，節省資源
                appState?.stopForegroundTimer()
            @unknown default:
                break
            }
        }
    }

    // MARK: - Main Tab View

    @ViewBuilder
    private func mainTabView(appState: AppState) -> some View {
        TabView {
            BaseView(appState: appState)
                .tabItem {
                    Label("基地", systemImage: "house.fill")
                }

            AdventureView(appState: appState)
                .tabItem {
                    Label("冒險", systemImage: "map.fill")
                }

            CharacterView()
                .tabItem {
                    Label("角色", systemImage: "person.fill")
                }
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
