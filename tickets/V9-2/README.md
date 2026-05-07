# V9-2：Grid 卡片視覺重設計

**主題：** 將 Base NPC 列表、角色裝備槽、背包裝備從 List Row 全面升級為 Grid 卡片佈局；探索分頁地區改為全寬橫幅卡片，全面提升圖像識別度與視覺清晰度。

**依賴：**
- V9-1 T04 NPC WebP 圖片需先完成（T01、T04 依賴）
- V9-1 T03 Region WebP 圖片需先完成（T05 依賴）

---

## Ticket 清單

| # | 票號 | 標題 | 狀態 | 依賴 |
|---|---|---|---|---|
| 1 | T01 | Base NPC Grid 卡片化 | 📋 規劃中 | V9-1 T04 NPC 圖片 |
| 2 | T02 | 角色裝備槽 Grid 卡片化 | 📋 規劃中 | 無 |
| 3 | T03 | 背包裝備 Grid 卡片化 | 📋 規劃中 | 無 |
| 4 | T04 | 採集者詳細頁視覺升級 | 📋 規劃中 | V9-1 T04 NPC 圖片 |
| 5 | T05 | 探索分頁地區卡片視覺升級 | 📋 規劃中 | V9-1 T03 Region 圖片 |

---

## 建議實作順序

```
無依賴先做：
T02（裝備槽 Grid）
T03（背包 Grid）

V9-1 T04 NPC 圖片到位後：
T01（Base NPC Grid）
T04（採集者詳細頁）

V9-1 T03 Region 圖片到位後：
T05（探索地區橫幅卡片）
```

---

## 修改檔案總覽

| 檔案 | 涉及 Tickets |
|---|---|
| `Views/BaseView.swift` | T01 |
| `Views/CharacterView.swift` | T02、T03 |
| `Views/GathererDetailSheet.swift` | T04 |
| `Views/AdventureView.swift` | T05 |
| `ViewModels/AdventureViewModel.swift` | T05（新增 `clearedFloorCount` helper）|
