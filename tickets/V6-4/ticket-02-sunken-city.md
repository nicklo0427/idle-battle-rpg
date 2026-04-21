# V6-4 Ticket 02：第 4 區域「沉落王城」(sunken_city)

**狀態：** ✅ 完成
**版本：** V6-4
**依賴：** V2-1 地下城推進系統

**修改檔案：**
- `IdleBattleRPG/StaticData/DungeonRegionDef.swift`
- `IdleBattleRPG/StaticData/EliteDef.swift`
- `IdleBattleRPG/StaticData/AchievementDef.swift`
- `IdleBattleRPG/StaticData/EquipmentDef.swift`（新增 4 件套裝裝備）
- `IdleBattleRPG/StaticData/MaterialType.swift`（新增區域素材）

---

## 說明

在原有 3 個地下城區域（荒野邊境 / 廢棄礦坑 / 古代遺跡）後加入第 4 區域，
作為目前內容的最終挑戰地帶，解鎖條件為首通古代遺跡菁英。

## 樓層定義

| 樓層 | 名稱 | Boss | 推薦戰力 | 金幣範圍 | 解鎖裝備 |
|---|---|---|---|---|---|
| F1 | 沉塔入口 | — | 530 | 50–95 | sunken_city_accessory |
| F2 | 溺殿迴廊 | — | 585 | 62–115 | sunken_city_armor |
| F3 | 王室深淵 | — | 645 | 78–145 | sunken_city_offhand |
| F4 | 沉王聖座 | 沉落王・深淵甦醒 | 710 | 100–180 | sunken_city_weapon |

## 區域素材（掉落表）

- `sunkenRuneShard`（沉落符文碎片）
- `abyssalCrystalDrop`（深淵晶淚）
- `drownedCrownFragment`（溺王冠碎片）
- `sunkenKingSeal`（沉王印記，Boss 層限定）

## AdventureView

- `DungeonRegionDef.all` 包含 4 個區域，`ForEach` 自動渲染第 4 張卡片
- 未解鎖前灰化並顯示解鎖條件（需首通古代遺跡菁英）

## 驗收標準

- [x] AdventureView 顯示 4 個區域，sunken_city 灰化顯示直到解鎖
- [x] 解鎖後可進入 F1–F4，各層掉落正確
- [x] F4 Boss 擊敗後成就「深淵征服者」觸發
- [x] `xcodebuild` 通過，無新警告
