# V9-2 Ticket 05：探索分頁地區卡片視覺升級

**狀態：** 📋 規劃中

**依賴：** V9-1 T03 region WebP 圖片（`region_wildland/mine/ruins/sunken.webp`）已生成

---

## 目標

探索分頁的地區標題列（`regionHeader`）目前是 40×40 縮圖 + 文字橫排，
圖像在 List Row 中佔比太小，視覺感不足。

改為全寬橫幅卡片（Banner Card）：
地區圖片作為卡片背景鋪滿，區域名稱 + 解鎖狀態文字以漸層遮罩疊加在圖片上，
讓每個地區有「進入一個世界」的感覺。

---

## 新 UI 設計

```
┌──────────────────────────────────────────────┐
│  [  地區圖片，全寬，高度 ~130pt  ]            │
│                                              │
│                              🔒 通關前一區 Boss│  ← 未解鎖時
│   荒野邊境                                   │  ← 地區名稱（左下）
│   1/4 層首通                                 │  ← 進度（左下副標）
│  ─────────────────────────── ▼ / ▲           │  ← 展開/收合
└──────────────────────────────────────────────┘
  ↓ 展開後樓層列表（不變）
  ┌──────────────────────────────────────────────┐
  │ [30px怪] 第 1 層 · 推薦 120 · 勝率 68%  ▶ │
  │ [boss圖] 第 4 層 Boss · 推薦 400        ▶ │
  └──────────────────────────────────────────────┘
```

**Banner Card 程式碼結構：**

```swift
private func regionBannerCard(
    region: DungeonRegionDef,
    unlocked: Bool,
    completed: Bool,
    expanded: Bool
) -> some View {
    ZStack(alignment: .bottomLeading) {
        // 背景：地區圖片
        Image(webp: "region_\(region.key)")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .clipped()
            .opacity(unlocked ? 1.0 : 0.25)

        // 漸層遮罩（底部文字底板）
        LinearGradient(
            colors: [.black.opacity(0.0), .black.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )

        // 文字覆層
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(region.name)
                    .font(.headline).fontWeight(.bold)
                    .foregroundStyle(.white)
                if unlocked {
                    let clearedCount = /* 已首通層數 */
                    Text("\(clearedCount) / \(region.floors.count) 層首通")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer()
            if !unlocked {
                // 未解鎖：右側顯示解鎖條件
                Label(unlockCaption, systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            } else if completed {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .contentShape(RoundedRectangle(cornerRadius: 14))
}
```

---

## 修改範圍

### `Views/AdventureView.swift`

**1. `regionListSection` — 改用 `regionBannerCard`**

```swift
private var regionListSection: some View {
    // 移除 Section 包裝，改用直接 VStack 卡片（卡片本身已有圓角背景）
    ForEach(DungeonRegionDef.all, id: \.key) { region in
        let unlocked  = ...
        let completed = ...
        let expanded  = expandedRegionKey == region.key

        VStack(spacing: 0) {
            Button {
                guard unlocked else { return }
                expandedRegionKey = expanded ? nil : region.key
            } label: {
                regionBannerCard(region: region, unlocked: unlocked,
                                 completed: completed, expanded: expanded)
            }
            .buttonStyle(.plain)

            if unlocked && expanded {
                // 樓層列表：保留現有 floorRow，包在圓角背景內
                VStack(spacing: 0) {
                    ForEach(region.floors) { floor in
                        floorRow(floor: floor, region: region)
                        if floor != region.floors.last {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(UnevenRoundedRectangle(
                    bottomLeadingRadius: 14, bottomTrailingRadius: 14
                ))
            }
        }
        // 整組卡片 + 展開列表有 shadow/spacing
        .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
        .padding(.horizontal, 4)
    }
}
```

**2. `regionHeader()` — 完全移除**（被 `regionBannerCard` 取代）

**3. `regionUnlockLabel()` — 邏輯搬至 `regionBannerCard` 內部**

**4. `floorRow()` — 不動**（只是容器外觀從 Section 改為 VStack，floorRow 本身邏輯和視覺不變）

