# V2-4 Ticket 04：CraftSheet 配方裝備屬性預覽

**狀態：** ✅ 完成

**依賴：** 無（獨立）

---

## 目標

鑄造 Sheet 目前顯示配方名稱、時長、素材需求、金幣成本，但不顯示鑄出裝備的屬性。
玩家不知道「精良武器 ATK +32」還是「荒野皮甲 DEF +16 / HP +38」，無法做出明智選擇。

本 ticket 在每個配方 row 加入輸出裝備的 ATK / DEF / HP 預覽。

---

## 修改檔案

`IdleBattleRPG/Views/CraftSheet.swift`

### 在配方 row 加入屬性預覽

定位每個配方 row 的 VStack（目前包含：名稱 + 時長文字，以及素材 tag 列），
在名稱列的右側或素材列下方（根據現有佈局決定位置）加入：

```swift
if let equip = EquipmentDef.find(key: recipe.outputEquipmentKey) {
    HStack(spacing: 6) {
        if equip.baseAtk > 0 {
            Label("+\(equip.baseAtk)", systemImage: "sword")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if equip.baseDef > 0 {
            Label("+\(equip.baseDef)", systemImage: "shield")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if equip.baseHp > 0 {
            Label("+\(equip.baseHp)", systemImage: "heart")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
```

若 `Label` 的 systemImage 不夠直觀，可改用純文字：
```swift
Text("⚔️ +\(equip.baseAtk)")   // ATK
Text("🛡 +\(equip.baseDef)")   // DEF
Text("❤️ +\(equip.baseHp)")    // HP
```

只顯示非零屬性（武器只顯示 ATK，防具顯示 DEF + HP，以此類推）。

### 屬性來源

`EquipmentDef.find(key: recipe.outputEquipmentKey)` — 純靜態查詢，無需 SwiftData。

> Boss 武器（wildland_weapon / mine_weapon / ruins_weapon）的 baseAtk 為固定基準值（如 22），
> 實際浮動值在 Farming 時才計算。配方預覽顯示基準值即可，可加附註「ATK 浮動」。

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `Views/CraftSheet.swift` | ✏️ 修改（每個配方 row 加屬性預覽） |

---

## 驗收標準

- [ ] 每個配方 row 顯示輸出裝備的非零屬性（ATK / DEF / HP）
- [ ] 武器配方只顯示 ATK
- [ ] 防具配方只顯示 DEF + HP
- [ ] 飾品/副手配方顯示對應非零屬性
- [ ] Boss 武器配方顯示基準 ATK（可加「浮動」說明）
- [ ] 資源不足（灰化）的配方也正確顯示屬性
- [ ] Build 無錯誤
