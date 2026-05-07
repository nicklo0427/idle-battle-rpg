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

    /// 依職業定義發放初始裝備並全部裝備（V10-1 職業選擇確認時呼叫）
    func grantStarterEquipment(for classDef: ClassDef) {
        for key in classDef.starterEquipmentKeys {
            guard let def = EquipmentDef.find(key: key) else { continue }
            let item = EquipmentModel(
                defKey:     def.key,
                slot:       def.slot,
                rarity:     def.rarity,
                isEquipped: true
            )
            context.insert(item)
        }
        save()
    }

    /// 教程防具鑄造結算：發放 wildland_armor（精良，已裝備）
    func grantTutorialArmor() {
        guard let def = EquipmentDef.find(key: "wildland_armor") else { return }
        let item = EquipmentModel(
            defKey:     def.key,
            slot:       def.slot,
            rarity:     .refined,
            isEquipped: true
        )
        context.insert(item)
        save()
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
