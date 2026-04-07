# V2-4 Ticket 01：MerchantTradeDef 新增 V2-1 素材出售

**狀態：** ✅ 完成

**依賴：** 無（第一張）

---

## 目標

商人目前只能出售 4 種 V1 通用素材。V2-1 帶入了 12 種區域素材，玩家打多了卻無處出售。
本 ticket 在靜態資料層補齊這個缺口，並加入 `TradeCategory` 以利 UI 分組。

---

## 修改檔案

`IdleBattleRPG/StaticData/MerchantTradeDef.swift`

### 1. 新增 TradeCategory enum

```swift
enum TradeCategory {
    case basicMaterial   // V1 通用素材 → 金幣
    case areaMaterial    // V2-1 區域素材 → 金幣
}
```

### 2. MerchantTradeDef 新增 category 欄位

```swift
struct MerchantTradeDef {
    let key: String
    let giveMaterial: MaterialType
    let giveAmount: Int
    let receive: TradeReceive
    let category: TradeCategory   // ← 新增
    ...
}
```

### 3. 原有 4 筆補上 category: .basicMaterial

```swift
MerchantTradeDef(key: "sell_wood",         ..., category: .basicMaterial),
MerchantTradeDef(key: "sell_ore",          ..., category: .basicMaterial),
MerchantTradeDef(key: "sell_hide",         ..., category: .basicMaterial),
MerchantTradeDef(key: "sell_crystal_shard",..., category: .basicMaterial),
```

### 4. 新增 12 筆 V2-1 素材出售（category: .areaMaterial）

| Key | 素材 | giveAmount | 金幣 | 地區 |
|---|---|---|---|---|
| sell_old_post_badge | .oldPostBadge | 3 | 30 | 荒野 F1 |
| sell_dried_hide_bundle | .driedHideBundle | 3 | 30 | 荒野 F2 |
| sell_split_horn_bone | .splitHornBone | 3 | 30 | 荒野 F3 |
| sell_rift_fang_royal_badge | .riftFangRoyalBadge | 1 | 120 | 荒野 Boss |
| sell_mine_lamp_copper_clip | .mineLampCopperClip | 3 | 40 | 礦坑 F1 |
| sell_tunnel_iron_clip | .tunnelIronClip | 3 | 40 | 礦坑 F2 |
| sell_vein_stone_slab | .veinStoneSlab | 3 | 40 | 礦坑 F3 |
| sell_stone_swallow_core | .stoneSwallowCore | 1 | 150 | 礦坑 Boss |
| sell_relic_seal_ring | .relicSealRing | 3 | 50 | 遺跡 F1 |
| sell_oath_inscription_shard | .oathInscriptionShard | 3 | 50 | 遺跡 F2 |
| sell_fore_shrine_clip | .foreShrineClip | 3 | 50 | 遺跡 F3 |
| sell_ancient_king_core | .ancientKingCore | 1 | 200 | 遺跡 Boss |

**定價邏輯：**
- F1-F3 通用素材：3 個換 30~50 金（略高於木/礦比例，反映掉落難度）
- Boss 特材：1 個換 120~200 金（稀有溢價，但不能輕易替代 farming）

---

## 影響範圍

| 檔案 | 動作 |
|---|---|
| `StaticData/MerchantTradeDef.swift` | ✏️ 修改（+TradeCategory +category 欄位 +12 筆） |

---

## 驗收標準

- [ ] `TradeCategory` enum 存在，有 `.basicMaterial` / `.areaMaterial` 兩個 case
- [ ] `MerchantTradeDef` 有 `category` 欄位
- [ ] `MerchantTradeDef.all` 共 16 筆（原 4 + 新 12）
- [ ] 原 4 筆 `category == .basicMaterial`
- [ ] 新 12 筆 `category == .areaMaterial`
- [ ] Build 無錯誤
