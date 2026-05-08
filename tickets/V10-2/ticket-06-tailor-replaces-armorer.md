# V10-2 T06 — 裁縫師取代皮甲師（教程防具 + NPC 順序調整）

## 狀態：✅ 已完成

## 目標

- 移除皮甲師（armorer）NPC 卡片，將教程防具製作（step 5 / step 7）統一交給裁縫師（tailor）
- 調整生產 Tab NPC 排序為裝備槽對應順序：主手 → 副手 → 防具 → 飾品 → 廚師 → 製藥師

## 設計

### NPC 責任重劃

| 職責 | 舊 | 新 |
|------|----|----|
| 教程 step 5 引導（材料不足） | 皮甲師 ArmorSheet | 裁縫師 TailorSheet |
| 教程 step 7 鑄造防具 | 皮甲師 ArmorSheet | 裁縫師 TailorSheet |
| tutorial_armor task actorKey | `armorer` | `tailor` |
| 皮甲師卡片（BaseView） | step >= 5 顯示 | 移除 |

SettlementService 以 `definitionKey == "tutorial_armor"` 識別教程任務，不檢查 actorKey，無需修改。

### NPC 順序（生產 Tab）

```
鑄造師（主手）→ 鍛造學徒（副手）→ 裁縫師（防具）→ 飾品師（飾品）→ 廚師 → 製藥師
```

副手 / 防具 / 飾品三張卡片在 step >= 3（職業選擇後）解鎖。

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `Services/TaskCreationService.swift` | `createTutorialArmorTask()` actorKey / busy-check: armorer → tailor |
| `Views/TailorSheet.swift` | 新增 `@Binding var selectedTab: Int`；新增 step 5 / step 7 tutorial Section；新增 `startTutorialArmorCraft()` |
| `Views/ArmorSheet.swift` | 移除 `@Binding var selectedTab: Int`；移除 step 5 / step 7 Section 及 `startTutorialArmorCraft()` |
| `Views/BaseView.swift` | 移除 `showArmorSheet`、ArmorSheet .sheet、`npcArmorerCard`；重排 `npcProduceSection()` 順序；TailorSheet 補上 `selectedTab: $selectedTab` |
| `Views/EliteBattleSheet.swift` | toast 改為「菁英已擊敗！前往裁縫師製作初始防具！」 |

## 驗收

1. Dev 工具重置教程，走完 step 0–8
2. step 5：裁縫師卡片已顯示；開啟後出現「引導任務」Section（材料不足 → 前往荒野探索）
3. step 7：裁縫師 Sheet 顯示「打造初始防具（2 秒）」按鈕
4. 防具鑄造完成，onboardingStep → 8，教程完成
5. 皮甲師卡片不再出現在生產 Tab（任何 step）
6. 生產 Tab 順序：鑄造師 → 鍛造學徒 → 裁縫師 → 飾品師 → 廚師 → 製藥師
7. 裁縫師一般配方（.armor slot）在教程完成後正常顯示且可委派
