// EquipmentService.swift
// 裝備查詢與裝備操作入口
//
// 責任：EquipmentModel 的讀取、裝備、卸除。
// 規則：同一部位只能同時裝備一件，equip() 會自動卸除舊件後裝備新件。

import Foundation
import SwiftData

struct EquipmentService {

    let context: ModelContext

    // MARK: - 查詢

    func fetchAll() -> [EquipmentModel] {
        let descriptor = FetchDescriptor<EquipmentModel>()
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchEquipped() -> [EquipmentModel] {
        fetchAll().filter { $0.isEquipped }
    }

    // MARK: - 裝備操作

    /// 裝備指定裝備。若同部位已有裝備，先卸除再裝備新件。
    func equip(_ equipment: EquipmentModel) {
        for existing in fetchEquipped() where existing.slot == equipment.slot {
            existing.isEquipped = false
        }
        equipment.isEquipped = true
        save()
    }

    func unequip(_ equipment: EquipmentModel) {
        equipment.isEquipped = false
        save()
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
