# 測試進度與 TestFlight 待辦清單

---

## 實機測試結果（Debug Build）

> **E1 備注：** 升級消耗金幣的設計將在下一 Phase 改為經驗值系統，目前維持現狀。

### ✅ 已通過（全部）

| 區塊 | 通過項目 |
|---|---|
| A 初始狀態 | A1 初始資料正確、A2 Onboarding Banner、A3 戰力 58 |
| B 採集 | B1–B6 全部（Sheet、倒數、阻擋、結算、庫存更新、雙採集者）|
| C 鑄造 | C1–C6 全部（首件加速、扣料時機、阻擋、裝備入背包）|
| D 地下城 | D1–D6 首次加速、5場、Banner倒數、按鈕禁用、獎勵入帳；D8 鎖定顯示 |
| E 角色 | E2 升級得屬性點、E3 戰力即時、E5 裝備切換、E6 卸除裝備 |
| F 商人 | F1–F4 全部（開啟、disabled、金幣更新）|
| G 離線 | G1 背景結算、G2 前台結算 |
| H 穩定性 | H1–H6 全部（背景Timer、Tab切換、Sheet疊加、拖關、Toast、重裝）|
| I Onboarding | I1 三步流程、I2 重啟不再顯示 |

---

## 待驗證（全部通過 ✅）

| # | 項目 | 通過 |
|---|---|---|
| D7 | 低戰力勝率偏低（卸裝 → 出征 → 敗場多、有安慰金幣）| ✅ |
| E1 | ~~升級金幣不足提示~~ → 已改為 EXP 升級系統，此項目作廢 | N/A |
| E4 | Lv.10 升級上限（升至最高等級後按鈕消失、顯示上限文字）| ✅ |

---

## 上傳 TestFlight 前（Release Build）

先同意 developer.apple.com 的 PLA，再執行以下步驟：

| # | 項目 | 說明 |
|---|---|---|
| R1 | 同意 PLA | developer.apple.com → 登入 → 同意最新授權條款 |
| R2 | 調回正式數值 | `GatherLocationDef`、`CraftRecipeDef` 時間調回正式值 |
| R3 | xcodegen generate | 確保 Info.plist 包含 `UIRequiresFullScreen`、`CFBundleDisplayName = 放置英雄` |
| R4 | Archive（Release scheme）| Xcode → Product → Archive |
| R5 | Dev 模式不可見 | Release build 中 BaseView 無「⚙️ 開發模式」Section |
| R6 | Clean build 無 error | Archive 前跑一次 Clean Build Folder |
| R7 | 上傳 App Store Connect | Distribute → TestFlight & App Store |
| R8 | 填寫測試說明 | 貼上下方「已知限制」作為 TestFlight What to Test |

---

## 正式數值參考（R2 用）

調回前請確認這些數值：

| 任務 | 目前（測試用）| 建議正式值 |
|---|---|---|
| 採集森林 | ✅ 15分 / 1小時 / 12小時 | 15分 / 1小時 / 12小時 |
| 採集礦坑 | ✅ 15分 / 1小時 / 12小時 | 15分 / 1小時 / 12小時 |
| 鑄造普通 | ✅ 5 / 8 / 10 分鐘 | 5–10 分鐘 |
| 鑄造精良 | ✅ 12 / 15 / 20 分鐘 | 12–20 分鐘 |
| 地下城最短 | ✅ 15 分鐘（已移除 1 分鐘）| 15 分鐘 |
| 地下城最長 | ✅ 12 小時 | 12 小時 |
| 離線上限 | ✅ 12 小時 | 12 小時 |

---

## 已知限制（TestFlight What to Test 文字）

```
【放置英雄 MVP 測試說明】

這是一款純本地單機的放置 RPG，派英雄去地下城冒險，NPC 採集素材、打造裝備。

請測試以下核心循環：
1. 派採集者採集素材
2. 用素材鑄造裝備
3. 裝備後派英雄出征地下城
4. 收下獎勵、升級英雄、挑戰更高區域

已知限制：
- 資料存於本機，刪除 App 即清除，無雲端備份
- 無推播通知，任務完成需手動回到 App 收取
- 離線最長計算 12 小時
- 不支援橫向旋轉
```
