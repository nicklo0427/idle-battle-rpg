// PlayerStateService.swift
// 玩家狀態資料查詢入口
//
// 責任：PlayerStateModel 的讀取。
// 寫入操作（等級提升、點數分配）留待 Phase 4 ViewModel 需要時再擴充。

import Foundation
import SwiftData

struct PlayerStateService {

    let context: ModelContext

    // MARK: - 查詢

    /// 回傳玩家狀態單例；seeding 後正常情況下不會為 nil
    func fetchPlayer() -> PlayerStateModel? {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        return (try? context.fetch(descriptor))?.first
    }
}
