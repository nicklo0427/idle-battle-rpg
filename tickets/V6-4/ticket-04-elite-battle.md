# V6-4 Ticket 04：菁英戰鬥系統

**狀態：** ✅ 完成
**版本：** V6-4
**依賴：** V6-3（BattleLogPlaybackModel）、V2-1（DungeonProgressionService）

**修改檔案：**
- `IdleBattleRPG/StaticData/EliteDef.swift`（新增）
- `IdleBattleRPG/Views/EliteBattleSheet.swift`（新增）
- `IdleBattleRPG/Views/AdventureView.swift`（FloorDetailSheet 擴充）
- `IdleBattleRPG/Services/DungeonProgressionService.swift`（markEliteCleared）

---

## 說明

每個地下城樓層對應一個菁英敵人，玩家可在 FloorDetailSheet 主動發起挑戰。
菁英戰鬥為即時單場戰鬥（非 AFK），使用 BattleLogPlaybackModel 現場播放。
首次擊敗菁英可解鎖下一區域並獲得額外獎勵。

## 菁英配置（共 16 個）

4 個區域 × 4 個樓層，每個菁英有固定的 hp / atk / def / reward。

| 區域 | 菁英數 | 推薦戰力範圍 |
|---|---|---|
| 荒野邊境 | 4 | 44–143 |
| 廢棄礦坑 | 4 | 165–396 |
| 古代遺跡 | 4 | 440–770 |
| 沉落王城 | 4 | 583–781 |

## EliteBattleSheet

```swift
struct EliteBattleSheet: View {
    let elite: EliteDef
    let appState: AppState
    var onEliteDefeated: (() -> Void)? = nil
    
    @State private var playbackModel = BattleLogPlaybackModel()
    @State private var battleResult: EliteBattleResult? = nil
}
```

- `onAppear` 立即呼叫 `runBattle()`，生成戰鬥事件並啟動播放
- 勝利後：`grantReward()` 入帳金幣 + 素材，呼叫 `markEliteCleared()`
- 使用 `BattleLogSheet` 呈現 ATB 動畫（與 DungeonBattleSheet 共用播放邏輯）

## FloorDetailSheet UI 入口

```swift
if let elite = EliteDef.find(floorKey: floor.key) {
    Section("地區菁英") { /* 菁英資訊卡片 */ }
    Button("挑戰菁英") { showEliteBattle = true }
        .disabled(heroStats.power < elite.minPowerRequired)
}
```

- 顯示菁英名稱、推薦戰力、首通解鎖說明
- 戰力不足時按鈕 disabled，顯示「建議戰力 X」

## 驗收標準

- [x] 每個地下城樓層的 FloorDetailSheet 顯示對應菁英資訊
- [x] 菁英戰鬥即時播放，ATB 動畫正常
- [x] 首通後解鎖下一區域（或下一樓層）
- [x] 獎勵正確入帳，成就觸發連動
- [x] `xcodebuild` 通過，無新警告
