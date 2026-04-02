// TaskCountdown.swift
// 任務剩餘時間格式化工具（共用，無副作用）
//
// 使用方式：
//   TaskCountdown.remaining(for: task, relativeTo: appState.tick)
//
// 格式規則：
//   ≥ 1 小時  → "H:mm:ss"   （例：1:23:45）
//   < 1 小時  → "mm:ss"     （例：23:45）
//   已到期    → "即將完成"

import Foundation

enum TaskCountdown {

    /// 回傳倒數字串。`now` 預設為當前時間；傳入 `appState.tick` 可驅動即時更新。
    static func remaining(for task: TaskModel, relativeTo now: Date = .now) -> String {
        let secs = Int(max(0, task.endsAt.timeIntervalSince(now)))
        guard secs > 0 else { return "即將完成" }

        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60

        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
