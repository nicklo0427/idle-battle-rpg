# V4-4 Ticket 01：AchievementDef 靜態資料

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

建立成就靜態定義，10 個成就涵蓋核心玩法里程碑。

---

## 新建檔案

`StaticData/AchievementDef.swift`

---

## 資料結構

```swift
struct AchievementDef {
    let key: String
    let name: String
    let description: String    // 對玩家顯示的達成條件說明
    let hiddenName: String     // 未解鎖時顯示的隱藏名稱（例：「??? 成就」）
    let icon: String           // SF Symbol 名稱
}
```

---

## 10 個成就定義

| key | 名稱 | 說明 | 隱藏名稱 | 圖示 |
|---|---|---|---|---|
| first_craft | 初次鑄造者 | 完成第一件裝備的鑄造 | 初出茅廬 | `hammer.fill` |
| first_dungeon | 地下城冒險家 | 完成第一次地下城出征 | 踏上旅途 | `map.fill` |
| refined_crafter | 精良工匠 | 鑄造第一件精良裝備 | 工藝之道 | `star.fill` |
| veteran_warrior | 百戰老兵 | 累計贏得 100 場戰鬥 | 沙場老將 | `shield.fill` |
| v1_collector | 裝備收藏家 | 集齊全部 6 件 V1 裝備（普通 + 精良各 3 部位）| 盔甲滿架 | `bag.fill` |
| wildland_explorer | 荒野征服者 | 首通荒野邊境全部 4 層 | 踏遍荒野 | `leaf.fill` |
| mine_explorer | 礦坑征服者 | 首通廢棄礦坑全部 4 層 | 深掘地底 | `cube.fill` |
| ruins_explorer | 遺跡征服者 | 首通古代遺跡全部 4 層 | 探索古蹟 | `building.columns.fill` |
| max_level | 傳奇英雄 | 英雄升至 Lv.20 | 極限突破 | `crown.fill` |
| elite_slayer | 菁英獵手 | 擊敗任意 5 個地區菁英 | 菁英剋星 | `flame.fill` |

---

## 靜態查詢方法

```swift
extension AchievementDef {
    static let all: [AchievementDef] = [...]

    static func find(key: String) -> AchievementDef? {
        all.first { $0.key == key }
    }
}
```

---

## 驗收標準

- [ ] 10 個成就定義完整
- [ ] `find(key:)` 查詢正確
- [ ] 不引入 SwiftData
