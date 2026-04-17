# V6-2 Ticket 10：技能 Tab 重構（主動/被動合併 + 可收合 UI）

**狀態：** ✅ 完成
**版本：** V6-2
**依賴：** T08、T09
**修改檔案：** `IdleBattleRPG/Views/CharacterView.swift`

---

## 說明

將原本的 `技能` 與 `天賦` 兩個獨立 Segment 合併成單一 `技能` Segment，
內部分為「主動技能」和「被動技能（天賦）」兩個 Section。
所有技能 / 天賦節點改用 `DisclosureGroup` 可收合展示，展開後顯示每個等級的效果。

---

## CharacterSegment 修改

移除 `.talent`，保留 `.skills`（語意不變，現在涵蓋主動＋被動）：

```swift
private enum CharacterSegment: String, CaseIterable {
    case gear        = "裝備"
    case backpack    = "背包"
    case skills      = "技能"    // 主動 + 被動合併（移除 .talent）
    case achievement = "成就"
}
```

---

## 技能 Tab 整體結構

```
技能 Tab（skillsSegment）
│
├── Section「主動技能」
│   ├── 可用技能點：N 點（橘色 badge）
│   ├── 配備欄（4 格）
│   ├── [已解鎖技能] ForEach → DisclosureGroup
│   │   ├── 摘要行（關閉時）：技能名 · 目前 Lv. · 配備狀態
│   │   └── 展開內容：
│   │       ├── Lv.1～Lv.maxLevel 效果文字（已升亮色，未升灰色）
│   │       ├── 升階預覽（若 T07 完成）
│   │       └── 升階按鈕（有技能點 + 未達上限時顯示）
│   └── [尚未解鎖技能] 灰化列表（不可收合）
│
└── Section「被動技能」
    ├── 可用天賦點：N 點（橘色 badge）
    ├── [路線 A] DisclosureGroup（Section 層級）
    │   ├── 路線名稱 · 主題描述
    │   └── 節點 1～5（各為可收合列）
    │       ├── 摘要行：節點名 · 投入次數 N/maxLevel
    │       └── 展開內容：
    │           ├── Lv.1～Lv.maxLevel 效果文字（已投亮色）
    │           └── 投入按鈕（有天賦點 + 未達上限 + 未互斥時顯示）
    └── [路線 B] 同上（若互斥鎖定則全灰 + 🔒 標示）
```

---

## 主動技能 DisclosureGroup 實作

```swift
@ViewBuilder
private func activeSkillDisclosure(
    skill: SkillDef,
    player: PlayerStateModel,
    equipped: [String]
) -> some View {
    let currentLevel = player.level(of: skill.key)
    let isEquipped   = equipped.contains(skill.key)
    let canUpgrade   = appState.skillUpgradeService.canUpgrade(skillKey: skill.key, for: player)

    DisclosureGroup {
        // 每等效果文字
        ForEach(0..<skill.maxLevel, id: \.self) { idx in
            HStack {
                Text("Lv.\(idx + 1)")
                    .frame(width: 36, alignment: .leading)
                Spacer()
                Text(skill.effectDescription(at: idx))
                    .foregroundStyle(currentLevel > idx ? Color.primary : Color.secondary.opacity(0.5))
            }
            .font(.caption)
        }

        // 升階 / 最高等級標示
        if currentLevel >= skill.maxLevel {
            Label("已達最高等級", systemImage: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if canUpgrade {
            Button("升階（-1 技能點）Lv.\(currentLevel) → \(currentLevel + 1)") {
                try? appState.skillUpgradeService.upgradeSkill(skillKey: skill.key, for: player)
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(.orange)
        }

    } label: {
        // 摘要行
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isEquipped ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: isEquipped ? "bolt.fill" : "bolt")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isEquipped ? .orange : .secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(skill.name).fontWeight(.medium)
                    Text("Lv.\(currentLevel)/\(skill.maxLevel)")
                        .font(.caption2)
                        .foregroundStyle(currentLevel > 0 ? .orange : .secondary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(skill.effectDescription(at: max(0, currentLevel - 1)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            // 配備 / 移除按鈕
            if isEquipped {
                Button("移除") { /* 同現有邏輯 */ }
                    .font(.caption).buttonStyle(.bordered).tint(.secondary)
                    .disabled(isOnExpedition)
            } else {
                Button("配備") { /* 同現有邏輯 */ }
                    .font(.caption).buttonStyle(.bordered).tint(.orange)
                    .disabled(isOnExpedition || equipped.count >= 4)
            }
        }
    }
}
```

