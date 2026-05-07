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

    let model:          BattleLogPlaybackModel
    let title:          String
    let enemyLabel:     String
    var enemyImageName: String?            = nil
    var eliteResult:    EliteBattleOutcome? = nil
    var onRetry:        (() -> Void)?       = nil

    @Environment(\.dismiss) private var dismiss

    @State private var heroDamageFlash:    Int?  = nil
    @State private var enemyDamageFlash:   Int?  = nil
    @State private var heroDamageFlashID:  UUID  = UUID()
    @State private var enemyDamageFlashID: UUID  = UUID()

    // MARK: - HP 計算（從當前場次事件取）

    private var heroMaxHp:  Int { model.currentBattleEvents.first?.heroMaxHp  ?? 100 }
    private var enemyMaxHp: Int { model.currentBattleEvents.first?.enemyMaxHp ?? 100 }

    private var currentHeroHp: Int {
        model.currentBattleEvents.prefix(model.displayedCount).last?.heroHpAfter ?? heroMaxHp
    }

    private var currentEnemyHp: Int {
        model.currentBattleEvents.prefix(model.displayedCount).last?.enemyHpAfter ?? enemyMaxHp
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                battleVisualsView
                    .onChange(of: model.displayedCount) { _, _ in
                        guard let event = model.currentBattleEvents.prefix(model.displayedCount).last else { return }
                        switch event.type {
                        case .damage where event.damageAmount > 0:
                            let id = UUID()
                            heroDamageFlashID = id
                            withAnimation { heroDamageFlash = event.damageAmount }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                guard heroDamageFlashID == id else { return }
                                withAnimation { heroDamageFlash = nil }
                            }
                        case .attack where event.damageAmount > 0,
                             .skill  where event.damageAmount > 0:
                            let id = UUID()
                            enemyDamageFlashID = id
                            withAnimation { enemyDamageFlash = event.damageAmount }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                guard enemyDamageFlashID == id else { return }
                                withAnimation { enemyDamageFlash = nil }
                            }
                        case .heal where event.damageAmount > 0:
                            let id = UUID()
                            heroDamageFlashID = id
                            withAnimation { heroDamageFlash = -(event.damageAmount) }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                guard heroDamageFlashID == id else { return }
                                withAnimation { heroDamageFlash = nil }
                            }
                        default: break
                        }
                    }
                if !model.skillCooldownFractions.isEmpty {
                    skillCooldownPanel
                    Divider()
                }
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

    // MARK: - 左右對峙版面（E + D）

    private var battleVisualsView: some View {
        HStack(alignment: .top, spacing: 12) {
            heroColumn
            Spacer()
            Image(systemName: model.isBattleActive ? "figure.fencing" : "map.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .padding(.top, 6)
            Spacer()
            enemyColumn
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var heroColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "person.fill").foregroundStyle(.blue)
                Text("英雄").font(.caption).fontWeight(.semibold)
            }
            ProgressView(value: Double(max(0, currentHeroHp)), total: Double(max(1, heroMaxHp)))
                .tint(.blue)
                .animation(.easeInOut(duration: 0.2), value: currentHeroHp)
                .overlay(alignment: .trailing) {
                    if let dmg = heroDamageFlash {
                        Text(dmg < 0 ? "+\(-dmg)" : "-\(dmg)")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundStyle(dmg < 0 ? .green : .red)
                            .padding(.trailing, 4)
                    }
                }
            Text("\(max(0, currentHeroHp))/\(heroMaxHp)")
                .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
            ProgressView(value: model.heroATBProgress, total: 1.0)
                .tint(model.isExploring ? .teal : .yellow)
                .animation(.linear(duration: 0.055), value: model.heroATBProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var enemyColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Text(enemyLabel).font(.caption).fontWeight(.semibold)
                if let imgName = enemyImageName {
                    Image(webp: imgName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 26, height: 26)
                        Image(systemName: "skull")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            ProgressView(value: Double(max(0, currentEnemyHp)), total: Double(max(1, enemyMaxHp)))
                .tint(.red)
                .animation(.easeInOut(duration: 0.2), value: currentEnemyHp)
                .overlay(alignment: .trailing) {
                    if let dmg = enemyDamageFlash {
                        Text("-\(dmg)")
                            .font(.caption2).fontWeight(.bold).foregroundStyle(.orange)
                            .padding(.trailing, 4)
                    }
                }
            Text("\(max(0, currentEnemyHp))/\(enemyMaxHp)")
                .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
            ProgressView(value: model.enemyATBProgress, total: 1.0)
                .tint(.orange)
                .animation(.linear(duration: 0.055), value: model.enemyATBProgress)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .opacity(model.isBattleActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: model.isBattleActive)
    }

    // MARK: - T09：技能 CD 面板

    private var skillCooldownPanel: some View {
        VStack(spacing: 4) {
            ForEach(model.skillCooldownFractions, id: \.key) { item in
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(item.fraction >= 1.0 ? Color.orange : Color.secondary)
                        .frame(width: 14)
                    Text(item.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 48, alignment: .leading)
                        .lineLimit(1)
                    ProgressView(value: item.fraction, total: 1.0)
                        .tint(item.fraction >= 1.0 ? Color.orange : Color.gray)
                        .frame(maxWidth: .infinity)
                        .animation(.linear(duration: 0.1), value: item.fraction)
                    Text(item.fraction >= 1.0 ? "就緒" : "CD")
                        .font(.caption2)
                        .foregroundStyle(item.fraction >= 1.0 ? Color.orange : Color.secondary)
                        .frame(minWidth: 24, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 事件 ScrollView

    private var eventScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
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

    private func isHighlightedEvent(_ event: BattleEvent) -> Bool {
        switch event.type {
        case .skill, .victory, .defeat, .encounter: return true
        case .attack: return event.isCrit
        default: return false
        }
    }

    private func eventRow(_ event: BattleEvent) -> some View {
        let highlight = isHighlightedEvent(event)
        return HStack(alignment: .top, spacing: 8) {
            eventIconView(event.type)
                .frame(width: highlight ? 18 : 16, height: highlight ? 18 : 16)
                .padding(.top, 2)
            Text(event.description)
                .font(highlight ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(eventColor(event.type))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, highlight ? 8 : 0)
        .padding(.vertical, highlight ? 4 : 0)
        .background(highlight ? eventColor(event.type).opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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

    @ViewBuilder
    private func eventIconView(_ type: BattleEvent.EventType) -> some View {
        switch type {
        case .skill:          Image(systemName: "bolt.fill").foregroundStyle(Color.orange)
        case .explore:        Image(systemName: "map.fill").foregroundStyle(Color.secondary)
        case .encounter:      Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.orange)
        case .attack:         Image(systemName: "figure.fencing").foregroundStyle(Color.primary)
        case .damage:         Image(systemName: "shield.fill").foregroundStyle(Color.orange)
        case .victory:        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
        case .defeat:         Image(systemName: "xmark.circle.fill").foregroundStyle(Color.red)
        case .heal:           Image(systemName: "heart.fill").foregroundStyle(Color.green)
        case .statusApplied:  Image(systemName: "flame.fill").foregroundStyle(Color.orange)
        case .statusTick:     Image(systemName: "drop.fill").foregroundStyle(Color.purple)
        case .statusExpired:  Image(systemName: "wind").foregroundStyle(Color.secondary)
        case .potionUsed:     Image(systemName: "pills.fill").foregroundStyle(Color.teal)  // V7-4
        }
    }

    private func eventColor(_ type: BattleEvent.EventType) -> Color {
        switch type {
        case .skill:          return .orange
        case .explore:        return .secondary
        case .encounter:      return .orange
        case .attack:         return .primary
        case .damage:         return .orange
        case .victory:        return .green
        case .defeat:         return .red
        case .heal:           return .green
        case .statusApplied:  return .orange
        case .statusTick:     return .purple
        case .statusExpired:  return .secondary
        case .potionUsed:     return .teal  // V7-4
        }
    }
}
