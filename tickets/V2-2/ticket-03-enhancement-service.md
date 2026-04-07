# V2-2 Ticket 03：EnhancementService（強化業務邏輯）

**狀態：** ✅ 已完成

**依賴：** Ticket 01（EnhancementDef）、Ticket 02（EquipmentModel.enhancementLevel）

---

## 目標

建立 `EnhancementService`，封裝強化與拆解的業務邏輯：前置驗證、資源扣除、SwiftData 寫入。
Service 依現有架構以 `ModelContext` 建構子注入，無副作用可驗證。

---

## 新增檔案

### `Services/EnhancementService.swift`（新增）

#### 強化

```swift
enum EnhanceError: Error {
    case alreadyMaxLevel          // 已達 +5，不可再強化
    case insufficientGold         // 金幣不足
}

func enhance(equipment: EquipmentModel, player: PlayerStateModel) throws {
    guard equipment.enhancementLevel < EnhancementDef.maxLevel
    else { throw EnhanceError.alreadyMaxLevel }

    guard let cost = EnhancementDef.goldCost(fromLevel: equipment.enhancementLevel)
    else { throw EnhanceError.alreadyMaxLevel }   // 查不到 = 超出範圍

    guard player.gold >= cost
    else { throw EnhanceError.insufficientGold }

    player.gold -= cost
    equipment.enhancementLevel += 1
    try context.save()
}
```

#### 拆解

```swift
enum DisassembleError: Error {
    case cannotDisassemble        // 不可拆解（rusty_sword 或查不到規則）
    case isEquipped               // 已裝備中，不可拆解
}

func disassemble(equipment: EquipmentModel, player: PlayerStateModel) throws {
    guard !equipment.isEquipped
    else { throw DisassembleError.isEquipped }

    guard let refund = EnhancementDef.disassembleRefund(defKey: equipment.defKey)
    else { throw DisassembleError.cannotDisassemble }

    player.gold += refund
    context.delete(equipment)
    try context.save()
}
```

---

## 分層責任

| 層 | 責任 |
|---|---|
| `EnhancementService` | 驗證 + 資源扣除 / 入帳 + SwiftData 寫入 |
| View / ViewModel | 傳入 `equipment` 與 `player`（從 `@Query` 取得），處理 error 顯示 |
| `EnhancementDef` | 靜態規則查詢（成本、加成、拆解退還）|

---

## 建構子

```swift
final class EnhancementService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
}
```

`AppState` 持有並公開 `enhancementService: EnhancementService`，與其他 Service 一致。

---

## 不做的事

- **強化動畫 / 特效**：留後續
- **多件批次強化**：MVP 語義，單件操作
- **材料消耗**：V2-2 僅消耗金幣（降低複雜度，數值靠 Ticket 06 平衡）

---

## 驗收標準

- [ ] `enhance()` 在金幣足夠時正確扣除金幣、遞增 `enhancementLevel`、`save()`
- [ ] `enhance()` 在金幣不足時拋出 `insufficientGold`，不修改任何資料
- [ ] `enhance()` 對 `enhancementLevel == 5` 的裝備拋出 `alreadyMaxLevel`
- [ ] `disassemble()` 正確入帳退還金幣、刪除裝備、`save()`
- [ ] `disassemble()` 對已裝備裝備拋出 `isEquipped`
- [ ] `disassemble()` 對 `rusty_sword` 拋出 `cannotDisassemble`
- [ ] `AppState` 持有 `enhancementService`，`init` 接受 `ModelContext`
