// MaterialInventoryModel.swift
// 玩家素材庫存的持久化模型（全域單例）

import Foundation
import SwiftData

@Model
final class MaterialInventoryModel {

    var wood: Int
    var ore: Int
    var hide: Int
    var crystalShard: Int
    var ancientFragment: Int

    init(
        wood: Int = AppConstants.Initial.wood,
        ore: Int = AppConstants.Initial.ore,
        hide: Int = 0,
        crystalShard: Int = 0,
        ancientFragment: Int = 0
    ) {
        self.wood            = wood
        self.ore             = ore
        self.hide            = hide
        self.crystalShard    = crystalShard
        self.ancientFragment = ancientFragment
    }

    // MARK: - 便利存取（依 MaterialType 讀寫）

    func amount(of material: MaterialType) -> Int {
        switch material {
        case .wood:            return wood
        case .ore:             return ore
        case .hide:            return hide
        case .crystalShard:    return crystalShard
        case .ancientFragment: return ancientFragment
        }
    }

    func add(_ amount: Int, of material: MaterialType) {
        switch material {
        case .wood:            wood            += amount
        case .ore:             ore             += amount
        case .hide:            hide            += amount
        case .crystalShard:    crystalShard    += amount
        case .ancientFragment: ancientFragment += amount
        }
    }

    /// 嘗試扣除素材，若不足回傳 false
    @discardableResult
    func deduct(_ amount: Int, of material: MaterialType) -> Bool {
        let current = self.amount(of: material)
        guard current >= amount else { return false }
        switch material {
        case .wood:            wood            -= amount
        case .ore:             ore             -= amount
        case .hide:            hide            -= amount
        case .crystalShard:    crystalShard    -= amount
        case .ancientFragment: ancientFragment -= amount
        }
        return true
    }
}
