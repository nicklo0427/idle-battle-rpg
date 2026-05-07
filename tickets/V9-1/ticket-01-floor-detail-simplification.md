# V9-1 Ticket 01：FloorDetailSheet 簡化

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

FloorDetailSheet 目前 7 個 Section 資訊量過多，出發按鈕位置太深。
重新排列為「操作區置頂、參考資訊收合」的結構，降低視覺複雜度。

---

## 新排列順序（最終版）

| 位置 | 區塊 | 預設狀態 |
|---|---|---|
| ① | floorInfoSection（Boss 名稱 + 最佳記錄，無已首通/推薦戰力）| 始終可見（無內容時隱藏）|
| ② | consumableSection（消耗品）| 始終可見 |
| ③ | launchSection（出發）| 始終可見 |
| ④ | unlockAndEliteSection（首通解鎖 + 菁英，合併）| 始終可見 |
| ⑤ | DisclosureGroup「掉落物」| **預設收合** |

> **戰力評估完全移除。**

---

## 修改細節

### `Views/AdventureView.swift` — FloorDetailSheet

#### State 變數

新增 `infoExpanded`，移除 `unlockExpanded`、`powerExpanded`（不再需要）：
```swift
@State private var infoExpanded = false
```

#### floorInfoSection 修改

移除「已首通」Badge 和「推薦戰力」文字。保留 Boss 名稱（Boss 樓層）和最佳記錄（有記錄時）。
若無 Boss 且無最佳記錄，Section 不顯示（加 `if` 判斷）。

```swift
private var floorInfoSection: some View {
    let hasBoss = floor.isBossFloor && floor.bossName != nil
    let hasBest = appState.progressionService.getBest(floorKey: floor.key) != nil
    if hasBoss || hasBest {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                if floor.isBossFloor, let bossName = floor.bossName {
                    Label(bossName, systemImage: "crown.fill")
                        .font(.subheadline).foregroundStyle(.orange)
                }
                if let best = appState.progressionService.getBest(floorKey: floor.key) {
                    Label("最佳：\(best.wins) 勝 / 💰\(best.gold)", systemImage: "trophy.fill")
                        .font(.caption).foregroundStyle(.yellow)
                }
            }
        }
    }
}
```

#### body 重排（List 內）

```swift
List {
    floorInfoSection         // Boss 名稱 + 最佳記錄（可能隱藏）
    consumableSection
    launchSection
    unlockAndEliteSection    // 新合併 Section（見下）

    Section {
        DisclosureGroup("掉落物", isExpanded: $infoExpanded) {
            // 原 dropTableSection 內容（ForEach + 金幣行）
        }
    }
}
```

#### unlockAndEliteSection（新，取代原 eliteSection + 首通解鎖 DisclosureGroup）

首通解鎖永遠在頂部，菁英挑戰若有才顯示，合併在同一個 Section：

```swift
@ViewBuilder
private var unlockAndEliteSection: some View {
    Section {
        // 首通解鎖（永遠顯示）
        HStack {
            Text(floor.unlocksSlot.icon + " \(floor.unlocksSlot.displayName)配方")
            Spacer()
            if isCleared {
                Text("已解鎖").font(.caption).foregroundStyle(.green)
            } else {
                Text("未解鎖").font(.caption).foregroundStyle(.secondary)
            }
        }

        // 菁英挑戰（只有 Boss 樓層才有）
        if let elite = EliteDef.find(floorKey: floor.key) {
            HStack {
                Text(elite.name).fontWeight(.semibold)
                Spacer()
                if eliteCleared {
                    Label("已擊敗", systemImage: "star.fill")
                        .font(.caption).foregroundStyle(.yellow)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("需 \(elite.minPowerRequired) 戰力")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            if eliteCleared {
                Label("菁英已擊敗，獎勵已領取", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            } else if let power = heroStats?.power, power >= elite.minPowerRequired {
                Button { showEliteBattle = true } label: {
                    Label("挑戰菁英", systemImage: "shield.lefthalf.filled")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(.orange).disabled(isBusy)
            } else {
                Label("戰力不足（需 \(elite.minPowerRequired)）", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }
}
```

---

## 清理

- 移除 `eliteSection` @ViewBuilder（由 `unlockAndEliteSection` 取代）
- 移除 body 裡的「首通解鎖」DisclosureGroup Section
- 移除 body 裡的「戰力評估」DisclosureGroup Section
- 移除 `@State private var unlockExpanded`、`@State private var powerExpanded`

---

## 修改檔案

- `Views/AdventureView.swift`（FloorDetailSheet 內部結構）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 一般樓層（非 Boss）：Sheet 頂部無 Boss 名稱，無「已首通」和「推薦戰力」
- [ ] Boss 樓層：顯示 Boss 名稱；有打過時顯示最佳記錄
- [ ] 首通解鎖和菁英合併在同一個 Section，首通解鎖行永遠可見
- [ ] 一般樓層（無菁英）：Section 只顯示首通解鎖一行
- [ ] 掉落物預設收合，點擊可展開
- [ ] 戰力評估從 Sheet 中完全消失
- [ ] 已出征中時，launchSection 正確顯示出征中 Banner
