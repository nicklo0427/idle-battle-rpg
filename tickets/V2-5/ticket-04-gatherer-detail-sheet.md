# V2-5 Ticket 04：採集者詳細頁（升級 UI 移入）

**狀態：** ✅ 完成

**依賴：** Ticket 03（GathererNpcDef + NpcKind 已定義）

---

## 目標

目前升級入口藏在長按 contextMenu，不易發現。
改為：**點擊採集者 row（不論忙閒）→ 開啟詳細頁 Sheet**，
詳細頁包含三個區塊：
1. 目前狀態（目前 Tier、tier 效果）
2. 升級（費用、按鈕）
3. 派遣（地點選擇，閒置時才可操作）

長按 contextMenu 同步移除。

---

## UI 結構（GathererDetailSheet）

**新檔案：** `IdleBattleRPG/Views/GathererDetailSheet.swift`

```
NavigationStack
  .navigationTitle(npc.name)               // 「伐木工」/ 「採礦工」

  List {

    // ── Section 1：目前狀態 ──────────────────────────────
    Section("目前狀態") {
      行：圖示 + 名稱 + Tier badge（同 BaseView tierBadge）
      行：tier 效果說明
          Tier 0：「無額外加成」
          Tier 1+：「每次採集 +N 額外產出」
    }

    // ── Section 2：升級 ──────────────────────────────────
    Section("升級") {
      if 已滿 Tier 3：
        Text("已達升級上限 T3")

      else（顯示下一 Tier 費用）：
        行：EXP \(cost.expCost)（持有 \(player.heroExp)）
        行：素材（一行一種，持有量 / 需求）
        行：金幣 \(cost.goldCost)（持有 \(player.gold)）
        Button("升至 T\(currentTier + 1)")
          .disabled(!canUpgrade)
          .buttonStyle(.borderedProminent)
    }

    // ── Section 3：派遣 ──────────────────────────────────
    Section("派遣") {
      if 忙碌中：
        行：「採集中：\(location.name)」
        倒數文字 + ProgressView（同 BaseView 現有 npcGathererRow 的樣式）

      else（閒置，可派遣）：
        ForEach(filteredLocations) { location in
          locationRow(location)    // 複用 GatherSheet.locationRow 結構
        }
    }
  }
```

---

## 修改：BaseView

**檔案：** `IdleBattleRPG/Views/BaseView.swift`

### 改動一：採集者 row 永遠可點，移除 contextMenu

```swift
// 改前
Button(action: { if !isBusy { onTap() } }) { ... }
.contextMenu { ... }

// 改後
Button(action: { onTap() }) { ... }
// 不再有 .contextMenu
```

### 改動二：Sheet 觸發改為開啟 GathererDetailSheet

```swift
// 改前（showGatherSheet1/2 控制 GatherSheet）
.sheet(isPresented: $showGatherSheet1) {
    GatherSheet(actorKey: "gatherer_1", ...)
}

// 改後（showDetailSheet + selectedGatherer）
@State private var selectedGatherer: GathererNpcDef?

.sheet(item: $selectedGatherer) { npc in
    GathererDetailSheet(
        npcDef:  npc,
        appState: appState
    )
}
```

`npcGathererRow` 的 `onTap` 設為 `selectedGatherer = npc`。

### 改動三：閒置提示文字修改

```swift
// 改前
Text("閒置中，點擊派遣")

// 改後
Text("閒置中，點擊查看")
```

---

## GathererDetailSheet 實作細節

**檔案：** `IdleBattleRPG/Views/GathererDetailSheet.swift`（新檔）

