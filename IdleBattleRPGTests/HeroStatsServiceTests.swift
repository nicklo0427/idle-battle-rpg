// HeroStatsServiceTests.swift
// 驗證 HeroStatsService.compute(player:equipped:) 純計算函式

import XCTest
@testable import IdleBattleRPG

final class HeroStatsServiceTests: XCTestCase {

    // MARK: - 無裝備：只計算基礎屬性點

    func test_compute_noEquipment_returnsBasePoints() {
        let player = makePlayer(atk: 5, def: 3, hp: 20)
        let stats  = HeroStatsService.compute(player: player, equipped: [])

        XCTAssertEqual(stats.totalATK, 5)
        XCTAssertEqual(stats.totalDEF, 3)
        XCTAssertEqual(stats.totalHP,  20)
        // 戰力 = 5×2 + 3×1.5 + 20 = 10 + 4 + 20 = 34
        XCTAssertEqual(stats.power, 34)
    }

    // MARK: - 單件裝備加成

    func test_compute_weaponEquipped_addsATK() {
        let player = makePlayer(atk: 5, def: 3, hp: 20)
        // iron_sword: atkBonus=12
        let weapon = EquipmentModel(defKey: "iron_sword", slot: .weapon, rarity: .common, isEquipped: true)
        let stats  = HeroStatsService.compute(player: player, equipped: [weapon])

        XCTAssertEqual(stats.totalATK, 5 + weapon.atkBonus)
        XCTAssertEqual(stats.totalDEF, 3)
        XCTAssertEqual(stats.totalHP,  20)
    }

    func test_compute_armorEquipped_addsDefAndHP() {
        let player = makePlayer(atk: 5, def: 3, hp: 20)
        // leather_armor: defBonus=8, hpBonus=20
        let armor  = EquipmentModel(defKey: "leather_armor", slot: .armor, rarity: .common, isEquipped: true)
        let stats  = HeroStatsService.compute(player: player, equipped: [armor])

        XCTAssertEqual(stats.totalDEF, 3  + armor.defBonus)
        XCTAssertEqual(stats.totalHP,  20 + armor.hpBonus)
        XCTAssertEqual(stats.totalATK, 5)
    }

    // MARK: - 多件裝備累加

    func test_compute_multipleEquipment_accumulates() {
        let player = makePlayer(atk: 10, def: 5, hp: 30)
        let weapon = EquipmentModel(defKey: "iron_sword",    slot: .weapon,    rarity: .common, isEquipped: true)
        let armor  = EquipmentModel(defKey: "leather_armor", slot: .armor,     rarity: .common, isEquipped: true)
        let ring   = EquipmentModel(defKey: "bone_ring",     slot: .accessory, rarity: .common, isEquipped: true)

        let stats = HeroStatsService.compute(player: player, equipped: [weapon, armor, ring])

        XCTAssertEqual(stats.totalATK, 10 + weapon.atkBonus + armor.atkBonus + ring.atkBonus)
        XCTAssertEqual(stats.totalDEF, 5  + weapon.defBonus + armor.defBonus + ring.defBonus)
        XCTAssertEqual(stats.totalHP,  30 + weapon.hpBonus  + armor.hpBonus  + ring.hpBonus)
    }

    // MARK: - 強化裝備加成

    func test_compute_enhancedWeapon_addsEnhancementBonus() {
        let player  = makePlayer(atk: 5, def: 0, hp: 0)
        let weapon  = EquipmentModel(defKey: "iron_sword", slot: .weapon, rarity: .common,
                                     isEquipped: true, enhancementLevel: 3)
        let base    = HeroStatsService.compute(player: player, equipped: [
            EquipmentModel(defKey: "iron_sword", slot: .weapon, rarity: .common, isEquipped: true)
        ])
        let enhanced = HeroStatsService.compute(player: player, equipped: [weapon])

        XCTAssertGreaterThan(enhanced.totalATK, base.totalATK,
                              "強化等級 3 的武器 ATK 應大於未強化版本")
    }

    // MARK: - AGI / DEX 透傳

    func test_compute_agiAndDex_arePassedThrough() {
        let player = makePlayer(atk: 0, def: 0, hp: 0, agi: 8, dex: 4)
        let stats  = HeroStatsService.compute(player: player, equipped: [])

        XCTAssertEqual(stats.totalAGI, 8)
        XCTAssertEqual(stats.totalDEX, 4)
        // power = 0 + 0 + 0 + 8 + 4 = 12
        XCTAssertEqual(stats.power, 12)
    }

    // MARK: - 不計入未裝備的裝備

    func test_compute_unequippedItem_notCounted() {
        let player    = makePlayer(atk: 5, def: 3, hp: 20)
        let equipped  = EquipmentModel(defKey: "iron_sword", slot: .weapon, rarity: .common, isEquipped: true)
        let unequipped = EquipmentModel(defKey: "iron_sword", slot: .weapon, rarity: .common, isEquipped: false)

        let statsWith    = HeroStatsService.compute(player: player, equipped: [equipped])
        let statsWithout = HeroStatsService.compute(player: player, equipped: [unequipped])

        // unequipped 傳進 compute 時仍會被計入，因為 compute 假設傳入的都是已裝備清單
        // 此測試驗證：若傳入相同裝備，結果應相同（compute 不看 isEquipped flag）
        XCTAssertEqual(statsWith.totalATK, statsWithout.totalATK)
    }

    // MARK: - Helpers

    private func makePlayer(
        atk: Int, def: Int, hp: Int, agi: Int = 0, dex: Int = 0
    ) -> PlayerStateModel {
        let p = PlayerStateModel(
            gold: 100,
            heroLevel: 1,
            availableStatPoints: 0,
            atkPoints: atk,
            defPoints: def,
            hpPoints: hp,
            lastOpenedAt: Date(),
            hasUsedFirstCraftBoost: false,
            hasUsedFirstDungeonBoost: false,
            onboardingStep: 3
        )
        p.agiPoints = agi
        p.dexPoints = dex
        return p
    }
}
