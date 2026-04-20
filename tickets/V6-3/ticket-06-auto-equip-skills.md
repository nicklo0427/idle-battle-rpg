# V6-3 Ticket 06：升等時自動裝備新解鎖技能

**狀態：** ✅ 完成
**版本：** V6-3
**依賴：** 無（獨立改動）

**修改檔案：**
- `IdleBattleRPG/Services/CharacterProgressionService.swift`

---

## 問題背景

玩家升級後，技能依 `SkillDef.requiredLevel` 解鎖，但原本實作中
`CharacterProgressionService` 只遞增 `availableSkillPoints`，
不自動將新技能裝入 `equippedSkillKeysRaw`。

若玩家未主動進角色頁手動裝備，出征時 `task.snapshotSkillKeysRaw = ""`，
`BattleLogGenerator` 的 `activeSkills = []`，戰鬥記錄中完全沒有技能事件。

---

## 實作

在 `// MARK: - Private` 區塊新增 helper：

```swift
/// T06：升級後自動裝備該等級新解鎖的技能（不超過 4 槽，不重複）
private func autoEquipNewSkills(at newLevel: Int, player: PlayerStateModel) {
    let newSkills = SkillDef.all.filter {
        $0.classKey == player.classKey && $0.requiredLevel == newLevel
    }
    guard !newSkills.isEmpty else { return }
    var equipped = player.equippedSkillKeys
    for skill in newSkills where !equipped.contains(skill.key) && equipped.count < 4 {
        equipped.append(skill.key)
    }
    player.equippedSkillKeys = equipped
}
```

**插入點（兩處）：**

`levelUp()` — `player.availableSkillPoints += 1` 之後：
```swift
autoEquipNewSkills(at: nextLevel, player: player)   // T06
```

`autoLevelIfPossible()` — `player.heroLevel = next` 之後：
```swift
autoEquipNewSkills(at: next, player: player)    // T06
```

---

## 設計說明

- 每升一級只裝備**當級解鎖**的技能（`requiredLevel == newLevel`），不做補裝
- 裝備槽上限 4，滿槽時靜默跳過
- 已裝備的 key 不重複加入
- `classKey = ""` 時 `SkillDef.all.filter` 回傳空陣列，無副作用

---

## 驗收標準

- [x] 升至 Lv.3 後，對應職業第一技能自動出現在 `equippedSkillKeysRaw`
- [x] 已裝備 4 槽時，第 5 個解鎖技能不強塞入
- [x] 已裝備的技能不重複加入
- [x] `classKey = ""` 時無副作用
- [x] `xcodebuild` 通過，無新警告
