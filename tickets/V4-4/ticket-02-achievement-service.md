# V4-4 Ticket 02：PlayerStateModel 成就欄位 + AchievementService

**狀態：** 🔲 待實作

**依賴：** T01 AchievementDef

---

## 目標

在 PlayerStateModel 新增成就進度欄位，建立 AchievementService 負責檢查與解鎖，並在結算時觸發檢查。

---

## 修改檔案

- `Models/PlayerStateModel.swift`
- `Services/TaskClaimService.swift`（或 SettlementService）

## 新建檔案

- `Services/AchievementService.swift`

---

## PlayerStateModel 修改

```swift
@Model class PlayerStateModel {
    // ... 現有欄位 ...
    var unlockedAchievements: [String] = []   // 已解鎖的 achievement key 陣列
}
```

---

## AchievementService

```swift
class AchievementService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// 檢查所有成就，解鎖符合條件者
    func checkAndUnlock(
        player: PlayerStateModel,
        inventory: MaterialInventoryModel,
        allEquipment: [EquipmentModel],
        tasks: [TaskModel],
        clearedElites: [String]
    ) {
        let keys = player.unlockedAchievements
        var newKeys: [String] = []

        // first_craft：任一 .craft 任務有 resultCraftedEquipKey
        if !keys.contains("first_craft") {
            // 檢查是否曾完成鑄造（累計統計 or 背包有任何裝備）
            if !allEquipment.isEmpty { newKeys.append("first_craft") }
        }

        // first_dungeon：resultBattlesWon + resultBattlesLost > 0
        if !keys.contains("first_dungeon") {
            let total = (player.totalBattlesWon) + (player.totalBattlesLost)
            if total > 0 { newKeys.append("first_dungeon") }
        }

        // refined_crafter：背包有任何 .refined 裝備
        if !keys.contains("refined_crafter") {
            if allEquipment.contains(where: { $0.rarity == .refined }) {
                newKeys.append("refined_crafter")
            }
        }

        // veteran_warrior：累計 100 場勝利
        if !keys.contains("veteran_warrior") {
            if player.totalBattlesWon >= 100 { newKeys.append("veteran_warrior") }
        }

        // v1_collector：背包有全部 6 件 V1 裝備（各 defKey 至少 1 件）
        if !keys.contains("v1_collector") {
            let v1Keys = Set(["common_weapon", "common_armor", "common_accessory",
                              "refined_weapon", "refined_armor", "refined_accessory"])
            let ownedKeys = Set(allEquipment.map { $0.defKey })
            if v1Keys.isSubset(of: ownedKeys) { newKeys.append("v1_collector") }
        }

        // wildland_explorer / mine_explorer / ruins_explorer：首通各區 4 層
        // （依 clearedFloors 判斷，需從 DungeonProgressionModel 傳入）

        // max_level：英雄 Lv.20
        if !keys.contains("max_level") {
            if player.heroLevel >= 20 { newKeys.append("max_level") }
        }

        // elite_slayer：已清除菁英 ≥ 5
        if !keys.contains("elite_slayer") {
            if clearedElites.count >= 5 { newKeys.append("elite_slayer") }
        }

        guard !newKeys.isEmpty else { return }
        player.unlockedAchievements.append(contentsOf: newKeys)
        try? context.save()
    }
}
```

---

## 觸發時機

在 `TaskClaimService.claimAllCompleted()` 完成後呼叫：

```swift
achievementService.checkAndUnlock(
    player: player,
    inventory: inventory,
    allEquipment: allEquipment,
    tasks: recentTasks,
    clearedElites: progressionModel.clearedElites
)
```

也在 `CharacterProgressionService.levelUp()` 後觸發（檢查 max_level）。

---

## 驗收標準

- [ ] `unlockedAchievements` 正確持久化
- [ ] 各成就觸發條件實作正確
- [ ] 不重複解鎖同一成就
- [ ] 結算時自動觸發檢查