**5. `Section` 結構調整**

原本：每個地區是一個 `Section { button header + forEach floors }`
改為：`Section { VStack { bannerCard + floorList } }`（保留 Section 結構以維持 List 間距），
或直接拿掉 Section 包裝，用 VStack 加 `.listRowInsets(.zero)` 讓卡片全寬鋪滿。

> 建議用 `.listRowInsets(.init())` + `.listRowBackground(Color.clear)` 達到全寬效果，
> 不需要離開 List 架構。

---

## 已解鎖進度計算（新增 ViewModel helper）

`regionClearedFloorCount(regionKey:service:) -> Int`
已在 `AdventureViewModel` 有 `isFloorCleared()`，加一個 aggregate helper：

```swift
func clearedFloorCount(regionKey: String, service: DungeonProgressionService) -> Int {
    guard let region = DungeonRegionDef.find(key: regionKey) else { return 0 }
    return region.floors.filter {
        isFloorCleared(regionKey: regionKey, floorIndex: $0.floorIndex, service: service)
    }.count
}
```

放在 `AdventureViewModel.swift`，無副作用。

---

## 不改動範圍

- `floorRow()` 所有邏輯
- `FloorDetailSheet`（選層後的出發頁）
- `activeBannerSection`（出征中橫幅）
- `DungeonRegionDef` 靜態資料

---

## 風險注意事項

**實作順序：ViewModel helper 要先加，再動 View**
`regionBannerCard` 裡用到 `clearedFloorCount(regionKey:service:)`，
若先改 View 再加 ViewModel，會無法編譯。正確順序：
1. 先在 `AdventureViewModel.swift` 加 `clearedFloorCount()` helper
2. 再改 `AdventureView.swift`

**圖片資源必須先到位（V9-1 T03 依賴）：**
Banner card 使用 `Image(webp: "region_\(region.key)")`，
需要 `region_wildland.webp`、`region_mine.webp`、`region_ruins.webp`、`region_sunken.webp` 存在。

實作前先確認：
```bash
ls IdleBattleRPG/Resources/region_*.webp
```
圖片未到位前先跳其他 ticket。

**圖片檔案大小影響開分頁的流暢度：**
4 張 130pt 全寬卡片在 List 裡不是 lazy 載入，分頁一開就同時解碼 4 張圖。
建議圖片壓縮至 150KB 以下、尺寸 750×260px（@2x）。
圖片過大可用 Instruments → Core Animation 查看 hitch。

**未解鎖地區的視覺語意：**
25% opacity 圖片在部分使用者眼中可能像「載入中」而非「鎖定」。
確認右側 `lock.fill` icon + 解鎖條件文字夠顯眼。
若效果不夠清晰，可在 opacity 之外加 `.grayscale(1.0)` 強化鎖定感。

**List row insets 必須設定才能全寬：**
卡片要鋪滿 List 寬度，需在每個 VStack 行加：
```swift
.listRowInsets(.init())
.listRowBackground(Color.clear)
```
漏掉會有左右 padding，卡片看起來像縮進去。

---

## 驗證方式

1. 確認 `region_wildland/mine/ruins/sunken.webp` 存在於 `Resources/`，且各檔案 < 150KB
2. 先加 `AdventureViewModel.clearedFloorCount()`，確認編譯通過，再改 View
3. `xcodebuild` 通過，無新警告
4. 模擬器：
   - 探索 Tab：4 個地區各自顯示 130pt 高橫幅卡片，圖片清晰鋪滿（無左右 padding）
   - 已解鎖地區：全彩圖 + 地區名稱 + 首通進度（X/4 層）+ 展開箭頭
   - **未解鎖地區：圖片明顯是「鎖定」狀態（不像載入中），lock icon + 解鎖條件文字可辨識**
   - 點擊已解鎖地區 → 樓層列表展開，floorRow 正常顯示
   - 點擊已展開地區 → 收合
   - 點擊樓層 → FloorDetailSheet 正常開啟
   - 出征中橫幅不受影響
   - 開啟探索 Tab 時滾動流暢（4 張圖同時載入無明顯頓感）
