// DungeonProgressionService.swift
// 地下城推進狀態業務邏輯
//
// 責任：
//   查詢面：
//     - isRegionUnlocked()    — 區域是否已解鎖（可挑戰）
//     - isRegionCompleted()   — 區域是否已完成（Boss 層菁英首通）
//     - isFloorUnlocked()     — 樓層是否可挑戰
//     - isFloorCleared()      — 樓層是否已首通（AFK 任務完成過）
//     - isEliteCleared()      — 菁英是否已擊敗（V4-2）
//     - hasSeenBossMaterial() — Boss 材料是否已見過（等同 Boss 層首通）
//
//   變更面：
//     - markFloorCleared()    — 標記 AFK 首通（冪等）；不再觸發區域解鎖
//     - markEliteCleared()    — 標記菁英擊敗（冪等）；觸發下一樓層 / 下一區域解鎖
//
// 解鎖規則（V4-2 更新）：
//   區域解鎖：
//     - wildland（第一區）：預設解鎖
//     - abandoned_mine：wildland Boss 層菁英（elite_wildland_4）擊敗後解鎖
//     - ancient_ruins：abandoned_mine Boss 層菁英擊敗後解鎖
//
//   樓層解鎖（within 已解鎖區域）：
//     - 第 1 層：區域解鎖即可挑戰
//     - 第 N 層（N > 1）：前一層菁英已擊敗才可挑戰
//
//   遷移策略（舊存檔相容）：
//     - 若 clearedFloorKeysJSON 有紀錄但 clearedEliteKeysJSON 為空，
//       自動將已通關樓層視為菁英已擊敗（一次性遷移）

import Foundation
import SwiftData

struct DungeonProgressionService {

    let context: ModelContext
    private let repository: DungeonProgressionRepository

    init(context: ModelContext) {
        self.context    = context
        self.repository = DungeonProgressionRepository(context: context)
    }

    // MARK: - 查詢：區域

    /// 指定區域是否已解鎖（可挑戰）
    func isRegionUnlocked(_ regionKey: String) -> Bool {
        let model = repository.fetch()
        migrateIfNeeded(model)
        return decodeKeys(model?.unlockedRegionKeysJSON).contains(regionKey)
    }

    /// 指定區域是否已完成（Boss 層菁英擊敗後視為完成）
    func isRegionCompleted(_ regionKey: String) -> Bool {
        isEliteCleared(regionKey: regionKey, floorIndex: 4)
    }

    // MARK: - 查詢：樓層

    /// 指定樓層是否可挑戰
    /// 規則（V4-2）：區域已解鎖 AND（floorIndex == 1 OR 前一層菁英已擊敗）
    func isFloorUnlocked(regionKey: String, floorIndex: Int) -> Bool {
        guard isRegionUnlocked(regionKey) else { return false }
        if floorIndex == 1 { return true }
        return isEliteCleared(regionKey: regionKey, floorIndex: floorIndex - 1)
    }

    /// 指定樓層是否已首通（AFK 任務完成過，不論勝負）
    func isFloorCleared(regionKey: String, floorIndex: Int) -> Bool {
        guard let def = DungeonRegionDef.find(key: regionKey),
              let floor = def.floor(index: floorIndex)
        else { return false }
        let model = repository.fetch()
        return decodeKeys(model?.clearedFloorKeysJSON).contains(floor.key)
    }

    /// 指定樓層的菁英是否已擊敗（V4-2 新增）
    func isEliteCleared(regionKey: String, floorIndex: Int) -> Bool {
        guard let def = DungeonRegionDef.find(key: regionKey),
              let floor = def.floor(index: floorIndex)
        else { return false }
        let model = repository.fetch()
        migrateIfNeeded(model)
        return decodeKeys(model?.clearedEliteKeysJSON).contains(floor.key)
    }

    /// Boss 材料是否已見過（等同 Boss 層首通）
    func hasSeenBossMaterial(_ regionKey: String) -> Bool {
        isFloorCleared(regionKey: regionKey, floorIndex: 4)
    }

    /// 直接用 floor key 查詢菁英是否已擊敗（供採集地點解鎖判斷）
    func isEliteCleared(floorKey: String) -> Bool {
        let model = repository.fetch()
        migrateIfNeeded(model)
        return decodeKeys(model?.clearedEliteKeysJSON).contains(floorKey)
    }

    // MARK: - 變更：標記 AFK 首通

