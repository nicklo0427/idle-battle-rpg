# V10-3 Ticket 01：引導 UX 問題審查與重構方向

## 問題描述

目前 onboardingStep 0–7 的引導流程存在三類問題：

1. **畫面太亂**：引導橫幅與原有 UI 層疊，某些步驟同時出現兩份指引文字
2. **按鈕太多**：引導專屬按鈕與原生操作按鈕並存，玩家不知道要按哪個
3. **引導按鈕應整合進原生 UI**：不應有獨立的「引導任務」捷徑按鈕，應讓玩家透過真實操作流程完成引導

---

## 現況完整清單

### Step 0 — GathererDetailSheet（gatherer_1）
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialDispatchSection`「派遣採集（2 秒）」| ❌ 獨立引導按鈕 | 與下方正常地點列表重複 |
| 正常地點列表（dispatchSection）| ✅ 原生 UI | 功能相同，兩者並存 |

### Step 1 — 等待採集
| 元素 | 類型 | 問題 |
|---|---|---|
| tutorialHintBanner | ✅ 純提示，無互動 | 無問題 |

### Step 2 — CraftSheet（blacksmith）
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialCraftSection`「打造初始武器（2 秒）」| ❌ 獨立引導按鈕 | 與下方配方列表重複 |
| 正常配方列表（recipeSection）| ✅ 原生 UI | 功能相同，兩者並存 |

### Step 3 — CharacterView 裝備
| 元素 | 類型 | 問題 |
|---|---|---|
| tutorialHintBanner（進入角色頁確認武器已裝備）| ✅ 純提示 | 無問題 |
| 裝備欄位（正常 UI）| ✅ 原生 UI | 無問題 |

### Step 4 — AdventureView
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialStep4BannerSection`（🎯 引導任務）| ❌ 重複橫幅 | 與 tutorialHintBanner 文字幾乎相同，同時顯示 |
| tutorialHintBanner（BaseView 頂部）| ✅ 主要提示 | 已足夠 |
| 正常地下城列表 | ✅ 原生 UI | 無問題 |

### Step 5 — TailorSheet（素材不足）
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialInsufficientMaterialsSection` 文字提示 | ✅ 情境說明 | 可接受 |
| 「前往荒野探索 →」tab 切換按鈕 | ⚠️ 引導導覽按鈕 | **待討論**（見 Ticket 03） |

### Step 6 — AdventureView（探索獲材）
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialStep6ExploreSection`「金穗之野探索（2 秒）」| ❌ 獨立引導按鈕 | 與下方正常地下城列表重複 |
| 正常地下城列表（所有區域全顯示）| ✅/⚠️ 原生 UI | 功能重複，且顯示太多無關區域 |

### Step 7 — TailorSheet（打造防具）
| 元素 | 類型 | 問題 |
|---|---|---|
| `tutorialCraftArmorSection`「打造初始防具（2 秒）」| ❌ 獨立引導按鈕 | 與下方配方列表重複 |
| 正常配方列表 | ✅ 原生 UI | 功能相同，兩者並存 |

---

## 拆分為三個執行 Ticket

| Ticket | 主題 | 複雜度 |
|---|---|---|
| Ticket 02 | 移除 step 4 重複橫幅（最簡單，立即執行） | 低 |
| Ticket 03 | Step 5「前往荒野探索」導覽按鈕處理方式（需決策） | 中 |
| Ticket 04 | 引導按鈕整合進原生 UI（主要工程，steps 0/2/6/7） | 高 |
