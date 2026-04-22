# V4-2 Ticket 02：EliteBattleEngine（純計算層）

**狀態：** ✅ 已完成

**依賴：** T01 EliteDef

---

## 目標

建立純計算層 `EliteBattleEngine`，逐回合模擬菁英戰鬥，輸出完整戰鬥記錄供 BattleLogSheet 顯示。

---

## 新建檔案

`Services/EliteBattleEngine.swift`

---

## 輸入

```swift
static func simulate(
    heroStats: HeroStats,
    elite: EliteDef,
    seed: UInt64
) -> EliteBattleResult
```

`seed` 由呼叫方提供：
```swift
let seed = UInt64(Date.now.timeIntervalSinceReferenceDate) ^ UInt64(elite.floorKey.hashValue)
```

---

## 輸出

```swift
struct EliteRound {
    let heroAtk: Int
    let eliteAtk: Int
    let heroHpAfter: Int
    let eliteHpAfter: Int
    let description: String
}

struct EliteBattleResult {
    let rounds: [EliteRound]
    let won: Bool
    let finalHeroHp: Int
    // 便利方法：轉換為 [BattleEvent] 供 BattleLogSheet 使用
    func toBattleEvents(eliteName: String, heroMaxHp: Int) -> [BattleEvent]
}
```

---

## 戰鬥邏輯

```
每回合：
1. 英雄攻擊：damage = max(1, heroStats.atk - elite.def + RNG(-2...2))
2. 菁英 HP 減少
3. 若菁英 HP ≤ 0 → won = true，結束
4. 菁英反擊：damage = max(1, elite.atk - heroStats.def + RNG(-2...2))
5. 英雄 HP 減少
6. 若英雄 HP ≤ 0 → won = false，結束
7. 最大 50 回合防無限迴圈（50 回合後英雄勝利，英雄剩 1 HP）
```

---

## 回合描述模板

```swift
// 英雄攻擊行
"發動斬擊 → 造成 \(heroAtk) 傷害（菁英剩 \(eliteHpAfter) HP）"

// 菁英反擊行
"\(eliteName) 反擊 → 受到 \(eliteAtk) 傷害（英雄剩 \(heroHpAfter) HP）"

// 最終行（勝利）
"⚔️ 擊敗 \(eliteName)！"

// 最終行（落敗）
"💀 英雄不敵 \(eliteName)，落敗…"
```

---

## `toBattleEvents` 轉換

將 `EliteRound` 陣列轉為 `[BattleEvent]`，供 `BattleLogSheet` 直接使用：
- 英雄攻擊 → `.attack` event
- 菁英反擊 → `.damage` event
- 勝利 / 落敗 → `.victory` / `.defeat` event
- `heroMaxHp`：`heroStats.maxHp`；`enemyMaxHp`：`elite.maxHp`

---

## 驗收標準

- [ ] `simulate()` 回傳完整回合記錄
- [ ] `won` 判斷正確（英雄或菁英任一歸零）
- [ ] 相同 seed 永遠回傳相同結果
- [ ] `toBattleEvents()` 正確轉換，HP 條可正常顯示
- [ ] 不引入 SwiftData
