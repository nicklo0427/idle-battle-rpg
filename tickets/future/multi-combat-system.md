# Future：多人戰鬥系統（4v4 同場制）

**狀態：** 📋 設計規劃中，尚未排入版本

**預計拆分：**
- **Phase 1（獨立版本）** — 多敵人同場（1 英雄 vs 最多 4 敵）
- **Phase 2（後端版本）** — 多英雄組隊（自己 + 傭兵 + 好友，最多 4 人）

---

## Phase 1 — 多敵人同場

### 設計

- 一場戰鬥最多 4 個敵人同時在場
- 英雄 ATB 滿後，自動選擇目標攻擊（優先 HP 最低或固定第一個）
- 敵人各自有獨立 ATB，各自對英雄行動
- 所有敵人死亡 = 英雄勝；英雄死亡 = 失敗
- 純 AFK，全系統自動控制目標選擇

### 靜態資料變更

`DungeonFloorDef` 新增敵方陣容定義（目前只有單一敵人）：

```swift
// 目前
var commonEnemyNames: [String]    // 隨機從中選一個名稱
var bossName: String?

// 未來
struct EnemyGroupDef {
    var enemies: [EnemyDef]       // 1–4 個敵人
}

struct EnemyDef {
    var name: String
    var hpMultiplier: Double      // 相對於 recommendedPower 的 HP 倍數
    var atkMultiplier: Double
}
```

### 引擎變更

**`BattleLogGenerator`**
- `runCombatCore()` 需要支援多個 `EnemyState`
- ATB loop 改為 N+1 個行動者（英雄 + N 敵）
- 英雄攻擊需指定目標 enemy index
- `BattleEvent` 新增 `targetIndex: Int?`（攻擊對象）

**`BattleLogPlaybackModel`**
- `currentEnemyHp` → `enemyHpArray: [Int]`
- `enemyATBProgress` → `enemyATBProgresses: [Double]`
- `enemyMaxHp` → `enemyMaxHpArray: [Int]`

**`DungeonSettlementEngine`**
- 多敵人戰鬥模擬（呼叫更新後的 `runCombat()`）

### UI 變更

**`BattleLogSheet`**
- 敵方區域改為最多 4 個 HP 條堆疊（或橫向排列）
- 死亡的敵人 HP 條變灰 / 縮小
- BattleEvent 的描述需加入「攻擊了 [目標名]」

### 待確認設計問題

- [ ] 英雄技能（AoE vs 單體）：目前所有技能都是單體，需決定哪些技能打全體
- [ ] 敵人目標選擇：隨機？固定打英雄？或輪流？
- [ ] 多敵人是否改變樓層難度（recommendedPower 如何計算）
- [ ] 套用範圍：全部樓層改，還是只有 F3 / F4 有多敵人

---

## Phase 2 — 多英雄組隊（後端版本）

**前提條件：** 需要後端 API、帳號系統、配對伺服器

### 設計概覽

- 英雄（玩家自己）+ 本地傭兵 + 好友邀請，最多 4 人
- 傭兵系統：遊戲內招募、有等級和職業、本地管理
- 好友系統：需後端（與好友同步角色快照）
- 各成員各自有 ATB、HP、技能，全部 AFK 自動控制

### 拆分建議

```
Phase 2a（本地）：傭兵系統
  - NpcMercenaryDef 靜態定義（職業 / 技能 / 升級）
  - 本地招募 / 管理 UI
  - 戰鬥引擎支援多英雄（不需後端）

Phase 2b（後端）：好友邀請
  - 帳號系統（Apple Sign In 或自建）
  - 角色快照同步 API
  - 組隊配對介面
```

### 待確認設計問題

- [ ] 傭兵如何招募（金幣購買？任務解鎖？）
- [ ] 傭兵是否有成長系統（升等 / 裝備）
- [ ] 好友戰鬥是即時同步還是異步（對方角色快照加入隊伍）
- [ ] AFK 多英雄的 AI 策略（誰保護英雄、技能觸發優先順序）

---

## 影響範圍總覽（Phase 1）

| 層級 | 檔案 | 變更類型 |
|---|---|---|
| StaticData | `DungeonFloorDef` / `DungeonRegionDef` | 新增敵方陣容結構 |
| Model | `BattleEvent` | 新增 `targetIndex` |
| Engine | `BattleLogGenerator` | ATB loop 多行動者 |
| Engine | `DungeonSettlementEngine` | 多敵人模擬 |
| Observable | `BattleLogPlaybackModel` | 多敵人 HP / ATB 陣列 |
| View | `BattleLogSheet` | 多敵人 HP 條 UI |
