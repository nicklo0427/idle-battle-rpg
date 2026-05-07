# V10-1 Ticket 06：引導式教程（新手武器鑄造流程）

**狀態：** 🔲 待實作

**依賴：** T01–T05（classKey、hasSeenIntro、starterEquipmentKeys 欄位需先存在）

---

## 核心目標

新玩家完成職業選擇後，不直接進入完整基地，而是透過一段引導完成：
1. 派遣樵夫採集 5 秒（示範採集機制）
2. 前往鑄造師打造第一把武器 5 秒（示範鑄造機制）
3. 武器自動裝備 → 進入完整基地

---

## onboardingStep 狀態機（擴充）

| step | 含義 |
|------|------|
| 0 | 職業確認完畢，教程尚未開始（無武器） |
| 1 | 樵夫採集任務已派遣（5 秒進行中） |
| 2 | 採集完成，引導前往鑄造師 |
| 3 | 教程完成（武器已授予，進入完整基地） |

**舊存檔相容：** `DatabaseSeeder.backfillOnboardingStep()` 對 `classKey != "" && onboardingStep < 3` 的存檔設 `onboardingStep = 3`，舊玩家不再觸發教程。

---

## 初始素材調整

新玩家起始木材/礦石改為 0，教程採集後才有素材：

```swift
// AppConstants.swift 或 DatabaseSeeder seedMaterials
initialWood = 0   // 原為 6
initialOre  = 0   // 原為 4
```

`seedStartingEquipment()` 守門已在 T05 調整（classKey 空不種 rusty_sword）。

---

## BaseView NPC 鎖定（step < 3）

| step | 可互動 NPC | 其餘 NPC |
|------|-----------|---------|
| 0 | `gatherer_1`（樵夫）| 灰色，顯示「完成引導後解鎖」 |
| 1 | `gatherer_1`（進行中狀態）| 同上 |
| 2 | `gatherer_1` + `blacksmith` | 其他仍鎖定 |
| 3 | 全員 | — |

```swift
// BaseView 判斷邏輯
func isNpcUnlocked(actorKey: String, step: Int) -> Bool {
    if step >= 3 { return true }
    if step <= 1 { return actorKey == "gatherer_1" }
    if step == 2 { return actorKey == "gatherer_1" || actorKey == "blacksmith" }
    return false
}
```

---

## GathererDetailSheet 教程模式（gatherer_1，step == 0）

頂部顯示教程提示 Section（獨立 Section，非 NpcIntroSection）：

```
╔══════════════════════════════════╗
║  採集提示（泡泡框）                ║
║  「要塞需要資源。先去砍點木材吧，   ║
║    打把武器就差這一步了。」         ║
║                                  ║
║  [ 派遣採集（5 秒） ]              ║
╚══════════════════════════════════╝
```

- 按下按鈕呼叫 `TaskCreationService.createTutorialGatherTask()`
- 任務建立後 `onboardingStep = 1`，context.save()
- 不扣除素材（教程採集直接授予 resultWood）

---

## CraftSheet 教程模式（blacksmith，step == 2）

頂部顯示教程提示 Section：

```
╔══════════════════════════════════╗
║  鑄造提示（泡泡框）                ║
║  「素材齊了，我替你打一把趁手的      ║
║    武器——5 秒後完工。」             ║
║                                  ║
║  [ 打造初始武器（5 秒） ]           ║
╚══════════════════════════════════╝
```

- 按下按鈕呼叫 `TaskCreationService.createTutorialCraftTask(for:)`
- 不扣除任何素材/金幣（教程鑄造）
- `definitionKey = "tutorial_craft"`，`resultCraftedEquipKey` = 職業對應主武器 key

---

## TaskCreationService — 教程任務方法

