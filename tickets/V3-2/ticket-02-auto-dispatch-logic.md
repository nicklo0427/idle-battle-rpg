# V3-2 Ticket 02：AppState 連續出征觸發邏輯

**狀態：** ✅ 完成

**依賴：** Ticket 01（AutoDispatch 欄位存在）

---

## 目標

在 `claimAllCompleted()` 完成後，若玩家啟用了連續出征且無進行中地下城任務，
自動建立新的地下城任務。失敗時靜默處理（不彈 alert）。

---

## 修改檔案

`IdleBattleRPG/AppState.swift`

### 1. 確認 TaskCreationService 已注入

AppState 目前持有：
- `settlementService`, `claimService`, `progressionService`, `enhancementService`, `npcUpgradeService`

需補上：
```swift
private let taskCreationService: TaskCreationService
```

在 AppState `init(context:)` 中加入初始化（與其他 Service 同格式）：
```swift
self.taskCreationService = TaskCreationService(context: context)
```

### 2. 新增 tryAutoDispatch() 私有方法

```swift
private func tryAutoDispatch() {
    // 讀取 player
    guard let player = (try? modelContext.fetch(
        FetchDescriptor<PlayerStateModel>()
    ))?.first else { return }

    // 確認已啟用且有目標樓層
    guard player.autoDispatchEnabled,
          let floorKey = player.autoDispatchFloorKey,
          DungeonFloorDef.find(key: floorKey) != nil
    else { return }

    // 確認無進行中地下城任務
    let activeDungeon = (try? modelContext.fetch(
        FetchDescriptor<TaskModel>()
    ))?.filter { $0.kind == .dungeon && $0.status == .inProgress }
    guard activeDungeon?.isEmpty == true else { return }

    // 計算當前英雄戰力
    let equipped = (try? modelContext.fetch(
        FetchDescriptor<EquipmentModel>()
    ))?.filter { $0.isEquipped } ?? []
    guard let stats = HeroStatsService.compute(player: player, equipped: equipped) else { return }

    // 靜默建立任務（失敗不 alert）
    _ = taskCreationService.createDungeonTask(
        floorKey: floorKey,
        durationSeconds: player.autoDispatchDuration,
        heroStats: stats,
        player: player
    )
}
```

### 3. 在 claimAllCompleted() 末尾呼叫

```swift
func claimAllCompleted() {
    // ... 現有邏輯 ...
    tryAutoDispatch()   // ← 加在最後
}
```

---

## 設計備注

- **autoDispatch 不消耗 hasUsedFirstDungeonBoost**（該 flag 只觸發一次性加速邏輯，autoDispatch 跳過首次加速判斷）
- **失敗靜默**：例如金幣不足（地下城不花金幣，應不會發生）或 floorKey 失效，皆不彈錯誤
- **Hero 快照**：用呼叫當下的戰力建立任務（`snapshotPower`），符合現有地下城設計

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `AppState.swift` | ✏️ 修改（注入 TaskCreationService + tryAutoDispatch + hook） |

---

## 驗收標準

- [ ] 啟用連續出征 → 收下結算 → 自動出現新地下城倒數
- [ ] 未啟用時收下 → 不觸發自動出征
- [ ] `autoDispatchFloorKey == nil` 時收下 → 不觸發
- [ ] 已有進行中地下城時（不可能但防呆）→ 不重複建立
- [ ] Build 無錯誤
