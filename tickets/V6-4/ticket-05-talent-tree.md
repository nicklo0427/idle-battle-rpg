# V6-4 Ticket 05：天賦樹系統

**狀態：** ✅ 完成
**版本：** V6-4
**依賴：** V6-1 職業系統、V6-2 T09 技能點系統

**修改檔案：**
- `IdleBattleRPG/StaticData/TalentDef.swift`（新增）
- `IdleBattleRPG/Services/TalentService.swift`（新增）
- `IdleBattleRPG/Views/CharacterView.swift`（天賦 UI 整合至技能 Tab）

---

## 說明

每個職業有 2 條天賦路線，路線間互斥（投入一條後，另一條鎖定）。
每條路線 5 個節點，節點需依序解鎖（前置條件），使用技能點投入。

## 結構

**8 條路線（每職業 2 條）：**

| 職業 | 路線 A | 路線 B |
|---|---|---|
| 劍士 | 狂戰士（sw_berserker）| 鐵壁（sw_ironwall）|
| 弓手 | 精準（ar_precision）| 毒箭（ar_poison）|
| 法師 | 爆發（mg_burst）| 護盾（mg_barrier）|
| 聖騎士 | 聖光（pl_holy）| 審判（pl_judgment）|

**節點等級上限：**

| 位置 | 節點 0–1 | 節點 2–3 | 節點 4 |
|---|---|---|---|
| maxLevel | 3 | 2 | 1 |

## TalentService 核心方法

```swift
func canInvest(nodeKey: String, for player: PlayerStateModel) -> Bool
func investPoint(nodeKey: String, for player: PlayerStateModel) throws
func resetAllTalents(player: PlayerStateModel) throws        // 消耗 500 金幣
func isRouteLocked(_ route: TalentRouteDef, for player: PlayerStateModel) -> Bool
```

- 前置條件：節點 N 需先有 N-1 節點的投入點數
- 路線互斥：同職業兩條路線只能選一條
- 重置：退回所有天賦點，扣除 500 金幣

## CharacterView UI（整合至技能 Tab 被動 Section）

- 顯示可用天賦點 badge
- 每條路線展開式卡片，顯示 5 個節點
- 已鎖定路線顯示 `lock.fill` 圖示
- 節點展開後顯示：效果說明（逐級）、戰力預覽差值、「投入 / 已最高」按鈕
- 天賦重置按鈕（confirmationDialog 確認，顯示金幣費用）

## 驗收標準

- [x] 路線互斥：投入 A 路線後 B 路線顯示鎖定
- [x] 前置條件：節點未投入前，後續節點按鈕 disabled
- [x] 重置後技能點退回，金幣扣除，路線解鎖
- [x] 天賦效果正確套用至 HeroStats（戰力計算）
- [x] `xcodebuild` 通過，無新警告
