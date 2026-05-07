// NotificationService.swift
// 本地通知排程與取消（V8-2 T05）
//
// 純靜態工具，不需 ModelContext。
// 呼叫方：TaskCreationService（排程）、TaskClaimService（取消）

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

        let fireDate = task.endsAt
        guard fireDate > Date() else { return }

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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
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
            return "\(name)回來了，帶回大量素材！"
        case .craft:
            let name = CraftRecipeDef.find(key: task.definitionKey)?.name ?? "裝備"
            return "\(name)鑄造完成，等待收取！"
        case .cuisine:
            let name = CuisineDef.find(task.definitionKey)?.name ?? "料理"
            return "\(name)烹飪完成，新鮮上桌！"
        case .alchemy:
            let name = PotionDef.find(task.definitionKey)?.name ?? "藥水"
            return "\(name)煉製完成，加入背包！"
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
