// HeroStatsService.swift
// 英雄總屬性與戰力計算
//
// 純計算層，不含副作用。
// compute(player:equipped:) 是靜態純函式，可在無 SwiftUI 環境下直接單元測試。
// fetchAndCompute(context:) 是便利方法，從 ModelContext 讀取後委派給純計算函式。

import Foundation
import SwiftData

struct HeroStatsService {

    // MARK: - 純計算（testable，不需 ModelContext）

    /// 聚合基礎點數 + 裝備加成，回傳 HeroStats value type
    static func compute(
        player: PlayerStateModel,
        equipped: [EquipmentModel]
    ) -> HeroStats {
        var atk = player.atkPoints
        var def = player.defPoints
        var hp  = player.hpPoints

        for equip in equipped {
            atk += equip.atkBonus
            def += equip.defBonus
            hp  += equip.hpBonus
        }

        let base = HeroStats(totalATK: atk, totalDEF: def, totalHP: hp,
                             totalAGI: player.agiPoints, totalDEX: player.dexPoints)

        // V6-1：套用職業基礎加成（classKey 為空時跳過，相容舊存檔）
        guard let classDef = ClassDef.find(key: player.classKey) else { return base }
        return base.applying(classDef: classDef)
    }

    // MARK: - 從 ModelContext 讀取並計算

    /// 從 context 讀取玩家資料與已裝備裝備，委派給 compute(player:equipped:)
    /// 若尚無玩家資料，回傳零值（正常情況下 seeding 後不會發生）
    static func fetchAndCompute(context: ModelContext) -> HeroStats {
        guard let player = fetchPlayer(context: context) else {
            return HeroStats(totalATK: 0, totalDEF: 0, totalHP: 0)
        }
        let equipped = fetchEquipped(context: context)
        return compute(player: player, equipped: equipped)
    }

    // MARK: - Private

    private static func fetchPlayer(context: ModelContext) -> PlayerStateModel? {
        let descriptor = FetchDescriptor<PlayerStateModel>()
        return (try? context.fetch(descriptor))?.first
    }

    private static func fetchEquipped(context: ModelContext) -> [EquipmentModel] {
        let descriptor = FetchDescriptor<EquipmentModel>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.isEquipped }
    }
}
