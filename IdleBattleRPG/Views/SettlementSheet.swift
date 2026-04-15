// SettlementSheet.swift
// 結算 Sheet — Phase 5
//
// 顯示內容：
//   - 完成筆數標題
//   - 獎勵明細行（金幣 / 素材 / 新裝備），由 SettlementViewModel 從 result* 欄位轉換
//   - V2-1 首通解鎖行（🔓 / 🗺），有首通時額外顯示
//   - 「收下」按鈕 → 呼叫 AppState.claimAllCompleted()（入帳 + 刪除任務 + 關閉 Sheet）
//
// 架構守則：
//   - View 只呼叫 appState.claimAllCompleted()，不直接碰任何 Service
//   - 獎勵行由 SettlementViewModel.makeSummary() 計算，View 只負責渲染

import SwiftUI
import SwiftData
import PhosphorSwift

struct SettlementSheet: View {

    let appState: AppState

    @Query private var allTasks: [TaskModel]
    @State private var viewModel = SettlementViewModel()

    // MARK: - 計算屬性

    /// Sheet 開啟期間，completed 任務即為「待收下」的任務
    private var completedTasks: [TaskModel] {
        allTasks.filter { $0.status == .completed }
    }

    private var summary: SettlementSummary {
        viewModel.makeSummary(from: appState, completedTasks: completedTasks)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── 標題區 ───────────────────────────────────────────────
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
                    .padding(.top, 32)

                Text(summary.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(summary.displayBody)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            Divider()

            // ── 獎勵明細 ─────────────────────────────────────────────
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

                // ── V2-1 首通解鎖提示 ─────────────────────────────
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

            Spacer()

            // ── 收下按鈕 ─────────────────────────────────────────────
            Button {
                appState.claimAllCompleted()
            } label: {
                Text("收下")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Row Renderers

    @ViewBuilder
    private func rewardRowView(_ row: SettlementRow) -> some View {
        switch row.kind {
        case .gold(let amt):
            HStack {
                Ph.coins.fill.frame(width: 18, height: 18).foregroundStyle(.yellow)
                Text("金幣 +\(amt)").font(.body)
                Spacer()
            }
        case .exp(let amt):
            HStack {
                Ph.sparkle.fill.frame(width: 18, height: 18).foregroundStyle(.purple)
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
                // 左側圖示（裝備專屬背景）
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRolled ? Color.yellow.opacity(0.15) : Color.accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    if isRolled {
                        Text("✦").font(.body)
                    } else {
                        Ph.sword.fill
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
                Ph.sword.fill.frame(width: 18, height: 18).foregroundStyle(.secondary)
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
