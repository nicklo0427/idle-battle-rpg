# V9-2 Ticket 02：角色裝備槽 Grid 卡片化

**狀態：** 📋 規劃中

**依賴：** 無（不需要圖片資源）

---

## 目標

CharacterView 裝備分頁目前是 4 個 List Row（武器 / 副手 / 防具 / 飾品），
資訊密度低，視覺不夠直觀。

改為 2×2 LazyVGrid 卡片，每張卡片聚焦展示「這個部位穿了什麼」，
讓玩家一眼看出裝備狀態。

---

## 新 UI 設計

```
┌──────────────────────────────────────────────────┐
│  已裝備                                          │
│                                                  │
│  ┌────────────────┐  ┌────────────────┐         │
│  │ 🗡️ 武器        │  │ 🛡️ 副手        │         │
│  │ ────────────── │  │ 精良圓盾       │         │
│  │ 鐵製長劍 +2    │  │ ATK +5         │         │
│  │ ATK +18        │  │ DEF +8         │         │
│  │ [強化] [卸除]  │  │        [卸除]  │         │
│  └────────────────┘  └────────────────┘         │
│  ┌────────────────┐  ┌────────────────┐         │
│  │ 🥋 防具        │  │ 💍 飾品        │         │
│  │  （未裝備）    │  │ （未裝備）     │         │
│  │                │  │                │         │
│  └────────────────┘  └────────────────┘         │
└──────────────────────────────────────────────────┘
```

**卡片結構：**

```swift
VStack(alignment: .leading, spacing: 6) {
    // 頂列：部位 icon + 部位名稱
    HStack {
        Text(slot.icon).font(.title3)
        Text(slot.displayName)
            .font(.caption).foregroundStyle(.secondary)
        Spacer()
        // 稀有度小點（有裝備且非普通稀有度）
        if let item, item.rarity.hasAccent {
            Circle()
                .fill(item.rarity.displayColor)
                .frame(width: 6, height: 6)
        }
    }

    // 裝備名稱（或未裝備提示）
    if let item {
        HStack(spacing: 2) {
            if item.isRolledBossWeapon {
                Text("✦").font(.caption2).foregroundStyle(.yellow)
            }
            Text(item.displayName)
                .fontWeight(.semibold)
                .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        // 主要加成
        VStack(alignment: .leading, spacing: 1) {
            if item.atkBonus > 0 { Text("ATK +\(item.atkBonus)").font(.caption2)... }
            if item.defBonus > 0 { Text("DEF +\(item.defBonus)").font(.caption2)... }
            if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").font(.caption2)... }
        }
    } else {
        Text("未裝備").foregroundStyle(.tertiary).font(.callout)
    }

    Spacer()

    // 底列操作按鈕
    if let item, !isOnExpedition {
        HStack(spacing: 6) {
            if item.enhancementLevel < EnhancementDef.maxLevel {
                Button { pendingEnhanceItem = item } label: {
                    Image(systemName: "hammer").font(.caption)
                }
                .buttonStyle(.bordered).tint(.orange)
            }
            Spacer()
            Button { viewModel.unequip(item, context: context) } label: {
                Image(systemName: "xmark").font(.caption)
            }
            .buttonStyle(.bordered).tint(.secondary)
        }
    } else if isOnExpedition {
        Label("出征中", systemImage: "lock.fill")
            .font(.caption2).foregroundStyle(.secondary)
    }
}
.padding(10)
.frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 14))
// 稀有度左側色條以 overlay 呈現（左側 3pt 窄條，圓角）
.overlay(alignment: .leading) {
    if let item {
        Capsule()
            .fill(item.rarity.hasAccent ? item.rarity.displayColor.opacity(0.8) : Color.clear)
            .frame(width: 3)
    }
}
// 點整卡片 → 開裝備選擇 Sheet
.contentShape(RoundedRectangle(cornerRadius: 14))
.onTapGesture {
    guard !isOnExpedition else { return }
    equipSheetSlot = slot
}
```

---

## 修改範圍

### `Views/CharacterView.swift`

**1. `gearSegment` — 重構為 LazyVGrid**

```swift
@ViewBuilder
private var gearSegment: some View {
    Section {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(slotDisplayOrder, id: \.self) { slot in
                let item = equippedItems.first { $0.slot == slot }
                equippedSlotCard(slot: slot, item: item)
            }
        }
        .padding(.vertical, 4)
    } header: {
        Text("已裝備（\(viewModel.equippedCount(from: equipments)) / 4）")
    } footer: {
        Text("點擊卡片可切換，錘子圖示可強化")
            .font(.caption)
    }
}
```

**2. `equippedSlotRow` → `equippedSlotCard`**

將現有 `equippedSlotRow` helper 重寫為上方卡片設計。
`equippedSlotRow` 完全移除（不再使用）。

**3. 強化確認 / 卸除邏輯不動**

`pendingEnhanceItem`、`viewModel.unequip()`、`equipSheetSlot` — 完全保留，只改觸發位置（從 row 移至 card 按鈕）。

---

## 不改動範圍

- Alert bindings（強化 / 卸除確認）
- EquipSelectSheet
- 所有其他 Segment（狀態 / 背包 / 技能 / 成就）

---

## 風險注意事項

**Grid 內 tap gesture 與 List 手勢衝突：**
卡片整體要點擊開 `EquipSelectSheet`，但卡片內部又有強化 / 卸除按鈕。
需確認：
- 卡片用 `.contentShape(RoundedRectangle(cornerRadius: 14)).onTapGesture { ... }` 而非 `Button`，避免 Button 在 List 內吃掉 tap event
- 強化 / 卸除 Button 加 `.buttonStyle(.bordered)` 並確認點擊範圍不與整卡點擊衝突

**空槽的視覺清晰度：**
4 槽全空時，2×2 grid 全部顯示「未裝備」——視覺上可能顯得空洞。
確認空槽卡片有足夠的 `minHeight`（建議 100pt）並顯示部位 icon，讓玩家一眼看出「這裡可以裝備東西」。

---

## 驗證方式

1. `xcodebuild` 通過，無新警告
2. 模擬器：
   - 裝備分頁：4 張卡片排 2×2，已裝備顯示裝備名稱 + 主要加成
   - 空槽顯示「未裝備」+ 部位名稱，minHeight 充足不顯空洞
   - **點擊每張卡片（含空槽）→ EquipSelectSheet 正確開啟，部位對應無誤**
   - **點擊強化按鈕 → Alert 彈出（不誤觸整卡 tap）**
   - 卸除按鈕立即卸除，裝備消失回背包
   - 出征中：底列按鈕隱藏，顯示「出征中 🔒」，整卡 tap 無反應
