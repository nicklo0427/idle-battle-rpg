# V7-1 Ticket 02：採集者技能系統

**狀態：** 🔲 待實作

**依賴：** T01（採藥師 / 漁夫 actorKey 需先定義）

---

## 目標

每位採集者升 Tier 時獲得技能點數，可投入專屬的技能節點，每個節點可重複投入多點（類比英雄天賦樹設計）。取代原本的「二擇一分支」概念。

---

## 系統設計

### 點數來源

每次採集者升 Tier（0→1、1→2、2→3）各獲得 **1 個技能點**，共 3 點上限。

> 點數與 Tier 升級綁定，不需額外 UI 操作，升完 Tier 即可見可用點數。

### 儲存（類比 TalentService 的 append-only 設計）

**PlayerStateModel 新增欄位（SwiftData 輕量遷移）：**

```swift
var gatherer1SkillPoints: Int = 0       // 可用點數
var gatherer1SkillsRaw:   String = ""   // 已投入，逗號分隔，重複 = 多點
var gatherer2SkillPoints: Int = 0
var gatherer2SkillsRaw:   String = ""
var gatherer3SkillPoints: Int = 0       // 採藥師
var gatherer3SkillsRaw:   String = ""
var gatherer4SkillPoints: Int = 0       // 漁夫
var gatherer4SkillsRaw:   String = ""
```

**節點等級計算（`GathererSkillNodeDef`）：**

```swift
func currentLevel(actorKey: String, in player: PlayerStateModel) -> Int {
    player.investedSkillKeys(for: actorKey).filter { $0 == self.key }.count
}
```

`investedSkillKeys(for:)` 類比 `investedTalentKeys`，parse raw string。

---

## 技能節點定義（靜態）

每種採集者各有 3 個節點，結構統一：

```swift
struct GathererSkillNodeDef {
    let key: String           // e.g. "gatherer_1_yield"
    let actorKey: String      // 屬於哪位 NPC
    let name: String
    let description: String   // 每點效果說明
    let maxLevel: Int
    let prerequisiteKey: String?  // 前置節點 key（nil = 無前置）
    let effect: GathererSkillEffect
}

enum GathererSkillEffect {
    case yieldBonus(Int)          // 每點 +N 產出
    case durationReduction(Double) // 每點 -X% 任務時長
    case rareChance(Double)        // 每點 +X% 稀有事件機率（T03 搭配使用）
}
```

### 各採集者節點

| NPC | 節點 key | 名稱 | 效果 / 點 | 上限 | 前置 |
|---|---|---|---|---|---|
| 伐木工 | `g1_yield` | 砍伐熟練 | +1 木材 / 點 | 5 | 無 |
| 伐木工 | `g1_speed` | 林地節奏 | -5% 任務時長 / 點 | 3 | g1_yield ≥ 1 |
| 伐木工 | `g1_rare` | 林中奇遇 | +5% 稀有事件 / 點 | 3 | g1_yield ≥ 3 |
| 採礦工 | `g2_yield` | 礦脈開採 | +1 礦石 / 點 | 5 | 無 |
| 採礦工 | `g2_speed` | 採礦效率 | -5% 任務時長 / 點 | 3 | g2_yield ≥ 1 |
| 採礦工 | `g2_rare` | 礦中發現 | +5% 稀有事件 / 點 | 3 | g2_yield ≥ 3 |
| 採藥師 | `g3_yield` | 採藥精通 | +1 草藥 / 點 | 5 | 無 |
| 採藥師 | `g3_speed` | 藥草識別 | -5% 任務時長 / 點 | 3 | g3_yield ≥ 1 |
| 採藥師 | `g3_rare` | 靈藥嗅覺 | +5% 稀有事件 / 點 | 3 | g3_yield ≥ 3 |
| 漁夫 | `g4_yield` | 漁獲豐收 | +1 鮮魚 / 點 | 5 | 無 |
| 漁夫 | `g4_speed` | 精準拋線 | -5% 任務時長 / 點 | 3 | g4_yield ≥ 1 |
| 漁夫 | `g4_rare` | 深淵感應 | +5% 稀有事件 / 點 | 3 | g4_yield ≥ 3 |

> 任務時長縮減以「實際採集 cycle 數不變、顯示倒數縮短」實作，或直接縮短 `endsAt`（需確認對 deterministic RNG 無影響）。

---

## GathererSkillService

新建 `Services/GathererSkillService.swift`，類比 `TalentService`：

```swift
func investPoint(nodeKey: String, actorKey: String, player: PlayerStateModel) throws
// 驗證：有點數、節點未滿、前置達標
// 寫入：availablePoints -1，append nodeKey 至 rawString

func availablePoints(actorKey: String, player: PlayerStateModel) -> Int
func currentLevel(nodeKey: String, actorKey: String, player: PlayerStateModel) -> Int
func isPrerequisiteMet(node: GathererSkillNodeDef, actorKey: String, player: PlayerStateModel) -> Bool
```

---

## 效果套用時機

- **yieldBonus**：`TaskClaimService.accumulateMaterials` 查詢該 NPC 的 yield 節點等級，加入基礎 bonus
- **durationReduction**：`TaskCreationService.createGatherTask` 計算實際 `endsAt` 時套用縮減
- **rareChance**：`SettlementService.fillGatherResults` 計算事件 roll 的閾值時套用（T03 整合）

---

## UI

在 `GathererDetailSheet` 新增「技能」段落（位於 Tier 升級下方）：

```
┌─────────────────────────────────────────┐
│  技能  （可用點數：1）                   │
│                                         │
│  ○ 砍伐熟練  Lv.2/5   +2 木材          │
│              [＋]                       │
│                                         │
│  ○ 林地節奏  Lv.0/3   -0% 時長（鎖定）  │  ← 前置未達標
│  ○ 林中奇遇  Lv.0/3   +0% 稀有（鎖定）  │
└─────────────────────────────────────────┘
```

- 有可用點數且前置達標：顯示 `[＋]` 按鈕
- 前置未達標：灰色顯示「需先點 X 達 N 級」
- 節點已滿：顯示「已滿」badge

---

## 修改檔案

| 檔案 | 改動 |
|---|---|
| `StaticData/GathererSkillDef.swift`（新建）| `GathererSkillNodeDef`、`GathererSkillEffect`、靜態資料 |
| `Models/PlayerStateModel.swift` | 8 個新欄位（4 NPC × 點數 + rawString）及 helper |
| `Services/GathererSkillService.swift`（新建）| 投點驗證、點數查詢 |
| `Services/TaskCreationService.swift` | `createGatherTask` 套用 speed 縮減 |
| `Services/TaskClaimService.swift` | `accumulateMaterials` 套用 yield bonus |
| `Services/SettlementService.swift` | `fillGatherResults` 套用 rareChance（T03 整合）|
| `Views/GathererDetailSheet.swift` | 新增技能段落 UI |
| `ViewModels/BaseViewModel.swift` | 注入 `GathererSkillService`，暴露投點方法 |

---

## 驗收標準

- [ ] 採集者升 Tier 後，`gathererXSkillPoints` 正確增加
- [ ] 投點後節點等級上升，可用點數減少
- [ ] 前置節點未達標時無法投點
- [ ] 節點滿級後 `[＋]` 消失，顯示「已滿」
- [ ] yield bonus 在結算後正確反映在素材數量
- [ ] speed 節點縮短任務實際時長（endsAt 提前）
- [ ] rareChance 節點提高 T03 稀有事件觸發率
