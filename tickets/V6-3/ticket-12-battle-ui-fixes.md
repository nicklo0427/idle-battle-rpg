# V6-3 Ticket 12：戰鬥介面修正 + ATB carry-over + CD 平滑動畫

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T08（CD 追蹤）、T09（CD 面板 UI）、T11（技能從冷卻開始）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogPlaybackModel.swift`
- `IdleBattleRPG/Views/DungeonBattleSheet.swift`
- `IdleBattleRPG/Views/BattleLogSheet.swift`
- `IdleBattleRPG/Views/CharacterView.swift`
- `IdleBattleRPG/Views/CraftSheet.swift`
- `IdleBattleRPG/Views/SettlementSheet.swift`
- `IdleBattleRPG/StaticData/ClassDef.swift`

---

## 問題清單

### Bug 1：場次計數顯示

`DungeonBattleSheet.startNextBattle()` 傳入 `taskTotalBattles: totalBattles`，導致 BattleLogSheet 顯示「第 N 場 / 共 M 場」計數。

**修正：** `taskTotalBattles: 0`，battleLabel 邏輯回傳 nil，計數消失。  
**延伸：** 將 `battleLabel` computed property 與其對應的 UI 顯示 block 從 `BattleLogSheet` 完全移除，保持程式碼精簡。

---

### Bug 2：敵方攻擊事件系統性遺失（浮點數精度）

**根因：** `for _ in 0..<steps` 迴圈中以 `elapsed += stepDur` 累加，`stepDur = total / steps`。  
迴圈結束後 `elapsed` 因 FP 捨入可能略小於 `enemyTime`（如 `1.9599999 < 1.96`），`enemyATBProgress >= 1.0` 永不觸發，`damageEvent` 被跳過但 `i += 2` 仍消耗。  
結果：每次敵方攻擊事件系統性丟棄，英雄仍扣血但 log 無顯示。

**修正：** 迴圈後補 FP 安全補齊：

```swift
if !heroShown  { snapZero(hero: true);  currentBattleEvents.append(attackEvent);  displayedCount += 1 }
if !enemyShown { snapZero(enemy: true); currentBattleEvents.append(damageEvent);  displayedCount += 1 }
i += 2
```

---

### Bug 3：技能 CD 條戰鬥開始顯示「就緒」

**根因：** T08 `updateSkillCooldowns()` 對尚未觸發的技能回傳 `fraction = 1.0`。T11 改為「從冷卻開始」後行為不一致。

**修正 1** — `start()` 初始化：`fraction: 1.0` → `fraction: 0.0`  
**修正 2** — `updateSkillCooldowns()` else 分支：
```swift
// 修改前
fraction = 1.0
// 修改後（T11 連動）
fraction = min(1.0, t / Double(skill.cooldownSeconds))
```

---

### 追加 1：CD 條動畫平滑化（不再只在攻擊結束後跳動）

`updateSkillCooldowns()` 新增 `extraTime: Double = 0` 參數，讓動畫迴圈中每一 step 都能即時更新 CD 進度。

為防止 commit 後跳回（`accumulatedCombatTime += heroTime` 比動畫最高點小），在 ATB 動畫迴圈中上限鎖定：
```swift
updateSkillCooldowns(extraTime: min(elapsed, heroTime))
```

---

### 追加 2：ATB carry-over（英雄攻擊後讀條不歸零）

**問題：** 英雄出手後，ATB 條歸零等待敵方攻擊完畢才開始下一輪填充，視覺上有停頓感。

**設計：** `heroCarryOver: Double`（per-session 局部變數）記錄英雄出手後到敵方完成之間已充入下一輪的進度。

- 動畫起點：`heroATBProgress = heroCarryOver`（瞬間設定，`disablesAnimations`）
- 英雄觸發時刻：`heroFiringAt = heroTime * (1 - heroCarryOver)`
- 英雄出手後立即開始下一輪填充：`heroATBProgress = (elapsed - heroFiringAt) / heroTime`
- 結束後計算：`heroCarryOver = max(0, enemyTime - heroFiringAt).truncatingRemainder(dividingBy: heroTime) / heroTime`

---

### 追加 3：SF Symbol 修正

兩個無效 SF Symbol 名稱導致 runtime 警告：
- `skull.fill` → `skull`（`.fill` 變體不存在）
- `sword` → `figure.fencing`（SF Symbols 無 `sword`，改用 iOS 16+ `figure.fencing`）

涉及檔案：`BattleLogSheet`、`DungeonBattleSheet`、`CraftSheet`、`SettlementSheet`、`CharacterView`、`ClassDef`。

---

## 驗收標準

- [x] 地下城戰鬥不顯示場次計數
- [x] 戰鬥 log 中出現「反擊 → 受到 X 傷害」橙色事件
- [x] CD 條在戰鬥開始時為 0，隨時間平滑填充至「就緒」
- [x] 英雄出手後 ATB 條立即開始填充（不等敵方）
- [x] 被敵方攻擊時 CD 條不倒退
- [x] 無 SF Symbol 警告（skull / figure.fencing）
- [x] `xcodebuild` 通過，無新警告