```swift
func createTutorialGatherTask() throws
// actorKey: "gatherer_1"
// definitionKey: "tutorial_gather"
// durationOverride: 5（秒）
// resultWood: 6（固定，教程木材補給）
// 建立後 player.onboardingStep = 1
// 同一個 context.save()

func createTutorialCraftTask(for classDef: ClassDef) throws
// actorKey: "blacksmith"
// definitionKey: "tutorial_craft"
// durationOverride: 5（秒）
// resultCraftedEquipKey = classDef.starterEquipmentKeys.first（主武器）
// 不扣素材，不扣金幣
// 同一個 context.save()
```

---

## SettlementService — 教程任務結算處理

```swift
// scanAndSettle() 內新增判斷
if task.definitionKey == "tutorial_gather" {
    // resultWood 正常入帳
    player.onboardingStep = 2
}

if task.definitionKey == "tutorial_craft" {
    // 查找 classDef，呼叫 grantStarterEquipment(for: classDef)
    // weapon + offhand 皆建立並設 isEquipped = true
    player.onboardingStep = 3
}
```

---

## ClassSelectionView 調整（配合 T05）

移除 `grantStarterEquipment` 呼叫（裝備改由本教程結算授予）：

```swift
// ❌ 移除
appState.equipmentService.grantStarterEquipment(for: classDef)

// ✅ 只保留
player.classKey = classDef.key
try? context.save()
// onboardingStep 維持 0，進入教程流程
```

---

## 移除 hasUsedFirstCraftBoost

原本的首次鑄造 30 秒加速功能由教程 5 秒鑄造完全取代，欄位整個移除：

- `Models/PlayerStateModel.swift`：刪除 `hasUsedFirstCraftBoost: Bool`
- `Views/CraftSheet.swift`：刪除首次加速按鈕相關邏輯
- `Models/DatabaseSeeder.swift`：刪除 `hasUsedFirstCraftBoost` 初始化

---

## 停用 OnboardingBannerView

現有 3 步驟 Banner（step 0–2）與新教程邏輯衝突，教程取代其功能：

```swift
// BaseView 中移除 OnboardingBannerView 引用，或條件改為永不觸發
// onboardingStep >= 3 後不顯示任何 Banner
```

---

## 修改檔案

| 檔案 | 變更說明 |
|------|---------|
| `AppConstants.swift` / `DatabaseSeeder.swift` | `initialWood = 0`, `initialOre = 0` |
| `Models/DatabaseSeeder.swift` | 新增 `backfillOnboardingStep()`；移除 `hasUsedFirstCraftBoost` 初始化 |
| `Models/PlayerStateModel.swift` | 移除 `hasUsedFirstCraftBoost` 欄位 |
| `Views/BaseView.swift` | NPC 鎖定邏輯（`isNpcUnlocked(actorKey:step:)`）；移除 OnboardingBannerView |
| `Views/GathererDetailSheet.swift` | step == 0 時顯示教程採集 Section |
| `Views/CraftSheet.swift` | step == 2 時顯示教程鑄造 Section；移除首次 30 秒加速按鈕邏輯 |
| `Services/TaskCreationService.swift` | 新增 `createTutorialGatherTask()` / `createTutorialCraftTask(for:)` |
| `Services/SettlementService.swift` | 辨識 `tutorial_gather` / `tutorial_craft`，推進 onboardingStep，結算武器 |
| `Views/ClassSelectionView.swift` | 移除 `grantStarterEquipment` 呼叫（由教程結算負責） |

---

## 驗證

1. 新玩家選完職業 → 進入基地 → 只有樵夫可點，其他 NPC 顯示「完成引導後解鎖」
2. 點樵夫 → 顯示教程提示 + 「派遣採集（5 秒）」 → 5 秒後結算 → 獲得木材 → step = 2
3. step = 2 → 鑄造師解鎖 → 點鑄造師 → 顯示教程提示 + 「打造初始武器（5 秒）」
4. 鑄造 5 秒後結算 → 背包出現職業對應武器 + 副手（皆已裝備）→ step = 3 → 全員解鎖
5. 舊存檔升級（classKey 非空）→ step 自動設為 3 → 不進教程，全員正常互動
6. 鑄造 Sheet 不再有首次 30 秒加速按鈕
7. `xcodebuild` 通過，無警告
