# V8-2 Ticket 04：鑄造師進階技能（bs_gold + bs_mastery）

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

實作鑄造師技能樹中兩個尚未接入的進階技能：

| 技能 | key | 效果 | 實作位置 |
|------|-----|------|----------|
| 節省用金 | `bs_gold` | 每點降低 10% 鑄造金幣消耗 | `TaskCreationService.createCraftTask` |
| 爐火純青 | `bs_mastery` | 每點提升精良及以上裝備屬性 5% | `HeroStatsService.compute` |

---

## 修改細節

### T04-A：`Services/TaskCreationService.swift` — `createCraftTask`（bs_gold）

`createCraftTask` 只有**一個**實作（含 `durationOverride` 預設值），沒有多個 overload。
`createCuisineTask` / `createAlchemyTask` 雖然也有 `def.goldCost`，但 `bs_gold` **不適用**——
該技能僅屬於鑄造師，不影響廚師 / 製藥師的任務。

找到 `createCraftTask` 中讀取 `def.goldCost` 並扣除金幣的段落，套用折扣：

**現況：**
```swift
guard player.gold >= def.goldCost else { throw TaskCreationError.insufficientGold }
// ...
player.gold -= def.goldCost
```

**修改後：**
```swift
// 計算有效金幣成本（bs_gold 折扣）
let goldLv    = player.skillLevel(nodeKey: "bs_gold", actorKey: "blacksmith")
let discount  = Double(goldLv) * 0.10
let effectiveGold = max(0, Int(Double(def.goldCost) * (1.0 - discount)))

guard player.gold >= effectiveGold else { throw TaskCreationError.insufficientGold }
// ...
player.gold -= effectiveGold
```

> `max(0, ...)` 防禦性保護；Lv2 折扣最多 20%，實際不會出現負數。
>
> **TODO（UI）**：`CraftSheet` 目前顯示 `def.goldCost`，應改為 `effectiveGold` 讓玩家看到折後價。
> 本 ticket 不改 UI，留待後續。

### T04-B：`Services/HeroStatsService.swift` — `compute`（bs_mastery）

在計算裝備加成時，若裝備稀有度 ≥ `.refined`，套用鑄造師的 `bs_mastery` 技能加成。

**實作位置：** `compute(player:equipped:)` 的裝備迴圈段落。

```swift
// 讀取 bs_mastery 等級（一次性，在迴圈外）
let masteryLv    = player.skillLevel(nodeKey: "bs_mastery", actorKey: "blacksmith")
let masteryBonus = 1.0 + Double(masteryLv) * 0.05

// 裝備迴圈中
for equip in equipped {
    guard let def = EquipmentDef.find(key: equip.defKey) else { continue }
    
    // bs_mastery：精良及以上裝備屬性倍率
    // 使用 equip.rarity（直接在 EquipmentModel 上），不需額外查 EquipmentDef
    let rarityMultiplier: Double = {
        guard masteryLv > 0 else { return 1.0 }
        switch equip.rarity {
        case .refined, .rare, .epic: return masteryBonus
        case .common: return 1.0
        }
    }()

    atk += Int(Double(def.atkBonus) * rarityMultiplier)
    def_ += Int(Double(def.defBonus) * rarityMultiplier)
    hp  += Int(Double(def.hpBonus)  * rarityMultiplier)
}
```

`bs_mastery` 的加成是**動態即時計算**的（不存入 EquipmentModel），讓玩家每次點進角色頁都能看到最新的戰力數字。

---

## 修改檔案

- `Services/TaskCreationService.swift`（bs_gold）
- `Services/HeroStatsService.swift`（bs_mastery）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] bs_gold Lv0：鑄造金幣成本與現在完全相同
- [ ] bs_gold Lv1：金幣成本 ×0.90（例：200 金 → 180 金）
- [ ] bs_gold Lv2：金幣成本 ×0.80（例：200 金 → 160 金）
- [ ] 金幣不足判定以折扣後數字為準（不是原始 def.goldCost）
- [ ] bs_mastery Lv0：裝備屬性與現在完全相同
- [ ] bs_mastery Lv1：精良 / 稀有 / 史詩裝備屬性 ×1.05
- [ ] bs_mastery Lv3：精良及以上裝備屬性 ×1.15
- [ ] 普通（common）裝備不受 bs_mastery 影響（×1.0）
- [ ] 角色頁戰力數字即時反映（點技能 → 戰力立刻更新）
