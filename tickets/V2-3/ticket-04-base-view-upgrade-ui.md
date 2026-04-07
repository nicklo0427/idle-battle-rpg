# V2-3 Ticket 04：BaseView NPC 升級 UI

**狀態：** ✅ 完成

**依賴：** Ticket 03（NpcUpgradeService）

---

## 目標

在 `BaseView` 的 NPC 列表行加入升級等級 Badge，並透過長按 contextMenu 提供升級入口，點擊後顯示確認 Alert。

---

## UI 規格

### NPC 行外觀

```
[⛏️ 採集者 1]  正在採集木材…  [T2]
[⚒️ 採集者 2]  閒置中          [T0 不顯示]
[🔨 鑄造師]    正在打造…       [T1]
```

- Tier 0：不顯示 badge
- Tier 1/2/3：右側顯示圓角小標籤 `T1` / `T2` / `T3`（accent color）

### 長按 contextMenu

```
採集者 1（T2）
● 升級到 T3（需 2,500 金）   ← 有下一級時
● 已達升級上限               ← T3 時（disabled）
```

金幣不足時選項文字為「升級到 T3（需 2,500 金，金幣不足）」並 disabled。

### 確認 Alert

點擊「升級到 TN」→ 彈出 Alert：

```
升級採集者 1 到 T3？
費用：2,500 金幣

[取消]  [確認升級]
```

---

## 實作要點

### 狀態管理

```swift
// 複用 CharacterView Alert 模式
@State private var pendingUpgradeInfo: (npcKind: NpcKind, actorKey: String, label: String, cost: Int)?
```

### contextMenu

```swift
.contextMenu {
    if let cost = appState.npcUpgradeService.nextUpgradeCost(
        npcKind: npcKind, actorKey: actorKey, player: player) {
        let canAfford = player.gold >= cost
        let nextTier = player.tier(for: actorKey) + 1
        Button(
            canAfford ? "升級到 T\(nextTier)（需 \(cost) 金）"
                      : "升級到 T\(nextTier)（需 \(cost) 金，金幣不足）"
        ) {
            pendingUpgradeInfo = (npcKind, actorKey, npcLabel, cost)
        }
        .disabled(!canAfford)
    } else {
        Text("已達升級上限").foregroundStyle(.secondary)
    }
}
```

### Alert

```swift
.alert(
    item: $pendingUpgradeInfo
) { info in
    Alert(
        title: Text("升級 \(info.label)？"),
        message: Text("費用：\(info.cost) 金幣"),
        primaryButton: .default(Text("確認升級")) {
            appState.npcUpgradeService.upgrade(
                npcKind: info.npcKind,
                actorKey: info.actorKey,
                player: player
            )
        },
        secondaryButton: .cancel(Text("取消"))
    )
}
```

> `pendingUpgradeInfo` 需為 `Identifiable` 的 struct，或使用 SwiftUI 5.0+ `alert(isPresented:)` 搭配額外狀態。建議用同 CharacterView 的 presenting 寫法。

### Tier Badge

```swift
@ViewBuilder
func tierBadge(tier: Int) -> some View {
    if tier > 0 {
        Text("T\(tier)")
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/BaseView.swift` | ✏️ 修改（Badge + contextMenu + Alert）|

---

## 驗收標準

- [ ] NPC 行在 Tier > 0 時顯示 `T1`/`T2`/`T3` Badge
- [ ] 長按 NPC 行出現 contextMenu
- [ ] 未達上限且金幣充足時，選項可點擊，彈出確認 Alert
- [ ] 金幣不足時選項 disabled
- [ ] 已達 Tier 3 時顯示「已達升級上限」（disabled）
- [ ] 確認 Alert 點擊「確認升級」後升級成功，tier 即時更新（@Observable 自動刷新）
- [ ] 取消 Alert 不執行升級
- [ ] 現有採集 / 鑄造 / 商人功能無回歸
