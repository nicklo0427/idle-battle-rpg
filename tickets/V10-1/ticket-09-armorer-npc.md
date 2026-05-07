# V10-1 T09 — 皮甲師 NPC（ArmorSheet）

## 狀態：✅ 已完成

## 目標

新增「皮甲師」NPC（actorKey: `armorer`），專門鑄造 `.armor` slot 裝備。
教程 step 5 後出現在生產 Tab。

## 設計

- actorKey: `armorer`
- 預設名: `皮甲師`
- 顯示條件：`onboardingStep >= 5`
- 專屬 Sheet：`ArmorSheet`（複用 CraftSheet 架構，filter `.armor` slot）
- 教程 step 5 Section：素材不足提示 → 設 step=6，切回冒險 Tab
- 教程 step 7 Section：一鍵 5 秒打造 → `createTutorialArmorTask()`

## 修改檔案

| 檔案 | 變更 |
|------|------|
| `AppConstants.swift` | `Actor.armorer = "armorer"` |
| `StaticData/NpcIntroDef.swift` | 新增 armorer 條目（defaultName: "皮甲師"） |
| `Views/ArmorSheet.swift`（新增）| `.armor` slot 配方列表；step 5/7 教程 Section |
| `Views/BaseView.swift` | `npcArmorerCard`；`@Binding var selectedTab: Int`；sheet 綁定 |
| `Views/ContentView.swift` | 傳入 `$selectedTab` 至 BaseView |

## 驗收

1. Step 5 後生產 Tab 出現皮甲師卡片
2. 點開 ArmorSheet 顯示 `.armor` 配方
3. Step 5 時顯示「材料不足」Section，點擊切回冒險 Tab（step → 6）
4. Step 7 時顯示「打造初始防具（5 秒）」按鈕
