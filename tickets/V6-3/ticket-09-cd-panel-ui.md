# V6-3 Ticket 09：技能 CD 面板 UI + Callers 傳入 activeSkills

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T08（`BattleLogPlaybackModel.skillCooldownFractions`）

**修改檔案：**
- `IdleBattleRPG/Views/BattleLogSheet.swift`
- `IdleBattleRPG/Views/AdventureView.swift`
- `IdleBattleRPG/Views/DungeonBattleSheet.swift`

---

## 目的

在 `BattleLogSheet` 的 HP/ATB 條下方顯示技能 CD 進度條列，
讓玩家在觀看戰鬥過程時清楚看到每個技能的冷卻狀態。
同時讓 AFK 查看（AdventureView）與即時地下城戰鬥（DungeonBattleSheet）
都能將裝備技能傳入播放模型以啟用 CD 追蹤。

---

## BattleLogSheet — 技能 CD 面板

### body 插入位置

在 `hpBarsView` 之後、原有 `Divider()` 之前：

```swift
if !model.skillCooldownFractions.isEmpty {
    skillCooldownPanel
    Divider()
}
Divider()
```

### skillCooldownPanel

```swift
private var skillCooldownPanel: some View {
    VStack(spacing: 4) {
        ForEach(model.skillCooldownFractions, id: \.key) { item in
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(item.fraction >= 1.0 ? Color.orange : Color.secondary)
                    .frame(width: 14)
                Text(item.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 48, alignment: .leading)
                    .lineLimit(1)
                ProgressView(value: item.fraction, total: 1.0)
                    .tint(item.fraction >= 1.0 ? Color.orange : Color.gray)
                    .frame(maxWidth: .infinity)
                    .animation(.linear(duration: 0.1), value: item.fraction)
                Text(item.fraction >= 1.0 ? "就緒" : "CD")
                    .font(.caption2)
                    .foregroundStyle(item.fraction >= 1.0 ? Color.orange : Color.secondary)
                    .frame(minWidth: 24, alignment: .trailing)
            }
        }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color(.systemGroupedBackground))
}
```

---

## AdventureView — startBattleLogModel() 傳入 activeSkills

```swift
let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

appState.battleLogPlayback.start(
    events:           events,
    fromBattleIndex:  fromIdx,
    taskTotalBattles: totalBattles,
    taskId:           task.id,
    activeSkills:     activeSkills,      // ← 新增
    nextBatchProvider: { ... }
)
```

---

## DungeonBattleSheet — startNextBattle() 傳入 activeSkills

```swift
let activeSkills = task.snapshotSkillKeys.compactMap { SkillDef.find(key: $0) }

playbackModel.start(
    events:           events,
    fromBattleIndex:  currentBattleIndex,
    taskTotalBattles: totalBattles,
    taskId:           task.id,
    activeSkills:     activeSkills,      // ← 新增
    onBattleEnded:    { ... }
)
```

---

## 不受影響的 Callers

`EliteBattleSheet` 呼叫 `playbackModel.start()` 時不傳 `activeSkills`（使用預設 `[]`），
`skillCooldownFractions` 恆為空，CD 面板不顯示。

---

## 視覺規格

| 狀態 | bolt 圖示顏色 | 進度條顏色 | 標籤 |
|---|---|---|---|
| 就緒（fraction ≥ 1.0）| `.orange` | `.orange` | 就緒 |
| 冷卻中（fraction < 1.0）| `.secondary` | `.gray` | CD |

---

## 驗收標準

- [x] AFK「查看過程」Sheet 顯示技能 CD 列，進度條隨每次 `.attack` 事件推進
- [x] 技能觸發後 CD 條降至接近 0，再逐漸回升至「就緒」橙色
- [x] `EliteBattleSheet`（不傳 activeSkills）不顯示 CD 列
- [x] DungeonBattleSheet 即時戰鬥同樣顯示 CD 列
- [x] `xcodebuild` 通過，無新警告
