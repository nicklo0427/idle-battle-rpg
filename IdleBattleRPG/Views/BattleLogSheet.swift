// BattleLogSheet.swift
// V4-1 重設計：戰鬥記錄 Sheet（AFK 查看 + V4-2 菁英戰鬥共用）
//
// 單場模式：每次只顯示當前這場的事件
//   - 英雄（黃）和敵方（橙）ATB 條同時填充，先滿先動
//   - 勝/敗後停留 2 秒，清空，自動進入下一場
//   - 頂部顯示「第 N 場 / 共 M 場」
//
// 播放狀態由 BattleLogPlaybackModel（@Observable）持有，
// 關閉 Sheet 不停止播放，重開時從當前位置繼續。
//
// 菁英模式（V4-2 預留）：傳入 eliteResult + onRetry

import SwiftUI

// MARK: - 菁英戰鬥結果型別（V4-2 預留接口）

enum EliteBattleOutcome {
    case won(rewardText: String)
    case lost
}

// MARK: - BattleLogSheet

struct BattleLogSheet: View {

    let model:      BattleLogPlaybackModel
    let title:      String
    let enemyLabel: String
    var eliteResult: EliteBattleOutcome? = nil
    var onRetry:     (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // MARK: - HP 計算（從當前場次事件取）

    private var heroMaxHp:  Int { model.currentBattleEvents.first?.heroMaxHp  ?? 100 }
    private var enemyMaxHp: Int { model.currentBattleEvents.first?.enemyMaxHp ?? 100 }

    private var currentHeroHp: Int {
        model.currentBattleEvents.prefix(model.displayedCount).last?.heroHpAfter ?? heroMaxHp
    }

    private var currentEnemyHp: Int {
        model.currentBattleEvents.prefix(model.displayedCount).last?.enemyHpAfter ?? enemyMaxHp
    }

    // MARK: - 場次標籤

    private var battleLabel: String? {
        guard model.taskTotalBattles > 0 else { return nil }
        let n = model.fromBattleIndex + model.currentBattleInSession + 1
        return "第 \(n) 場 / 共 \(model.taskTotalBattles) 場"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                hpBarsView
                Divider()
                eventScrollView
                if let result = eliteResult {
                    eliteResultView(result: result)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        // 關閉 Sheet 時不停止播放（背景繼續執行）
        // onDisappear 刻意不呼叫 model.stop()
    }

    // MARK: - HP + ATB 血量條

    private var hpBarsView: some View {
        VStack(spacing: 4) {
            hpBar(icon: "🧙", label: "英雄",
                  current: currentHeroHp, maxHp: heroMaxHp, color: .blue)
            atbBar(progress: model.heroATBProgress,
                   color: model.isExploring ? .teal : .yellow)

            if model.isBattleActive {
                Spacer().frame(height: 4)
                hpBar(icon: "👹", label: enemyLabel,
                      current: currentEnemyHp, maxHp: enemyMaxHp, color: .red)
                atbBar(progress: model.enemyATBProgress, color: .orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.25), value: model.isBattleActive)
    }

    private func hpBar(icon: String, label: String,
                       current: Int, maxHp: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text("\(icon) \(label)")
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
            ProgressView(value: Double(Swift.max(0, current)),
                         total:  Double(Swift.max(1, maxHp)))
                .tint(color)
                .animation(.easeInOut(duration: 0.2), value: current)
            Text("\(Swift.max(0, current))/\(maxHp)")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }

    private func atbBar(progress: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Spacer().frame(width: 100)
            ProgressView(value: progress, total: 1.0)
                .tint(color)
                // 步進補間（歸零由 Model 的 withAnimation(nil) 控制，不倒退）
                .animation(.linear(duration: 0.055), value: progress)
            Spacer().frame(width: 72)
        }
    }

    // MARK: - 事件 ScrollView

    private var eventScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if let label = battleLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                    }
                    ForEach(Array(model.currentBattleEvents.prefix(model.displayedCount).enumerated()), id: \.offset) { idx, event in
                        eventRow(event).id(idx)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: model.displayedCount) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    private func eventRow(_ event: BattleEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(eventIcon(event.type))
                .frame(width: 18)
            Text(event.description)
                .font(.subheadline)
                .foregroundStyle(eventColor(event.type))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 菁英模式底部（V4-2 預留）

    @ViewBuilder
    private func eliteResultView(result: EliteBattleOutcome) -> some View {
        Divider()
        VStack(spacing: 12) {
            switch result {
            case .won(let rewardText):
                Text(rewardText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.green)
                Button("關閉") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            case .lost:
                Text("落敗… 再試一次")
                    .foregroundStyle(.red)
                Button("再試一次") {
                    onRetry?()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func eventIcon(_ type: BattleEvent.EventType) -> String {
        switch type {
        case .explore:   return "🗺"
        case .encounter: return "⚠️"
        case .attack:    return "⚔"
        case .damage:    return "🛡"
        case .victory:   return "✓"
        case .defeat:    return "✗"
        case .heal:      return "💚"
        }
    }

    private func eventColor(_ type: BattleEvent.EventType) -> Color {
        switch type {
        case .explore:   return .secondary
        case .encounter: return .orange
        case .attack:    return .primary
        case .damage:    return .orange
        case .victory:   return .green
        case .defeat:    return .red
        case .heal:      return .green
        }
    }
}
