// FarmerPlotSheet.swift
// 農田種植 Sheet（V7-4）
//
// 觸發：點擊閒置農田格子
// 功能：選擇種子 → 選擇時長 → 種下（扣除種子，建立 farming 任務）
//
// 設計：
//   - 顯示各種種子持有量
//   - 種子不足時 disabled + 灰色
//   - 已選種子以 checkmark 標示
//   - segmented Picker 選時長
//   - 種下後自動關閉 Sheet

import SwiftUI
import SwiftData

struct FarmerPlotSheet: View {

    let viewModel: BaseViewModel
    let plotIndex: Int
    let player: PlayerStateModel?
    let inventory: MaterialInventoryModel?
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @State private var selectedSeed: MaterialType?
    @State private var selectedDuration: Int = 1800   // 預設 30 分鐘
    @State private var errorMessage: String?
    @State private var showError = false

    private var plotKey: String { AppConstants.FarmerPlot.key(for: plotIndex) }

    private let durationOptions: [(seconds: Int, label: String)] = [
        (1800,  "30 分"),
        (7200,  "2 小時"),
        (28800, "8 小時")
    ]

    private let seedTypes: [MaterialType] = [.wheatSeed, .vegetableSeed, .fruitSeed, .spiritGrainSeed]

    var body: some View {
        NavigationStack {
            List {

                // ── 種子庫存摘要 ───────────────────────────────────────
                Section("種子庫存") {
                    ForEach(seedTypes, id: \.self) { seed in
                        let count = inventory?.amount(of: seed) ?? 0
                        HStack {
                            Text("\(seed.icon) \(seed.displayName)")
                                .foregroundStyle(count > 0 ? Color.primary : Color.secondary)
                            Spacer()
                            Text("\(count)")
                                .monospacedDigit()
                                .foregroundStyle(count > 0 ? Color.primary : Color.secondary)
                        }
                    }
                }

                // ── 選擇種子 ───────────────────────────────────────────
                Section("選擇種子") {
                    ForEach(seedTypes, id: \.self) { seed in
                        let count = inventory?.amount(of: seed) ?? 0
                        Button {
                            selectedSeed = seed
                        } label: {
                            HStack(spacing: 12) {
                                Text(seed.icon)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(seed.displayName)
                                        .fontWeight(.medium)
                                        .foregroundStyle(count > 0 ? Color.primary : Color.secondary)
                                    Text("庫存：\(count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedSeed == seed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(count < 1)
                        .opacity(count < 1 ? 0.45 : 1.0)
                    }
                }

                // ── 種植時長 ───────────────────────────────────────────
                Section("種植時長") {
                    Picker("時長", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.seconds) { opt in
                            Text(opt.label).tag(opt.seconds)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                // ── 種下按鈕 ───────────────────────────────────────────
                Section {
                    Button {
                        plant()
                    } label: {
                        HStack {
                            Spacer()
                            if let seed = selectedSeed {
                                Label("種下 \(seed.displayName)", systemImage: "leaf.fill")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            } else {
                                Text("請先選擇種子")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .disabled(selectedSeed == nil)
                }
            }
            .navigationTitle("農田 \(plotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .alert("無法種植", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }

    // MARK: - Action

    private func plant() {
        guard let seed = selectedSeed else { return }
        let result = viewModel.startFarmTask(
            plotKey: plotKey,
            seedType: seed,
            durationSeconds: selectedDuration,
            context: context
        )
        switch result {
        case .success:
            isPresented = false
        case .failure(let error):
            errorMessage = error.errorDescription
            showError = true
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    FarmerPlotSheet(
        viewModel: BaseViewModel(),
        plotIndex: 0,
        player: nil,
        inventory: nil,
        isPresented: $isPresented
    )
    .modelContainer(container)
}
