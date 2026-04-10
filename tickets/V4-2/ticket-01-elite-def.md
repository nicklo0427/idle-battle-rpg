# V4-2 Ticket 01：EliteDef 靜態資料

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

建立每個樓層的菁英敵人靜態定義，作為 V4-2 菁英戰鬥系統的資料基礎。

---

## 新建檔案

`StaticData/EliteDef.swift`

---

## 資料結構

```swift
struct EliteDef {
    let floorKey: String                    // 對應樓層 key
    let name: String                        // 菁英名稱
    let maxHp: Int
    let atk: Int
    let def: Int
    let minimumPowerToChallenge: Int        // 戰力不足則 disabled
    let rewardGold: Int
    let rewardMaterials: [MaterialType: Int]
}
```

---

## 靜態資料（各區域 × 4 樓層）

### 荒野邊境（推薦戰力 50–150）

| 樓層 key | 名稱 | HP | ATK | DEF | 最低戰力 | 獎勵 |
|---|---|---|---|---|---|---|
| wildland_floor_1 | 荒野哨兵 | 80 | 18 | 5 | 60 | 50 金 + oldPostBadge × 2 |
| wildland_floor_2 | 野地皮師 | 120 | 22 | 8 | 90 | 80 金 + driedHideBundle × 2 |
| wildland_floor_3 | 裂角獵手 | 160 | 28 | 10 | 120 | 120 金 + splitHornBone × 2 |
| wildland_floor_4 | 裂牙王 | 220 | 35 | 12 | 150 | 200 金 + riftFangRoyalBadge × 1 |

### 廢棄礦坑（推薦戰力 150–300）

| 樓層 key | 名稱 | HP | ATK | DEF | 最低戰力 | 獎勵 |
|---|---|---|---|---|---|---|
| mine_floor_1 | 礦坑守衛 | 200 | 35 | 15 | 180 | 120 金 + mineLampCopperClip × 2 |
| mine_floor_2 | 脈鐵鑿工 | 280 | 45 | 20 | 220 | 180 金 + tunnelIronClip × 2 |
| mine_floor_3 | 承脈重甲 | 380 | 55 | 28 | 270 | 250 金 + veinStoneSlab × 2 |
| mine_floor_4 | 吞岩巨獸 | 500 | 68 | 32 | 320 | 400 金 + stoneSwallowCore × 1 |

### 古代遺跡（推薦戰力 300–500）

| 樓層 key | 名稱 | HP | ATK | DEF | 最低戰力 | 獎勵 |
|---|---|---|---|---|---|---|
| ruins_floor_1 | 遺跡守誓者 | 450 | 65 | 35 | 380 | 250 金 + relicSealRing × 2 |
| ruins_floor_2 | 碑紋祭司 | 600 | 80 | 45 | 430 | 350 金 + oathInscriptionShard × 2 |
| ruins_floor_3 | 前殿衛士 | 780 | 95 | 55 | 480 | 480 金 + foreShrineClip × 2 |
| ruins_floor_4 | 古王靈魂 | 1000 | 115 | 65 | 540 | 700 金 + ancientKingCore × 1 |

---

## 靜態查詢方法

```swift
extension EliteDef {
    static let all: [EliteDef] = [...]

    static func find(floorKey: String) -> EliteDef? {
        all.first { $0.floorKey == floorKey }
    }
}
```

---

## 驗收標準

- [ ] 所有 12 個樓層均有對應 EliteDef
- [ ] `find(floorKey:)` 查詢正確
- [ ] 菁英強度介於普通敵人與 Boss 之間（依推薦戰力合理設置）
- [ ] 不引入 SwiftData
