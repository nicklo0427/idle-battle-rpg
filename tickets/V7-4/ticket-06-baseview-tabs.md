# V7-4 Ticket 06：BaseView 分頁重構（採集 / 生產 / 商店）

**狀態：** ✅ 完成

**依賴：** Ticket 02（農夫 section）、Ticket 04（製藥師 row）

---

## 目標

BaseView NPC 區域加入三分頁 segmented Picker，避免頁面過長。將 NPC 依功能分組：
- **採集**：採集者（4 人）+ 農夫（多塊田）
- **生產**：鑄造師 + 廚師 + 製藥師
- **商店**：商人

---

## Tab 定義

```swift
private enum BaseTab: String, CaseIterable {
    case gather  = "採集"
    case produce = "生產"
    case shop    = "商店"
}
```

---

## BaseView 改動

### State 新增

```swift
@State private var baseTab: BaseTab = .gather
@State private var showPharmacySheet = false
```

### NPC List 區域結構

```swift
// 原本的 NPC Section 改為：
Section {
    Picker("分頁", selection: $baseTab) {
        ForEach(BaseTab.allCases, id: \.self) { tab in
            Text(tab.rawValue).tag(tab)
        }
    }
    .pickerStyle(.segmented)
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets())
    .padding(.vertical, 4)
}

switch baseTab {
case .gather:
    npcGatherSection()
case .produce:
    npcProduceSection()
case .shop:
    npcShopSection()
}
```

---

## 各分頁 Section 組成

### `npcGatherSection()`

```swift
@ViewBuilder
private func npcGatherSection() -> some View {
    Section("採集者") {
        ForEach(GathererNpcDef.all, id: \.actorKey) { npc in
            npcGathererRow(npc: npc)
        }
    }
    npcFarmerSection()   // Ticket 02 新增
}
```

### `npcProduceSection()`

```swift
@ViewBuilder
private func npcProduceSection() -> some View {
    Section("生產") {
        npcBlacksmithRow(player: player)
        npcChefRow(player: player)
        npcPharmacistRow(player: player)   // 本 Ticket 新增
    }
}
```

### `npcShopSection()`

```swift
@ViewBuilder
private func npcShopSection() -> some View {
    Section("商店") {
        npcMerchantRow()
    }
}
```

---

## 製藥師 Row

### `npcPharmacistRow(player:)`

仿 `npcChefRow`，三態：

```swift
@ViewBuilder
private func npcPharmacistRow(player: PlayerStateModel?) -> some View {
    let pharmacistTask = viewModel.pharmacistTask(from: tasks)

    if let task = pharmacistTask {
        // 製藥中 — 顯示進度條 + 倒數 + 藥水名稱
        TaskProgressRow(
            task: task,
            icon: "cross.vial.fill",
            iconColor: .purple,
            title: "製藥師",
            subtitle: task.definitionKey.isEmpty ? "製藥中" :
                      (PotionDef.find(task.definitionKey)?.name ?? "製藥中"),
            currentTime: currentTime
        )
    } else {
        // 閒置 — 點擊開啟 PharmacySheet
        Button {
            showPharmacySheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "cross.vial.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("製藥師")
                        .fontWeight(.semibold)
                    Text("閒置中，點擊選擇配方")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
```

### Sheet 掛載

```swift
.sheet(isPresented: $showPharmacySheet) {
    PharmacySheet(
        viewModel: viewModel,
        player: player,
        inventory: inventory,
        isPresented: $showPharmacySheet
    )
}
```

---

## 注意事項

- 切換 tab 時不需要重置 sheet 狀態（各 sheet 的 `isPresented` 獨立）
- 製藥師升級入口：`npcPharmacistRow` 在閒置狀態下加入「升級」按鈕（仿現有採集者升級模式），或沿用 `NpcUpgradeSheet`
- 農夫升級入口：在 `npcFarmerSection()` 的底部顯示升級提示（見 Ticket 02）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] BaseView NPC 區域顯示「採集 / 生產 / 商店」Segmented Picker
- [ ] 採集 tab：顯示 4 位採集者 + 農夫段落
- [ ] 生產 tab：顯示鑄造師 + 廚師 + 製藥師
- [ ] 商店 tab：顯示商人
- [ ] 切換 tab 流暢，不影響進行中任務的顯示
- [ ] 製藥師閒置 → 點擊 → 開啟 PharmacySheet
- [ ] 製藥師忙碌 → 顯示進度條
- [ ] 現有採集者 / 鑄造師 / 廚師 / 商人功能不受影響
