# V8-2 Ticket 05：本地推播通知（任務完成提醒）

**狀態：** 🔲 待實作

**依賴：** 無

---

## 目標

閒置遊戲的核心留存機制：任務在背景完成時，發送本地通知告知玩家回來收取。  
完全使用 `UNUserNotificationCenter`，無後端，純本地實作。

---

## 通知規格

| 任務類型 | 標題 | 內文 |
|----------|------|------|
| `.gather` | 「採集完成」| 「採集者 \(npcName) 回來了，素材帶回基地！」|
| `.craft` | 「鑄造完成」| 「\(recipeName) 已完成，等待收取！」|
| `.cuisine` | 「料理完成」| 「\(cuisineName) 烹飪完成，新鮮上桌！」|
| `.alchemy` | 「煉藥完成」| 「\(potionName) 煉製完成，加入背包！」|
| `.farming` | 「農田豐收」| 「農田已有作物等待收穫！」|
| `.dungeon` | 「出征結束」| 「英雄從 \(floorName) 回來了！」|

通知排程時間：`task.endsAt`  
通知 ID：`"task_\(task.id.uuidString)"`（用於精準取消）

---

## 修改細節

### Step 1：新增 `Services/NotificationService.swift`

```swift
import UserNotifications

struct NotificationService {

    // MARK: - 權限申請（首次建立任務時呼叫一次）

    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { _, _ in }
        }
    }

    // MARK: - 排程

    static func schedule(for task: TaskModel) {
        let content   = UNMutableNotificationContent()
        content.title = title(for: task)
        content.body  = body(for: task)
        content.sound = .default

        let fireDate  = task.endsAt
        guard fireDate > Date() else { return }  // 已過期不排程

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - 取消

    static func cancel(for task: TaskModel) {
        let id = "task_\(task.id.uuidString)"
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
        // 同時清除已送達的通知（避免收取後通知中心仍留存舊訊息）
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [id])
    }

    // MARK: - Private helpers

    private static func title(for task: TaskModel) -> String {
        switch task.kind {
        case .gather:  return "採集完成"
        case .craft:   return "鑄造完成"
        case .cuisine: return "料理完成"
        case .alchemy: return "煉藥完成"
        case .farming: return "農田豐收"
        case .dungeon: return "出征結束"
        }
    }

    private static func body(for task: TaskModel) -> String {
        switch task.kind {
        case .gather:
            let name = GathererNpcDef.displayName(for: task.actorKey) ?? "採集者"
            return "\(name) 回來了，帶回大量素材！"
        case .craft:
            let name = CraftRecipeDef.find(key: task.definitionKey)?.name ?? "裝備"
            return "\(name) 鑄造完成，等待收取！"
        case .cuisine:
            let name = CuisineDef.find(task.definitionKey)?.name ?? "料理"
            return "\(name) 烹飪完成，新鮮上桌！"
        case .alchemy:
            let name = PotionDef.find(task.definitionKey)?.name ?? "藥水"
            return "\(name) 煉製完成，加入背包！"
        case .farming:
            return "農田已有作物等待收穫！"
        case .dungeon:
            let allFloors = DungeonRegionDef.all.flatMap { $0.floors }
            let floorName = allFloors.first { $0.key == task.definitionKey }?.name
                         ?? DungeonAreaDef.find(key: task.definitionKey)?.name
                         ?? "地下城"
            return "英雄從\(floorName)回來了！"
        }
    }
}
```

> **實作前先確認 `GathererNpcDef.displayName(for:)` 是否存在**（grep `GathererNpcDef`）。
> 若不存在，在 `GathererNpcDef.swift` 新增此靜態方法（輸入 actorKey，回傳 displayName）；若找不到對應資料，`body` 裡的 fallback `"採集者"` 已可保護。

### Step 2：`Services/TaskCreationService.swift` — 排程通知

在每個 `create*Task` 方法最後（`repository.insert(task)` 之後），加入：

```swift
NotificationService.requestPermissionIfNeeded()
NotificationService.schedule(for: task)
```

> **注意**：`TaskCreationService` 有兩個地下城方法，兩個都要加：
> - `createDungeonFloorTask`（V2-1 樓層路徑）
> - `createDungeonTask`（V1 區域路徑）
>
> 實際儲存在 `repository.insert(task)` 內部完成，不是 `try? context.save()`；呼叫點緊接在 `repository.insert(task)` 後即可。

### Step 3：`Services/TaskClaimService.swift` — 取消通知

在 `claimAllCompleted()` 的每個任務處理迴圈中，收下前取消通知：

```swift
for task in completedTasks {
    NotificationService.cancel(for: task)
    // ... 原本的收取邏輯 ...
}
```

### Step 4：`Info.plist` — 不需修改

`NSUserNotificationUsageDescription` 是 macOS 的 key，iOS 不需要在 Info.plist 宣告通知使用說明。
iOS 的通知授權透過 `requestAuthorization` 彈窗處理，無需 plist key。此步驟可跳過。

---

## 修改檔案

- `Services/NotificationService.swift`（新增）
- `StaticData/GathererNpcDef.swift`（確認或補充 `displayName(for:)` 靜態方法）
- `Services/TaskCreationService.swift`（6 個 `create*Task` 方法全部加排程，包含兩個地下城方法）
- `Services/TaskClaimService.swift`

## 設計決策記錄

| 議題 | 決策 | 理由 |
|------|------|------|
| `removeDeliveredNotifications` | 加入 `cancel(for:)` | 玩家回前台收取後，通知中心不應留存舊訊息 |
| `NSUserNotificationUsageDescription` | 不加 | 這是 macOS key，iOS 無效；授權走 `requestAuthorization` |
| 前台通知顯示 | 不處理（留 TODO） | 正常遊戲場景最短任務 5 分鐘，App 常駐前台機率極低 |
| 用戶拒絕授權 | graceful degradation | iOS 不允許重複請求，靜默失敗為合理設計 |

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 首次開始任務時，系統彈出通知授權請求
- [ ] 授權後，任務建立後在手機通知中心可見對應排程（時間正確）
- [ ] 收取任務後，對應通知從排程中消失
- [ ] App 在背景時，任務到期自動送達通知（文字內容符合規格）
- [ ] 通知 ID 不重複（不同 task 不會互相取消）
- [ ] 用戶拒絕授權後，不影響任何遊戲功能（graceful degradation）
