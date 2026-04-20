# V6-3 Ticket 07：BattleEvent 新增 skillKey 欄位

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** T05（新增的狀態效果技能 case 也需帶 skillKey）

**修改檔案：**
- `IdleBattleRPG/Services/BattleLogGenerator.swift`

---

## 目的

讓播放模型（T08）和未來 UI 能夠識別「哪個技能在哪個時刻觸發」，
以便追蹤個別技能的冷卻進度。

---

## 實作

### BattleEvent 新增欄位

```swift
/// T07：施放的技能 key（僅 .skill 事件且為真實技能施放時有效，其餘為 nil）
let skillKey: String?
```

`init(...)` 新增參數（有預設值，所有舊 caller 自動相容）：

```swift
init(..., skillKey: String? = nil) {
    // ...
    self.skillKey = skillKey
}
```

### runCombatCore 內所有技能觸發點

共 10 個 `onEvent?(BattleEvent(type: .skill, ...))` 呼叫，
全部加上 `skillKey: skill.key`：

| ActiveEffect case | 對應修改 |
|---|---|
| `.damage` | `skillKey: skill.key` |
| `.heal` | `skillKey: skill.key` |
| `.damageAndHeal` | `skillKey: skill.key` |
| `.heroAtkUp` | `skillKey: skill.key` |
| `.enemyAtkDown` | `skillKey: skill.key` |
| `.damageAndEnemyAtkDown` | `skillKey: skill.key` |
| `.damageAndBurn`（T05）| `skillKey: skill.key` |
| `.damageAndPoison`（T05）| `skillKey: skill.key`（兩個分支各一次）|
| `.stunAndDamage`（T05）| `skillKey: skill.key` |
| `.damageAndWeaken`（T05）| `skillKey: skill.key` |

### 不帶 skillKey 的 .skill 事件

出征開場提示「帶著…踏入地下城」屬於非技能觸發事件，`skillKey` 維持預設 `nil`。

### EliteBattleEngine

`EliteBattleEngine` 自行建立 `BattleEvent`，不傳 `skillKey`，
使用預設 `nil`，無編譯錯誤，不顯示 CD 面板。

---

## 驗收標準

- [x] 所有 `.skill` 事件（由技能觸發）的 `skillKey` 非 nil，等於觸發技能的 `skill.key`
- [x] 出征開場提示事件（`type == .skill`，`skillKey == nil`）不觸發 CD 記錄
- [x] 其他類型事件（`.attack`、`.damage` 等）`skillKey == nil`
- [x] `EliteBattleEngine` 建立 BattleEvent 時不傳 skillKey，無編譯錯誤
- [x] `xcodebuild` 通過，無新警告
