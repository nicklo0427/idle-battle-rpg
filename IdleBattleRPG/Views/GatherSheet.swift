// GatherSheet.swift
// 採集派遣 Sheet
//
// 觸發：點擊閒置的採集者 NPC
// 功能：選擇採集地點 + 時長 → 建立採集任務
//
// 設計：
//   - 列出全部採集地點（2 個）
//   - 每個地點下方有時長選擇 Chip（短/中/長）
//   - 預設選中最短時長
//   - 點擊地點名稱列（Chip 以外區域）→ 以選中時長建立任務 → 自動關閉

import SwiftUI
import SwiftData

struct GatherSheet: View {

    let actorKey: String
    let actorName: String
    let viewModel: BaseViewModel
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context

    @State private var selectedDurations: [String: Int] = [:]
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(GatherLocationDef.all, id: \.key) { location in
                        locationRow(location)
                    }
                } header: {
                    Text("選擇採集地點")
                } footer: {
                    Text("派出後採集者將自動返回，無需手動收回。")
                        .font(.caption)
                }
            }
            .navigationTitle(actorName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .alert("無法派遣", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "發生未知錯誤")
            }
            .onAppear {
                // 初始化各地點選中最短時長
                for loc in GatherLocationDef.all {
                    if selectedDurations[loc.key] == nil {
                        selectedDurations[loc.key] = loc.shortestDuration
                    }
                }
            }
        }
    }

    // MARK: - Location Row

    @ViewBuilder
    private func locationRow(_ location: GatherLocationDef) -> some View {
        let selected = selectedDurations[location.key] ?? location.shortestDuration

        VStack(alignment: .leading, spacing: 8) {

            // ── 上半：地點資訊 + 出發箭頭（點擊 → 派遣）────────────────
            Button {
                startGather(location: location, duration: selected)
            } label: {
                HStack(spacing: 12) {
                    Text(location.outputMaterial.icon)
                        .font(.title2)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(AppConstants.DungeonDuration.displayName(for: selected))
                                .font(.caption)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(location.outputMaterial.displayName) \(location.outputRange.lowerBound)–\(location.outputRange.upperBound)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(GatherRowButtonStyle())

            // ── 下半：時長 Chip 選擇（不觸發派遣）────────────────────────
            HStack(spacing: 6) {
                ForEach(location.durationOptions, id: \.self) { dur in
                    Button {
                        selectedDurations[location.key] = dur
                    } label: {
                        Text(AppConstants.DungeonDuration.displayName(for: dur))
                            .font(.caption)
                            .fontWeight(selected == dur ? .semibold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                selected == dur
                                    ? Color.green.opacity(0.18)
                                    : Color(uiColor: .systemGray5)
                            )
                            .foregroundStyle(selected == dur ? .green : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 48)   // 與文字欄對齊
            .padding(.bottom, 4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Action

    private func startGather(location: GatherLocationDef, duration: Int) {
        let result = viewModel.startGatherTask(
            actorKey:        actorKey,
            locationKey:     location.key,
            durationSeconds: duration,
            context:         context
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

// MARK: - Button Style

private struct GatherRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    GatherSheet(
        actorKey: AppConstants.Actor.gatherer1,
        actorName: "採集者 1",
        viewModel: BaseViewModel(),
        isPresented: $isPresented
    )
    .modelContainer(for: [
        PlayerStateModel.self, MaterialInventoryModel.self,
        EquipmentModel.self, TaskModel.self,
    ], inMemory: true)
}
