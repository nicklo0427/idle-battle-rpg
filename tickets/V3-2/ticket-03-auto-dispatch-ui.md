# V3-2 Ticket 03：AdventureView 連續出征 UI

**狀態：** ✅ 完成

**依賴：** Ticket 01、Ticket 02

---

## 目標

提供兩個入口讓玩家設定和開關連續出征：
1. **樓層 contextMenu** — 長按樓層 row 設為連續出征目標（出征中或閒置皆可設定）
2. **出征中 Banner** — 快速開關連續出征、顯示目前目標

---

## 修改檔案

`IdleBattleRPG/Views/AdventureView.swift`

### 1. 新增 Query

```swift
@Query private var players: [PlayerStateModel]
private var player: PlayerStateModel? { players.first }
```

（AdventureView 目前已有 `@Query private var players`，確認有無即可）

### 2. 出征中 Banner 加入連續出征狀態（activeBannerSection）

在 Banner VStack 的倒數文字 + 進度條下方加入：

```swift
Divider()
    .padding(.vertical, 4)

HStack {
    Text("連續出征")
        .font(.caption)
        .foregroundStyle(.secondary)
    Spacer()
    if let player {
        Toggle("", isOn: Binding(
            get: { player.autoDispatchEnabled },
            set: { player.autoDispatchEnabled = $0 }
        ))
        .labelsHidden()
        .tint(.purple)
        .scaleEffect(0.8)
    }
}

if let player, player.autoDispatchEnabled, let floor = player.autoDispatchFloor {
    Text("🔄 結算後自動前往：\(floor.name) · \(AppConstants.DungeonDuration.displayName(for: player.autoDispatchDuration))")
        .font(.caption2)
        .foregroundStyle(.purple)
}
```

### 3. 樓層 row 加入 contextMenu（floorRow）

在 `.buttonStyle(.plain)` 後加入：

```swift
.contextMenu {
    if unlocked, let player {
        Button {
            player.autoDispatchFloorKey = floor.key
            player.autoDispatchDuration = AppConstants.DungeonDuration.short  // 預設 15 分鐘
            player.autoDispatchEnabled  = true
        } label: {
            Label("設為連續出征目標（15 分鐘）", systemImage: "arrow.clockwise")
        }

        ForEach(AppConstants.DungeonDuration.all, id: \.self) { duration in
            Button {
                player.autoDispatchFloorKey = floor.key
                player.autoDispatchDuration = duration
                player.autoDispatchEnabled  = true
            } label: {
                Label(
                    "連續出征：\(AppConstants.DungeonDuration.displayName(for: duration))",
                    systemImage: "clock"
                )
            }
        }
    }
}
```

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/AdventureView.swift` | ✏️ 修改（Banner 加 Toggle + 狀態列；floorRow 加 contextMenu） |

---

## 驗收標準

- [ ] 長按已解鎖樓層 → contextMenu 顯示「設為連續出征目標」選項
- [ ] 設定後出征中 Banner 出現 Toggle 與「🔄 結算後自動前往…」文字
- [ ] Toggle 關閉後文字消失
- [ ] 未出征時（無 Banner）contextMenu 仍可設定（設定後 Banner 不出現，但下次出征完成收下時會觸發）
- [ ] Build 無錯誤
