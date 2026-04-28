// FarmerPlotSheet.swift
// 農田種植 Sheet（農場重構）
//
// 流程：
//   1. FarmerPlotSheet  — 只顯示種子清單，點選後進入第二層
//   2. FarmDurationSheet — 選擇時長（preset / 次數），確認後種下

import SwiftUI
import SwiftData

// MARK: - FarmerPlotSheet（主頁：種子選擇）

struct FarmerPlotSheet: View {

    let viewModel: BaseViewModel
    let plotIndex: Int
    let player:    PlayerStateModel?
    let inventory: MaterialInventoryModel?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var seedToPlant: SeedSelection?
    @State private var errorMessage: String?
    @State private var showError:    Bool = false

    private struct SeedSelection: Identifiable {
        let id    = UUID()
        let seed:  MaterialType
        let count: Int
    }

    private let seedTypes: [MaterialType] = [
        .wheatSeed, .vegetableSeed, .fruitSeed, .spiritGrainSeed
    ]
    private var plotKey: String { AppConstants.FarmerPlot.key(for: plotIndex) }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section("選擇種子") {
                    ForEach(seedTypes, id: \.self) { seed in
                        let count = inventory?.amount(of: seed) ?? 0
                        Button {
                            seedToPlant = SeedSelection(seed: seed, count: count)
                        } label: {
                            HStack(spacing: 12) {
                                Text(seed.icon).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(seed.displayName)
                                        .fontWeight(.medium)
                                        .foregroundStyle(count > 0 ? Color.primary : Color.secondary)
                                    Text("庫存：\(count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if count > 0 {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(count < 1)
                        .opacity(count < 1 ? 0.45 : 1.0)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("農田 \(plotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(item: $seedToPlant) { selection in
                FarmDurationSheet(
                    seed:      selection.seed,
                    seedCount: selection.count,
                    plotKey:   plotKey,
                    viewModel: viewModel,
                    onSuccess: { dismiss() }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("無法種植", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
    }
}

// MARK: - FarmDurationSheet（第二層：時長選擇 + 確認）

private struct FarmDurationSheet: View {

    let seed:      MaterialType
    let seedCount: Int
    let plotKey:   String
    let viewModel: BaseViewModel
    let onSuccess: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    private enum DurationMode: String, CaseIterable {
        case preset   = "時長"
        case runCount = "次數"
    }

    private static let shortestRound: Int = 300   // 5 分鐘 / 輪

    @State private var durationMode:   DurationMode = .preset
    @State private var selectedPreset: Int
    @State private var runCount:       Int = 1
    @State private var errorMessage:   String?
    @State private var showError:      Bool = false

    init(seed: MaterialType, seedCount: Int, plotKey: String,
         viewModel: BaseViewModel, onSuccess: @escaping () -> Void) {
        self.seed      = seed
        self.seedCount = seedCount
        self.plotKey   = plotKey
        self.viewModel = viewModel
        self.onSuccess = onSuccess
        _selectedPreset = State(initialValue: AppConstants.GatherDuration.short)
    }

    // MARK: - Computed

    private var maxRounds:   Int { max(1, seedCount) }
    private var maxDuration: Int { maxRounds * Self.shortestRound }

    private var effectiveDuration: Int {
        switch durationMode {
        case .preset:   return min(selectedPreset, maxDuration)
        case .runCount: return runCount * Self.shortestRound
        }
    }

    private var effectiveRounds: Int { max(1, effectiveDuration / Self.shortestRound) }
    private var canPlant: Bool { seedCount >= effectiveRounds }

    private var estimatedEnd: String {
        Date().addingTimeInterval(TimeInterval(effectiveDuration))
            .formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── 種子資訊標頭 ───────────────────────────────
                VStack(spacing: 6) {
                    Text(seed.icon).font(.system(size: 48))
                    Text(seed.displayName)
                        .font(.title3).fontWeight(.semibold)
                    Text("庫存：\(seedCount) 顆")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 14)

                Divider()

                // ── 時長選擇主體 ───────────────────────────────
                VStack(spacing: 14) {

                    Picker("", selection: $durationMode) {
                        ForEach(DurationMode.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    Group {
                        switch durationMode {
                        case .preset:   presetContent
                        case .runCount: runCountContent
                        }
                    }
                    .frame(minHeight: 100)

                    Divider()

                    // 消耗說明
                    HStack {
                        Text("消耗種子").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(effectiveRounds) 顆  預計 \(estimatedEnd) 完成")
                            .foregroundStyle(canPlant ? Color.secondary : Color.red)
                            .monospacedDigit()
                    }
                    .font(.subheadline)

                    // 種下按鈕
                    Button { plant() } label: {
                        Label("種下（\(effectiveRounds) 輪）", systemImage: "leaf.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .disabled(!canPlant)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Spacer(minLength: 0)
            }
            .navigationTitle("選擇種植時長")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("無法種植", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - 時長 Tab

    private var presetContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(AppConstants.GatherDuration.all, id: \.self) { dur in
                    FarmPresetChip(
                        dur:        dur,
                        roundDur:   Self.shortestRound,
                        isSelected: selectedPreset == dur,
                        isDisabled: dur > maxDuration,
                        onTap:      { selectedPreset = dur }
                    )
                }
            }
        }
    }

    // MARK: - 次數 Tab

    @ViewBuilder
    private var runCountContent: some View {
        VStack(spacing: 8) {
            HStack {
                Text("最多 \(maxRounds) 次（庫存上限）")
                    .font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Text("\(runCount) 次")
                    .font(.callout).fontWeight(.semibold).monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: runCount)
            }

            FarmInlineNumpad(
                value:  $runCount,
                minVal: 1,
                maxVal: maxRounds
            )
        }
    }

    // MARK: - Action

    private func plant() {
        let result = viewModel.startFarmTask(
            plotKey:         plotKey,
            seedType:        seed,
            durationSeconds: effectiveDuration,
            context:         context
        )
        switch result {
        case .success:
            dismiss()
            onSuccess()
        case .failure(let error):
            errorMessage = error.errorDescription
            showError    = true
        }
    }
}

// MARK: - FarmPresetChip

private struct FarmPresetChip: View {
    let dur:        Int
    let roundDur:   Int
    let isSelected: Bool
    let isDisabled: Bool
    let onTap:      () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Text(AppConstants.DungeonDuration.displayName(for: dur))
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
            Text("\(dur / roundDur) 輪")
                .font(.caption2)
                .foregroundStyle(
                    isSelected  ? Color.green :
                    isDisabled  ? Color.secondary.opacity(0.4) :
                                  Color.secondary.opacity(0.6)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            isSelected  ? Color.green.opacity(0.18) :
            isDisabled  ? Color(uiColor: .systemGray6) :
                          Color(uiColor: .systemGray5)
        )
        .foregroundStyle(
            isSelected  ? Color.green :
            isDisabled  ? Color.secondary.opacity(0.4) :
                          Color.secondary
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isDisabled ? 0.5 : 1.0)
        .onTapGesture { if !isDisabled { onTap() } }
    }
}

// MARK: - FarmInlineNumpad

private struct FarmInlineNumpad: View {

    @Binding var value:  Int
    let minVal: Int
    let maxVal: Int

    @State private var buffer: String = ""

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        numKey(key)
                    }
                }
            }
            // 最大值快捷按鈕
            Text("最大值（\(maxVal)）")
                .font(.callout).fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGray5))
                .foregroundStyle(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    buffer = "\(maxVal)"
                    value  = maxVal
                }
        }
        .onAppear { buffer = "" }
    }

    @ViewBuilder
    private func numKey(_ key: String) -> some View {
        let isAction = key == "C" || key == "⌫"
        Text(key)
            .font(.title3).fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                key == "C"
                    ? Color.red.opacity(0.12)
                    : isAction
                        ? Color(uiColor: .systemGray4)
                        : Color(uiColor: .systemGray5)
            )
            .foregroundStyle(key == "C" ? Color.red : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture { handleKey(key) }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            buffer = ""
            value  = minVal
        case "⌫":
            let s       = buffer.isEmpty ? "\(value)" : buffer
            let trimmed = String(s.dropLast())
            buffer = trimmed
            value  = trimmed.isEmpty ? minVal : max(minVal, min(Int(trimmed) ?? minVal, maxVal))
        default:
            let next = (buffer.isEmpty && key == "0") ? "" : buffer + key
            if let v = Int(next), v >= 1, v <= maxVal {
                buffer = next
                value  = v
            } else if next.isEmpty {
                buffer = ""
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: PlayerStateModel.self, MaterialInventoryModel.self,
             EquipmentModel.self, TaskModel.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    FarmerPlotSheet(
        viewModel: BaseViewModel(),
        plotIndex: 0,
        player:    nil,
        inventory: nil
    )
    .modelContainer(container)
}
