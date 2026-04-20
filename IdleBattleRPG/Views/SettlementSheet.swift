// SettlementSheet.swift
// 結算 Sheet — V6-3 T02 重構
//
// 顯示內容：
//   - battlePending 任務行（每筆一個「⚔️ 開始戰鬥」按鈕）
//   - 一般獎勵明細行（非 battlePending 任務的 gold / 素材 / 新裝備）
//   - V2-1 首通解鎖行
//   - 「收下」按鈕 → 呼叫 AppState.claimAllCompleted()（入帳非 battlePending 任務 + 關閉 Sheet）
//
// 架構守則：
//   - View 只呼叫 appState 公開方法，不直接碰任何 Service
//   - battlePending 任務的獎勵不納入摘要（由 DungeonBattleSheet 填入後再收下）

import SwiftUI
import SwiftData

struct SettlementSheet: View {

    let appState: AppState

    @Query private var allTasks: [TaskModel]
    @State private var viewModel = SettlementViewModel()

    // MARK: - 計算屬性

    private var completedTasks: [TaskModel] {
        allTasks.filter { $0.status == .completed }
    }

    /// V6-3 T02：battlePending == true 的地下城任務（待即時戰鬥）
    private var battlePendingTasks: [TaskModel] {
        completedTasks.filter { $0.battlePending }
    }

    /// 可直接收下的任務（排除 battlePending）
    private var claimableTasks: [TaskModel] {
        completedTasks.filter { !$0.battlePending }
    }

    private var summary: SettlementSummary {
        viewModel.makeSummary(from: appState, completedTasks: claimableTasks)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── 標題區 ───────────────────────────────────────────────
                VStack(spacing: 12) {
                    if battlePendingTasks.isEmpty {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.orange)
                    }

                    Text("任務完成")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(headerSubtitle)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 20)

                Divider()

                // ── battlePending 任務（需即時戰鬥）────────────────────
                if !battlePendingTasks.isEmpty {
                    battlePendingSection
                    if !claimableTasks.isEmpty {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }
                }

                // ── 一般獎勵明細 ─────────────────────────────────────────
                if !claimableTasks.isEmpty {
                    rewardDetailSection
                }

                Spacer(minLength: 32)

                // ── 收下按鈕 ─────────────────────────────────────────────
                Button {
                    appState.claimAllCompleted()
                } label: {
                    Text(claimButtonLabel)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(claimableTasks.isEmpty ? Color.secondary : Color.accentColor)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 標題副文字

    private var headerSubtitle: String {
        let n = completedTasks.count
        return n == 1 ? "1 筆任務已完成" : "共 \(n) 筆任務已完成"
    }

    // MARK: - 收下按鈕文字

    private var claimButtonLabel: String {
        if claimableTasks.isEmpty {
            return battlePendingTasks.isEmpty ? "收下" : "稍後再戰"
        }
        return "收下"
    }

    // MARK: - battlePending Section

    @ViewBuilder
    private var battlePendingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("待發起戰鬥")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(battlePendingTasks) { task in
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dungeonFloorName(for: task))
                            .fontWeight(.semibold)
                        Text("探索完成，待即時戰鬥")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        appState.startDungeonBattle(task: task)
                    } label: {
                        Label("開始戰鬥", systemImage: "bolt.fill")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 獎勵明細 Section

    @ViewBuilder
    private var rewardDetailSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("獎勵明細")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if summary.hasRewards {
                ForEach(summary.rewardRows) { row in
                    rewardRowView(row)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                }
            } else {
                Text("（本次無額外獎勵）")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }

            // V2-1 首通解鎖提示
            if summary.hasUnlocks {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)

                ForEach(summary.unlockRows) { row in
                    unlockRowView(row)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func dungeonFloorName(for task: TaskModel) -> String {
        if let floor = DungeonRegionDef.all
            .flatMap({ $0.floors })
            .first(where: { $0.key == task.definitionKey }) {
            return floor.name
        }
        return task.definitionKey
    }

    // MARK: - Row Renderers

    @ViewBuilder
    private func rewardRowView(_ row: SettlementRow) -> some View {
        switch row.kind {
        case .gold(let amt):
            HStack {
                Image(systemName: "coins").frame(width: 18, height: 18).foregroundStyle(.yellow)
                Text("金幣 +\(amt)").font(.body)
                Spacer()
            }
        case .exp(let amt):
            HStack {
                Image(systemName: "sparkles").frame(width: 18, height: 18).foregroundStyle(.purple)
                Text("EXP +\(amt)").font(.body)
                Spacer()
            }
        case .material(let mat, let amt):
            HStack {
                Text("\(mat.icon) \(mat.displayName) +\(amt)").font(.body)
                Spacer()
            }
        case .equipment(let name, let stats, let isRolled):
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRolled ? Color.yellow.opacity(0.15) : Color.accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    if isRolled {
                        Text("✦").font(.body)
                    } else {
                        Image(systemName: "figure.fencing")
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(isRolled ? Color.rarityRefined : Color.primary)
                        Text("新裝備")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    if !stats.isEmpty {
                        Text(stats)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 2)
        case .battle(let won, let lost):
            HStack {
                Image(systemName: "figure.fencing").frame(width: 18, height: 18).foregroundStyle(.secondary)
                Text("戰鬥 \(won) 勝 \(lost) 敗").font(.body)
                Spacer()
            }
        case .firstClear, .regionUnlock:
            EmptyView()
        }
    }

    @ViewBuilder
    private func unlockRowView(_ row: SettlementRow) -> some View {
        switch row.kind {
        case .firstClear(let floorName):
            HStack {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(Color.accentColor)
                Text("解鎖配方：\(floorName)")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
        case .regionUnlock(let regionName):
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.green)
                Text("新區域開放：\(regionName)")
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                Spacer()
            }
        default:
            EmptyView()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let state = AppState(context: container.mainContext)

    SettlementSheet(appState: state)
}
