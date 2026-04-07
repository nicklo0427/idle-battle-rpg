# V2-1 Ticket 08：Boss 武器浮動數值 Farming

**狀態：** ✅ 已完成

**依賴：** Ticket 04（AdventureView 樓層出征）、Ticket 07（首通後解鎖 Boss 武器配方）

---

## 目標

讓 Boss 層（`isBossFloor == true`）在結算時有機率掉落區域代表武器，武器的 ATK 加成有浮動數值，讓玩家有動機反覆挑戰 Boss 追求更好的版本。

規格 §7.2：
> 同名武器可有浮動數值版本，玩家可透過反覆挑戰 Boss 追求更好的版本。

---

## 設計規範

### 掉落條件

- 任務為 Boss 層（`DungeonFloorDef.isBossFloor == true`）
- 出征至少獲得一場勝利（`resultBattlesWon >= 1`）
- 掉落率：**100%**（每次擊敗 Boss 必掉，farming 動機來自浮動數值）

### 浮動數值範圍

每個 Boss 武器有基礎 ATK 與浮動範圍：

| Boss 武器 | ATK 基礎 | ATK 浮動範圍 |
|---|---|---|
| 裂牙獵刃（荒野邊境）| 20 | 18–24 |
| 吞岩重鑿（廢棄礦坑）| 38 | 34–44 |
| 王誓聖刃（古代遺跡）| 60 | 54–68 |

> ⚠️ 數值為初稿，待 Ticket 09 數值平衡工單調整。

### 浮動數值確定性

使用現有確定性 RNG（seed = `task.startedAt XOR task.id`），保證相同任務重算時結果一致。

---

## 資料模型

### EquipmentModel 新增浮動欄位

```swift
@Model final class EquipmentModel {
    // 現有欄位
    var defKey: String
    var slot: EquipmentSlot
    var rarity: Rarity
    var isEquipped: Bool

    // 新增
    var rolledAtk: Int?   // nil = 使用 EquipmentDef.atkBonus 固定值
                           // 非 nil = Boss 武器浮動值，覆蓋 defKey 的基礎值
}
```

### HeroStatsService 調整

`compute(player:equipped:)` 計算 ATK 時優先使用 `equipment.rolledAtk`：

```swift
atkBonus += equipment.rolledAtk ?? def.atkBonus
```

---

## 結算流程

```
Boss 層任務結算
  ↓ DungeonSettlementEngine.settle(task:floor:)
  ↓ isBossFloor && battlesWon >= 1
  ↓ rng.nextInt(in: weapon.atkRange) → rolledAtk
  ↓ task.resultCraftedEquipKey = boss weapon key
  ↓ task.resultRolledAtk = rolledAtk（TaskModel 新增欄位）
  ↓ TaskClaimService.claimAllCompleted()
  ↓ EquipmentModel(defKey:..., rolledAtk: rolledAtk) 插入背包
```

### TaskModel 新增欄位

```swift
var resultRolledAtk: Int?   // Boss 武器浮動 ATK，nil 表示非武器掉落
```

---

## CharacterView 顯示

已裝備的 Boss 武器若有 `rolledAtk`，裝備槽顯示浮動值而非基礎值：

```
裂牙獵刃  ATK +22  ← 顯示 rolledAtk，而非 defKey 基礎 20
```

---

## 影響範圍

| 檔案 | 異動類型 | 說明 |
|---|---|---|
| `Models/EquipmentModel.swift` | ✏️ 修改 | 新增 `rolledAtk: Int?` |
| `Models/TaskModel.swift` | ✏️ 修改 | 新增 `resultRolledAtk: Int?` |
| `StaticData/EquipmentDef.swift` | ✏️ 修改 | Boss 武器新增 `atkRange: ClosedRange<Int>` |
| `Services/DungeonSettlementEngine.swift` | ✏️ 修改 | Boss 層結算時擲 `atkRange` RNG |
| `Services/TaskClaimService.swift` | ✏️ 修改 | 建立 EquipmentModel 時傳入 `rolledAtk` |
| `Services/HeroStatsService.swift` | ✏️ 修改 | ATK 計算優先使用 `rolledAtk` |
| `Views/CharacterView.swift` | ✏️ 修改 | 裝備槽顯示 `rolledAtk` |

---

## 驗收標準

- [ ] 擊敗 Boss（≥1 場勝利）後，結算 Sheet 顯示掉落武器名稱
- [ ] 武器進入背包，ATK 數值在指定範圍內
- [ ] 相同任務（seed 固定）重算結果一致
- [ ] 裝備後 CharacterView 顯示浮動 ATK 值
- [ ] 重刷 Boss 可取得不同 ATK 值的同名武器
- [ ] 多把同名武器可並存於背包（取最優者裝備）