---

## 被動技能（天賦）DisclosureGroup 實作

```swift
@ViewBuilder
private func passiveRouteSection(
    route: TalentRouteDef,
    player: PlayerStateModel,
    isLocked: Bool
) -> some View {
    let header = HStack {
        VStack(alignment: .leading, spacing: 1) {
            Text(route.name).fontWeight(.semibold)
            Text(route.themeDescription).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        if isLocked {
            Label("互斥鎖定", systemImage: "lock.fill")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    Section(header: header) {
        ForEach(route.nodes, id: \.key) { node in
            passiveNodeDisclosure(node: node, player: player, isRouteLocked: isLocked)
        }
    }
    .disabled(isLocked)   // 整個 Section 灰化
}

@ViewBuilder
private func passiveNodeDisclosure(
    node: TalentNodeDef,
    player: PlayerStateModel,
    isRouteLocked: Bool
) -> some View {
    let investedCount = node.currentLevel(in: player)
    let isMaxed       = node.isMaxed(in: player)
    let canInvest     = !isRouteLocked && appState.talentService.canInvest(nodeKey: node.key, for: player)

    DisclosureGroup {
        // 每等效果文字
        ForEach(1...node.maxLevel, id: \.self) { lv in
            HStack {
                Text("Lv.\(lv)")
                    .frame(width: 36, alignment: .leading)
                Spacer()
                Text(node.effectSummary)
                    .foregroundStyle(investedCount >= lv ? Color.primary : Color.secondary.opacity(0.4))
            }
            .font(.caption)
        }

        // 投入按鈕
        if isMaxed {
            Label("已達上限", systemImage: "checkmark.seal.fill")
                .font(.caption).foregroundStyle(.green)
        } else if canInvest {
            Button("投入（-1 天賦點）") {
                try? appState.talentService.investPoint(nodeKey: node.key, for: player)
            }
            .font(.caption).buttonStyle(.bordered).tint(.blue)
        }

    } label: {
        HStack(spacing: 10) {
            Circle()
                .fill(isMaxed ? Color.green : (canInvest ? Color.blue : Color.secondary.opacity(0.25)))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .fontWeight(.medium)
                    .foregroundStyle(isMaxed || canInvest ? Color.primary : Color.secondary)
                Text(node.effectSummary)
                    .font(.caption)
                    .foregroundStyle(isMaxed || canInvest ? Color.secondary : Color.secondary.opacity(0.4))
            }
            Spacer()
            Text("\(investedCount)/\(node.maxLevel)")
                .font(.caption2)
                .foregroundStyle(isMaxed ? .green : (investedCount > 0 ? .blue : .secondary))
                .monospacedDigit()
        }
    }
}
```

---

## 點數 Badge（Tab 標題旁）

```swift
// ContentView.swift，CharacterView tab badge
.badge(players.first.map {
    max(0, $0.availableStatPoints + $0.availableTalentPoints + $0.availableSkillPoints)
} ?? 0)
```

---

## 移除舊 talentSegment

`talentSegment`、`talentContent(player:)`、`talentNodeRow(node:player:)` 三個方法整合進新的 `skillsSegment`，舊方法全部移除。

---

## 驗收標準

- [ ] `CharacterSegment` 不含 `.talent`，只保留 `.skills`
- [ ] 技能 Tab：上半「主動技能」Section（配備欄 + 已解鎖技能列表）
- [ ] 技能 Tab：下半「被動技能」Section（天賦點 badge + 路線 DisclosureGroup）
- [ ] 主動技能：每個可收合，展開顯示 Lv.1–Lv.3 效果 + 升階按鈕（有技能點時）
- [ ] 被動技能：每個節點可收合，展開顯示 Lv.1–N 效果 + 投入按鈕
- [ ] 路線互斥鎖定時，整個路線 Section 灰化 + 🔒 標示
- [ ] Tab badge = 屬性點 + 天賦點 + 技能點總和
- [ ] `xcodebuild` 通過，無新警告