```swift
struct GathererDetailSheet: View {

    let npcDef:   GathererNpcDef
    let appState: AppState

    @Environment(\.modelContext) private var context
    @Query private var players:     [PlayerStateModel]
    @Query private var inventories: [MaterialInventoryModel]
    @Query private var tasks:       [TaskModel]

    @State private var selectedDurations: [String: Int] = [:]
    @State private var alertMsg: String?

    private var player: PlayerStateModel? { players.first }
    private var inventory: MaterialInventoryModel? { inventories.first }

    private var activeTask: TaskModel? {
        tasks.first { $0.actorKey == npcDef.actorKey && $0.status == .inProgress }
    }

    private var currentTier: Int {
        player?.tier(for: npcDef.actorKey) ?? 0
    }

    private var npcKind: NpcKind? {
        player?.npcKind(for: npcDef.actorKey)
    }

    private var upgradeCost: NpcUpgradeCostDef? {
        guard let kind = npcKind else { return nil }
        return appState.npcUpgradeService.nextUpgradeCost(
            npcKind: kind, actorKey: npcDef.actorKey, player: player ?? ...)
    }

    private var canUpgrade: Bool {
        guard let cost = upgradeCost, let player, let inventory else { return false }
        let expOk  = player.heroExp >= cost.expCost
        let matOk  = cost.materialCosts.allSatisfy { (mat, req) in inventory.amount(of: mat) >= req }
        let goldOk = player.gold >= cost.goldCost
        return expOk && matOk && goldOk
    }

    private var filteredLocations: [GatherLocationDef] {
        GatherLocationDef.all.filter { npcDef.locationKeys.contains($0.key) }
    }

    var body: some View {
        NavigationStack {
            List {
                statusSection
                upgradeSection
                dispatchSection
            }
            .navigationTitle(npcDef.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { /* dismiss */ }
                }
            }
            .alert("提示", isPresented: Binding(...)) {
                Button("確定", role: .cancel) { alertMsg = nil }
            } message: { Text(alertMsg ?? "") }
        }
    }

    // MARK: - Section：目前狀態

    @ViewBuilder
    private var statusSection: some View {
        Section("目前狀態") {
            HStack {
                Image(systemName: npcDef.icon).foregroundStyle(.green)
                Text(npcDef.name).fontWeight(.medium)
                Spacer()
                tierBadge(currentTier)
            }
            let bonus = NpcUpgradeDef.gatherBonus(tier: currentTier)
            Text(bonus > 0
                 ? "每次採集 +\(bonus) 額外產出"
                 : "無額外加成（升級後解鎖）")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section：升級

    @ViewBuilder
    private var upgradeSection: some View {
        Section("升級") {
            if currentTier >= NpcUpgradeDef.maxTier {
                Label("已達升級上限 T\(NpcUpgradeDef.maxTier)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
            } else if let cost = upgradeCost, let player {
                costRow(label: "EXP",
                        required: cost.expCost,
                        have: player.heroExp,
                        unit: "")
                ForEach(cost.materialCosts, id: \.0.rawValue) { (mat, req) in
                    costRow(label: mat.displayName,
                            required: req,
                            have: inventory?.amount(of: mat) ?? 0,
                            unit: mat.icon)
                }
                costRow(label: "金幣",
                        required: cost.goldCost,
                        have: player.gold,
                        unit: "💰")

                Button("升至 T\(currentTier + 1)") {
                    performUpgrade()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
                .disabled(!canUpgrade)
            }
        }
    }

    // MARK: - Section：派遣

    @ViewBuilder
    private var dispatchSection: some View {
        Section("派遣") {
            if let task = activeTask {
                // 忙碌中：顯示倒數
                if let def = GatherLocationDef.find(key: task.definitionKey) {
                    HStack {
                        Text("採集中：\(def.name)")
                        Spacer()
                    }
                }
                Text(TaskCountdown.remaining(for: task, relativeTo: appState.tick))
                    .foregroundStyle(.green)
                ProgressView(value: taskProgress(task))
                    .tint(.green)
            } else {
                // 閒置：地點選擇（複用 GatherSheet locationRow 結構）
                ForEach(filteredLocations, id: \.key) { location in
                    locationRow(location)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func costRow(label: String, required: Int, have: Int, unit: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.primary)
            Spacer()
            Text("\(have) / \(required) \(unit)")
                .font(.caption)
                .foregroundStyle(have >= required ? .secondary : .red)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func tierBadge(_ tier: Int) -> some View {
        Text(tier == 0 ? "T0" : "T\(tier)")
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(tier == 0 ? Color.gray.opacity(0.15) : Color.green.opacity(0.15))
            .foregroundStyle(tier == 0 ? .secondary : .green)
            .clipShape(Capsule())
    }

    private func performUpgrade() {
        guard let kind = npcKind, let player else { return }
        let result = appState.npcUpgradeService.upgrade(
            npcKind: kind, actorKey: npcDef.actorKey, player: player)
        if case .failure(let err) = result { alertMsg = err.message }
    }

    private func taskProgress(_ task: TaskModel) -> Double {
        let total    = task.endsAt.timeIntervalSince(task.startedAt)
        let elapsed  = appState.tick.timeIntervalSince(task.startedAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, elapsed / total))
    }
}
```

---

## 移除項目

| 項目 | 理由 |
|---|---|
| `BaseView.showGatherSheet1 / showGatherSheet2` | 改由 `selectedGatherer` 驅動 |
| `BaseView.GatherSheet sheet` × 2 | 改為單一 `GathererDetailSheet` |
| `npcGathererRow.contextMenu` | 升級入口移入詳細頁 |
| `GatherSheet.swift`（可保留或刪除） | 功能被 GathererDetailSheet 完整取代 |

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/GathererDetailSheet.swift` | ✅ 新增（詳細頁主體） |
| `Views/BaseView.swift` | ✏️ 修改（row 永遠可點、改 sheet 觸發、移除 contextMenu） |
| `Views/GatherSheet.swift` | 🗑 可刪除（功能已被取代） |

---

## 驗收標準

- [ ] 點忙碌中的伐木工 → 詳細頁顯示倒數 + 進度條
- [ ] 點閒置的採礦工 → 詳細頁顯示礦坑地點（不顯示森林）
- [ ] 詳細頁升級區塊各費用顯示正確，持有不足時紅字標示
- [ ] 升級按鈕在資源不足時 disabled
- [ ] 升級成功 → EXP / 素材 / 金幣正確扣除，Tier badge 即時更新
- [ ] BaseView 採集者 row 不再有 contextMenu
- [ ] Build 無錯誤
