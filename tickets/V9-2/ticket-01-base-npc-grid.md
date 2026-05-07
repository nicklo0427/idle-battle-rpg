# V9-2 Ticket 01：Base NPC Grid 卡片化

**狀態：** 📋 規劃中

**依賴：** V9-1 T04 NPC WebP 圖片已生成並放入 `Resources/`

---

## 目標

Base Tab 的 NPC 列表目前以 32×32 圓形小頭像 + 文字 List Row 呈現，
NPC 臉孔辨識度低。

改為 2 欄 LazyVGrid 卡片，頭像放大至 72×72，
讓玩家一眼就能看清楚每個 NPC 是誰，以及目前狀態。

---

## 新 UI 設計

```
┌─────────────────────────────────────────────────────┐
│  採集者營地                                           │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐                │
│  │  [頭像72×72] │  │  [頭像72×72] │                │
│  │   [忙碌徽章] │  │   [閒置徽章] │                │
│  │   伐木工     │  │   採礦工     │                │
│  │   採集中…   │  │   點擊派遣   │                │
│  └──────────────┘  └──────────────┘                │
│  ┌──────────────┐  ┌──────────────┐                │
│  │  [頭像72×72] │  │  [頭像72×72] │                │
│  │   採藥師     │  │   漁夫       │                │
│  └──────────────┘  └──────────────┘                │
└─────────────────────────────────────────────────────┘
```

**卡片結構（每個 NPC 卡片）：**

```swift
VStack(spacing: 6) {
    ZStack(alignment: .topTrailing) {
        Image(webp: "npc_\(def.actorKey)")
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        // 狀態徽章（右上角）
        statusBadge  // 忙碌：綠色圓點；閒置：無或灰點；未解鎖：lock.fill
    }

    VStack(spacing: 2) {
        Text(def.name)
            .font(.subheadline).fontWeight(.medium)
            .lineLimit(1)
        Text(statusCaption)  // "採集中" / "閒置" / "Lv.X 解鎖"
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}
.padding(10)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 14))
```

---

## 修改範圍

### `Views/BaseView.swift`

**1. `npcGatherSection()` — 採集者改 Grid**

```swift
@ViewBuilder
private func npcGatherSection() -> some View {
    // Section header
    Section {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(GathererNpcDef.all) { npc in
                npcGathererCard(def: npc, player: players.first)
                    .onTapGesture { selectedGathererDef = npc }
            }
        }
        .padding(.vertical, 4)
    } header: {
        Text("採集者營地")
    }
    npcFarmerCard()  // 農夫：單個卡片，佔一格
}
```

**2. `npcGathererCard()` — 新 grid 卡片 helper（替換 `npcGathererRow`）**

- 移除 HStack 布局，改為 VStack
- 頭像從 32×32 Circle 放大為 72×72 RoundedRectangle
- 狀態徽章改為右上角 overlay（綠色 / 灰色圓點）
- 倒數計時保留在卡片底部 caption（`TaskCountdown.remaining`）
- Tier badge 移至左上角 overlay

**3. `npcProduceSection()` — 生產者改 Grid**

```swift
@ViewBuilder
private func npcProduceSection() -> some View {
    Section {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            npcBlacksmithCard(player: players.first)
            npcChefCard(player: players.first)
            npcPharmacistCard(player: players.first)
        }
        .padding(.vertical, 4)
    } header: {
        Text("生產者小屋")
    }
}
```

**4. `npcShopSection()` — 商人保留 List Row（商人只有一個，Grid 單格太空）**

商人行保持現有 List Row 格式，不改為 grid。

**5. 新增共用 `npcStatusBadge(isBusy:)` helper**

```swift
private func npcStatusBadge(isBusy: Bool) -> some View {
    Circle()
        .fill(isBusy ? Color.green : Color.secondary.opacity(0.3))
        .frame(width: 10, height: 10)
        .padding(6)
}
```

---

## 保留不動

- 所有 Sheet 觸發邏輯（`selectedGathererDef`、`showCraftSheet` 等）完全不動
- `TierBadgeView`：改為左上角 overlay（位置換，元件本身不動）
- `npcFarmerSection` 的農夫：只有 1 個，放在採集 grid 最後一格（或單獨一欄），可與採集者共用同一 LazyVGrid

---

## 風險注意事項

**農夫卡片互動性不明顯：**
農夫卡片只顯示「農田 N 塊解鎖」，沒有視覺提示說明可以點擊。
建議在 caption 改為「農田 \(plots) 塊 · 點擊管理」，讓互動性更明確。

---

## 驗證方式

1. `xcodebuild` 通過，無新警告
2. 模擬器：
   - Base → 採集：2 欄 grid，4 個採集者 + 農夫頭像清晰可辨
   - 採集者忙碌時：右上角綠點亮起，卡片 opacity 0.85
   - 點擊任意採集者卡片：正常開啟 GathererDetailSheet
   - 點擊農夫卡片：正常開啟 FarmerDetailSheet
   - Base → 生產：2 欄 grid，鑄造師 / 廚師 / 製藥師各自卡片
   - Base → 商店：商人保持 List Row，不受影響
