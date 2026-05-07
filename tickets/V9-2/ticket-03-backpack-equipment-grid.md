# V9-2 Ticket 03：背包裝備 Grid 卡片化

**狀態：** 📋 規劃中

**依賴：** 無（不需要圖片資源）

---

## 目標

CharacterView 背包分頁「裝備」子 Tab 目前是 List Row，
每行：`3pt 色條 + 部位 emoji + 裝備名 + 屬性 + diff badge + 箭頭圖示`。

改為 2 欄 LazyVGrid 卡片，視覺更直觀，同時解決
Grid 不支援 SwipeActions 的問題（改用 context menu）。

---

## 新 UI 設計

```
┌──────────────────────────────────────────────────┐
│  裝備（3 件未裝備）                              │
│  ◯普通  ★精良  ★★史詩  ★★★傳說             │
│                                                  │
│  ┌────────────────┐  ┌────────────────┐         │
│  │ 🗡️ 鐵製長劍    │  │ 🥋 精良皮甲 ★  │         │
│  │ ATK +12        │  │ DEF +10  HP +5 │         │
│  │ ▲ ATK +3       │  │ ▲ DEF +4       │         │
│  └────────────────┘  └────────────────┘         │
│  ┌────────────────┐  ...                        │
│  │ 💍 ...         │                             │
│  └────────────────┘                             │
└──────────────────────────────────────────────────┘
```

**卡片結構：**

```swift
VStack(alignment: .leading, spacing: 4) {
    // 頂列：部位 icon + 裝備名稱
    HStack {
        Text(item.slot.icon)
        Text(item.displayName)
            .font(.subheadline).fontWeight(.semibold)
            .foregroundStyle(item.rarity.hasAccent ? item.rarity.displayColor : .primary)
            .lineLimit(1).minimumScaleFactor(0.8)
        if item.isRolledBossWeapon {
            Text("✦").font(.caption2).foregroundStyle(.yellow)
        }
    }

    // 屬性列
    HStack(spacing: 6) {
        if item.atkBonus > 0 { Text("ATK +\(item.atkBonus)").font(.caption2).foregroundStyle(.red) }
        if item.defBonus > 0 { Text("DEF +\(item.defBonus)").font(.caption2).foregroundStyle(.blue) }
        if item.hpBonus  > 0 { Text("HP +\(item.hpBonus)").font(.caption2).foregroundStyle(.pink) }
    }

    // diff badge（若有差值）
    let diff = viewModel.equipDiff(candidate: item, equipped: equipments.filter { $0.isEquipped })
    if diff.hasAnyChange {
        diffBadge(diff)
    }
}
.padding(10)
.frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.overlay(alignment: .leading) {
    // 稀有度左側色條
    Capsule()
        .fill(item.rarity.hasAccent ? item.rarity.displayColor.opacity(0.8) : Color.secondary.opacity(0.35))
        .frame(width: 3)
}
// 點擊 → 穿上
.contentShape(RoundedRectangle(cornerRadius: 12))
.onTapGesture {
    viewModel.equip(item, context: context)
}
// 強化 / 拆解改用 context menu（SwipeActions 在 Grid 中不適用）
.contextMenu {
    if item.enhancementLevel < EnhancementDef.maxLevel {
        Button { pendingEnhanceItem = item } label: {
            Label("強化", systemImage: "hammer.fill")
        }
    }
    if EnhancementDef.disassembleRefund(defKey: item.defKey) != nil {
        Button(role: .destructive) { pendingDisassembleItem = item } label: {
            Label("拆解", systemImage: "trash.fill")
        }
    }
}
```

---

## 修改範圍

### `Views/CharacterView.swift`

**1. `backpackEquipmentTab` — 重構為 LazyVGrid**

```swift
@ViewBuilder
private var backpackEquipmentTab: some View {
    let unequipped = viewModel.unequippedItems(from: equipments)
    Section {
        if unequipped.isEmpty {
            // 空狀態（不變）
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(unequipped) { item in
                    backpackItemCard(item)
                }
            }
            .padding(.vertical, 4)
        }
    } header: {
        VStack(alignment: .leading, spacing: 4) {
            Text("裝備（\(unequipped.count) 件未裝備）")
            rarityLegendView
        }
    } footer: {
        Text("點擊穿上 · 長按可強化或拆解")
            .font(.caption)
    }
}
```

**2. `backpackItemRow` → `backpackItemCard`**

- 移除 SwipeActions（grid 不支援）
- 改用 `.contextMenu` 觸發強化 / 拆解 Alert
- 視覺改為 VStack 卡片（同上方 `backpackItemCard`）
- diff badge 保留

**3. Footer 文字更新**

`"點擊穿上 · 右滑強化 · 左滑拆解"` → `"點擊穿上 · 長按可強化或拆解"`

---

## 不改動範圍

- `backpackBasicMaterialTab`（通用素材 — 仍為 List）
- `backpackAreaMaterialTab`（區域素材 — 仍為 List）
- `rarityLegendView`（稀有度色彩說明條）
- `diffBadge` / `diffItem` helper
- Alert bindings（強化 / 拆解確認）

---

## 風險注意事項

**使用者習慣滑動操作，長按 contextMenu 發現性低：**
原本右滑強化、左滑拆解是可以探索的手勢；contextMenu 需要長按才觸發，不會自己被發現。
需確認：
- Footer 文字「點擊穿上 · 長按可強化或拆解」在畫面上清晰可見（字體不能太小、不能被 Section 蓋掉）
- 實際在模擬器上長按卡片，確認 contextMenu 出現時機正常（不需要長按太久）

**contextMenu action 觸發 Alert binding 需實測：**
`.contextMenu` 的 Button action 在 `@ViewBuilder` 環境內有時對 `@State` 更新有延遲，
`pendingEnhanceItem = item` 和 `pendingDisassembleItem = item` 需要實際操作確認 Alert 能彈出。

**大量裝備時滾動效能：**
`LazyVGrid` 本身是 lazy，但每個 cell 有 `.contextMenu` + `clipShape` + background layer 疊加，
在背包超過 20 件裝備時確認滾動仍然順暢（60fps）。

---

## 驗證方式

1. `xcodebuild` 通過，無新警告
2. 模擬器：
   - 背包 → 裝備：2 欄 grid 卡片，稀有度色條在左側
   - 點擊卡片 → 立即穿上（無需確認）
   - **長按卡片 → contextMenu 出現「強化」/「拆解」選項，操作不需要長按超過 0.5 秒**
   - **「強化」選項：觸發強化確認 Alert（金幣驗證不變）**
   - **「拆解」選項：觸發拆解確認 Alert（退還邏輯不變）**
   - Footer 文字「點擊穿上 · 長按可強化或拆解」清晰顯示
   - diff badge 正確顯示（換裝屬性差值）
   - 背包空時：空狀態圖示正常顯示
   - 背包有 20+ 件裝備時，滾動流暢無掉幀
