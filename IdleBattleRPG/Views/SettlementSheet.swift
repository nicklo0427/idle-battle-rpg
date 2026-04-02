// SettlementSheet.swift
// 結算 Sheet — Phase 5
//
// 顯示內容：
//   - 完成筆數標題
//   - 獎勵明細行（金幣 / 素材 / 新裝備），由 SettlementViewModel 從 result* 欄位轉換
//   - 「收下」按鈕 → 呼叫 AppState.claimAllCompleted()（入帳 + 刪除任務 + 關閉 Sheet）
//
// 架構守則：
//   - View 只呼叫 appState.claimAllCompleted()，不直接碰任何 Service
//   - 獎勵行由 SettlementViewModel.makeSummary() 計算，View 只負責渲染

import SwiftUI
import SwiftData

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
                    ForEach(summary.rewardLines, id: \.self) { line in
                        HStack {
                            Text(line)
                                .font(.body)
                            Spacer()
                        }
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