    /// 標記 AFK 任務完成（冪等）。
    /// V4-2 起不再觸發區域解鎖（改由 markEliteCleared 負責）。
    func markFloorCleared(regionKey: String, floorIndex: Int) {
        guard let regionDef = DungeonRegionDef.find(key: regionKey),
              let floor = regionDef.floor(index: floorIndex)
        else {
            print("[DungeonProgressionService] 找不到樓層定義：\(regionKey) floor \(floorIndex)")
            return
        }

        let model = repository.fetchOrCreate()
        migrateIfNeeded(model)

        var cleared = decodeKeys(model.clearedFloorKeysJSON)
        guard !cleared.contains(floor.key) else { return }

        cleared.insert(floor.key)
        model.clearedFloorKeysJSON = encodeKeys(cleared)

        print("[DungeonProgressionService] AFK 首通：\(floor.name)（\(floor.key)）")

        repository.save()
    }

    // MARK: - 變更：標記菁英擊敗（V4-2）

    /// 標記菁英擊敗（冪等）。
    /// - F1–F3 菁英擊敗 → 解鎖同區下一層
    /// - F4（Boss 層）菁英擊敗 → 解鎖下一區域
    func markEliteCleared(regionKey: String, floorIndex: Int) {
        guard let regionDef = DungeonRegionDef.find(key: regionKey),
              let floor = regionDef.floor(index: floorIndex)
        else {
            print("[DungeonProgressionService] 找不到樓層定義：\(regionKey) floor \(floorIndex)")
            return
        }

        let model = repository.fetchOrCreate()
        migrateIfNeeded(model)

        var cleared = decodeKeys(model.clearedEliteKeysJSON)
        guard !cleared.contains(floor.key) else { return }

        cleared.insert(floor.key)
        model.clearedEliteKeysJSON = encodeKeys(cleared)

        print("[DungeonProgressionService] 菁英擊敗：\(floor.name)（\(floor.key)）")

        // Boss 層菁英 → 解鎖下一區域
        if floor.isBossFloor {
            unlockNextRegion(after: regionKey, model: model)
        }

        repository.save()
    }

    // MARK: - Private：區域解鎖

    private func unlockNextRegion(after regionKey: String, model: DungeonProgressionModel) {
        let allRegions = DungeonRegionDef.all
        guard
            let currentIndex = allRegions.firstIndex(where: { $0.key == regionKey }),
            currentIndex + 1 < allRegions.count
        else { return }

        let nextRegion = allRegions[currentIndex + 1]
        var unlocked = decodeKeys(model.unlockedRegionKeysJSON)

        guard !unlocked.contains(nextRegion.key) else { return }
        unlocked.insert(nextRegion.key)
        model.unlockedRegionKeysJSON = encodeKeys(unlocked)

        print("[DungeonProgressionService] 解鎖新區域：\(nextRegion.name)（\(nextRegion.key)）")
    }

    // MARK: - Private：舊存檔遷移

    /// 若玩家已有 AFK 首通紀錄但菁英紀錄為空，自動遷移（一次性）。
    /// 保障舊存檔玩家升級後進度不斷。
    @discardableResult
    private func migrateIfNeeded(_ model: DungeonProgressionModel?) -> Bool {
        guard let model else { return false }

        let eliteCleared = decodeKeys(model.clearedEliteKeysJSON)
        guard eliteCleared.isEmpty else { return false }  // 已有菁英紀錄，無需遷移

        let floorCleared = decodeKeys(model.clearedFloorKeysJSON)
        guard !floorCleared.isEmpty else { return false }  // 無 AFK 紀錄，也無需遷移

        // 將已通關的樓層 key 複製到菁英紀錄
        model.clearedEliteKeysJSON = encodeKeys(floorCleared)

        // 補充區域解鎖：確保已通關 Boss 層的下一區域已解鎖
        for regionDef in DungeonRegionDef.all {
            if floorCleared.contains("\(regionDef.key)_floor_4") {
                unlockNextRegion(after: regionDef.key, model: model)
            }
        }

        repository.save()
        print("[DungeonProgressionService] 舊存檔遷移完成：菁英進度已同步")
        return true
    }

    // MARK: - Private：JSON 編解碼

    private func decodeKeys(_ json: String?) -> Set<String> {
        guard
            let json,
            let data = json.data(using: .utf8),
            let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(array)
    }

    private func encodeKeys(_ set: Set<String>) -> String {
        guard
            let data = try? JSONEncoder().encode(Array(set).sorted()),
            let str = String(data: data, encoding: .utf8)
        else { return "[]" }
        return str
    }
}
