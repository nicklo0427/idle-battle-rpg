// DungeonProgressionService.swift
// 地下城推進狀態業務邏輯
//
// 責任：
//   查詢面：
//     - isRegionUnlocked()    — 區域是否已解鎖（可挑戰）
//     - isRegionCompleted()   — 區域是否已完成（Boss 層首通）
//     - isFloorUnlocked()     — 樓層是否可挑戰
//     - isFloorCleared()      — 樓層是否已首通
//     - hasSeenBossMaterial() — Boss 材料是否已見過（等同 Boss 層首通）
//
//   變更面：
//     - markFloorCleared()    — 標記首通（冪等）；Boss 層首通時自動解鎖下一區
//
// 解鎖規則（最小規則集）：
//   區域解鎖：
//     - wildland（第一區）：預設解鎖
//     - abandoned_mine（第二區）：wildland Boss 層（floor_4）首通後解鎖
//     - ancient_ruins（第三區）：abandoned_mine Boss 層首通後解鎖
//
//   樓層解鎖（within 已解鎖區域）：
//     - 第 1 層：區域解鎖即可挑戰
//     - 第 N 層（N > 1）：前一層已首通才可挑戰
//
//   區域完成：Boss 層（floorIndex == 4）首通 = 區域完成
//   Boss 材料已見過：等同 Boss 層首通（hasSeenBossMaterial == isRegionCompleted）
//
// 注意：
//   - markFloorCleared() 是冪等的；重複呼叫不會重複計算首通
//   - 所有查詢方法可在無 SwiftUI 環境下直接單元測試

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
    /// - 全部區域永遠可見，只有已解鎖的才可點「出發」
    func isRegionUnlocked(_ regionKey: String) -> Bool {
        let model = repository.fetch()
        return decodeKeys(model?.unlockedRegionKeysJSON).contains(regionKey)
    }

    /// 指定區域是否已完成（Boss 層首通後視為完成）
    func isRegionCompleted(_ regionKey: String) -> Bool {
        isFloorCleared(regionKey: regionKey, floorIndex: 4)
    }

    // MARK: - 查詢：樓層

    /// 指定樓層是否可挑戰
    /// 規則：區域已解鎖 AND（floorIndex == 1 OR 前一層已首通）
    func isFloorUnlocked(regionKey: String, floorIndex: Int) -> Bool {
        guard isRegionUnlocked(regionKey) else { return false }
        if floorIndex == 1 { return true }
        return isFloorCleared(regionKey: regionKey, floorIndex: floorIndex - 1)
    }

    /// 指定樓層是否已首通（首通：任務完成一次即記錄，不論勝負場次）
    func isFloorCleared(regionKey: String, floorIndex: Int) -> Bool {
        guard let def = DungeonRegionDef.find(key: regionKey),
              let floor = def.floor(index: floorIndex)
        else { return false }
        let model = repository.fetch()
        return decodeKeys(model?.clearedFloorKeysJSON).contains(floor.key)
    }

    /// Boss 材料是否已見過（等同 Boss 層首通）
    func hasSeenBossMaterial(_ regionKey: String) -> Bool {
        isFloorCleared(regionKey: regionKey, floorIndex: 4)
    }

    // MARK: - 變更：標記首通

    /// 標記指定樓層首通。若已首通則跳過（冪等）。
    /// Boss 層首通時，自動解鎖下一個區域。
    ///
    /// - Parameters:
    ///   - regionKey:  區域 key（e.g. "wildland"）
    ///   - floorIndex: 樓層索引（1–4）
    func markFloorCleared(regionKey: String, floorIndex: Int) {
        guard let regionDef = DungeonRegionDef.find(key: regionKey),
              let floor = regionDef.floor(index: floorIndex)
        else {
            print("[DungeonProgressionService] 找不到樓層定義：\(regionKey) floor \(floorIndex)")
            return
        }

        let model = repository.fetchOrCreate()

        // 冪等：已首通則直接返回
        var cleared = decodeKeys(model.clearedFloorKeysJSON)
        guard !cleared.contains(floor.key) else { return }

        cleared.insert(floor.key)
        model.clearedFloorKeysJSON = encodeKeys(cleared)

        print("[DungeonProgressionService] 首通：\(floor.name)（\(floor.key)）")

        // Boss 層首通 → 解鎖下一區
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
