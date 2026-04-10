// EliteDef.swift
// V4-2 菁英系統：每樓層的菁英敵人靜態定義
// 靜態資料，不進 SwiftData
//
// 結構：
//   EliteDef — 每樓層一個菁英（3 區 × 4 樓層 = 12 個）
//
// 數值設計原則：
//   菁英 HP ≈ 一般推薦戰力 × 3（比普通小怪 ×2 更硬）
//   菁英 ATK ≈ 一般推薦戰力 / 3（傷害明顯更高）
//   菁英 DEF ≈ 一般推薦戰力 / 8
//   最低挑戰戰力 = 樓層推薦戰力 × 1.1（需略高於推薦才能挑戰）
//   金幣獎勵 ≈ 普通場次金幣上限 × 5–8 倍
//   素材獎勵：該樓層的掉落素材 × 固定數量

import Foundation

// MARK: - 菁英獎勵

struct EliteReward {
    let gold:          Int
    let material:      MaterialType
    let materialCount: Int
}

// MARK: - 菁英定義

struct EliteDef: Identifiable {
    var id: String { key }
    let key:               String      // e.g. "elite_wildland_1"
    let name:              String      // 菁英名稱
    let floorKey:          String      // 對應的樓層 key
    let regionKey:         String      // 所屬區域 key
    let floorIndex:        Int         // 1–4
    let lore:              String      // 一句話背景說明
    let minPowerRequired:  Int         // 最低挑戰戰力（低於此無法挑戰）
    let hp:                Int         // 菁英 HP
    let atk:               Int         // 菁英 ATK
    let def:               Int         // 菁英 DEF
    let reward:            EliteReward // 通關獎勵
}

// MARK: - 靜態資料

extension EliteDef {

    static let all: [EliteDef] = [
        // 荒野邊境
        wildland1, wildland2, wildland3, wildland4,
        // 廢棄礦坑
        mine1, mine2, mine3, mine4,
        // 古代遺跡
        ruins1, ruins2, ruins3, ruins4,
        // 沉落王城
        sunken1, sunken2, sunken3, sunken4,
    ]

    static func find(floorKey: String) -> EliteDef? {
        all.first { $0.floorKey == floorKey }
    }

    static func find(regionKey: String, floorIndex: Int) -> EliteDef? {
        all.first { $0.regionKey == regionKey && $0.floorIndex == floorIndex }
    }
}

// MARK: - 荒野邊境菁英

extension EliteDef {

    // F1 推薦戰力 40 → 菁英最低挑戰 44、HP 120、ATK 13、DEF 5
    static let wildland1 = EliteDef(
        key:              "elite_wildland_1",
        name:             "裂爪前哨長",
        floorKey:         "wildland_floor_1",
        regionKey:        "wildland",
        floorIndex:       1,
        lore:             "統領殘木前哨的老兵，身上的裂爪傷痕是每場廝殺的勳章。",
        minPowerRequired: 44,
        hp:               120,
        atk:              13,
        def:              5,
        reward:           EliteReward(gold: 60, material: .oldPostBadge, materialCount: 3)
    )

    // F2 推薦戰力 65 → 最低 72、HP 195、ATK 22、DEF 8
    static let wildland2 = EliteDef(
        key:              "elite_wildland_2",
        name:             "獸紋獵首",
        floorKey:         "wildland_floor_2",
        regionKey:        "wildland",
        floorIndex:       2,
        lore:             "以獸皮纏身的狂戰士，據說曾徒手將裂角獸撕裂。",
        minPowerRequired: 72,
        hp:               195,
        atk:              22,
        def:              8,
        reward:           EliteReward(gold: 90, material: .driedHideBundle, materialCount: 3)
    )

    // F3 推薦戰力 90 → 最低 99、HP 270、ATK 30、DEF 11
    static let wildland3 = EliteDef(
        key:              "elite_wildland_3",
        name:             "邊境斬界者",
        floorKey:         "wildland_floor_3",
        regionKey:        "wildland",
        floorIndex:       3,
        lore:             "遊走於文明邊界的亡命之徒，以斬殺旅人為樂。",
        minPowerRequired: 99,
        hp:               270,
        atk:              30,
        def:              11,
        reward:           EliteReward(gold: 120, material: .splitHornBone, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 120 → 最低 132、HP 360、ATK 40、DEF 15
    static let wildland4 = EliteDef(
        key:              "elite_wildland_4",
        name:             "裂牙掠首・狂怒態",
        floorKey:         "wildland_floor_4",
        regionKey:        "wildland",
        floorIndex:       4,
        lore:             "裂牙掠首在王庭深處甦醒的另一面，怒火燃盡後的最終型態。",
        minPowerRequired: 132,
        hp:               360,
        atk:              40,
        def:              15,
        reward:           EliteReward(gold: 180, material: .riftFangRoyalBadge, materialCount: 2)
    )
}

// MARK: - 廢棄礦坑菁英

extension EliteDef {

    // F1 推薦戰力 155 → 最低 171、HP 465、ATK 52、DEF 19
    static let mine1 = EliteDef(
        key:              "elite_mine_1",
        name:             "礦脈封鎖者",
        floorKey:         "mine_floor_1",
        regionKey:        "abandoned_mine",
        floorIndex:       1,
        lore:             "礦坑最初的管理者，如今只剩下封鎖一切的本能。",
        minPowerRequired: 171,
        hp:               465,
        atk:              52,
        def:              19,
        reward:           EliteReward(gold: 140, material: .mineLampCopperClip, materialCount: 3)
    )

    // F2 推薦戰力 190 → 最低 209、HP 570、ATK 63、DEF 24
    static let mine2 = EliteDef(
        key:              "elite_mine_2",
        name:             "裂層重鑿兵",
        floorKey:         "mine_floor_2",
        regionKey:        "abandoned_mine",
        floorIndex:       2,
        lore:             "以巨型鑿刀為武器，每一擊都能撕裂礦壁。",
        minPowerRequired: 209,
        hp:               570,
        atk:              63,
        def:              24,
        reward:           EliteReward(gold: 180, material: .tunnelIronClip, materialCount: 3)
    )

    // F3 推薦戰力 225 → 最低 248、HP 675、ATK 75、DEF 28
    static let mine3 = EliteDef(
        key:              "elite_mine_3",
        name:             "深坑承脈守將",
        floorKey:         "mine_floor_3",
        regionKey:        "abandoned_mine",
        floorIndex:       3,
        lore:             "深坑礦脈的最後守護者，以礦石鑲嵌全身。",
        minPowerRequired: 248,
        hp:               675,
        atk:              75,
        def:              28,
        reward:           EliteReward(gold: 220, material: .veinStoneSlab, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 260 → 最低 286、HP 780、ATK 87、DEF 33
    static let mine4 = EliteDef(
        key:              "elite_mine_4",
        name:             "深坑吞岩獸・狂嗜態",
        floorKey:         "mine_floor_4",
        regionKey:        "abandoned_mine",
        floorIndex:       4,
        lore:             "吞噬礦核後進入狂嗜狀態的吞岩獸，礦坑的終極威脅。",
        minPowerRequired: 286,
        hp:               780,
        atk:              87,
        def:              33,
        reward:           EliteReward(gold: 320, material: .stoneSwallowCore, materialCount: 2)
    )
}

// MARK: - 古代遺跡菁英

extension EliteDef {

    // F1 推薦戰力 295 → 最低 325、HP 885、ATK 98、DEF 37
    static let ruins1 = EliteDef(
        key:              "elite_ruins_1",
        name:             "外庭誓約衛兵",
        floorKey:         "ruins_floor_1",
        regionKey:        "ancient_ruins",
        floorIndex:       1,
        lore:             "以古老誓約束縛自身的遺跡守衛，誓言令其永不退縮。",
        minPowerRequired: 325,
        hp:               885,
        atk:              98,
        def:              37,
        reward:           EliteReward(gold: 260, material: .relicSealRing, materialCount: 3)
    )

    // F2 推薦戰力 330 → 最低 363、HP 990、ATK 110、DEF 41
    static let ruins2 = EliteDef(
        key:              "elite_ruins_2",
        name:             "碑紋大祭司",
        floorKey:         "ruins_floor_2",
        regionKey:        "ancient_ruins",
        floorIndex:       2,
        lore:             "迴廊深處的祭司首領，以符文詛咒所有入侵者。",
        minPowerRequired: 363,
        hp:               990,
        atk:              110,
        def:              41,
        reward:           EliteReward(gold: 310, material: .oathInscriptionShard, materialCount: 3)
    )

    // F3 推薦戰力 368 → 最低 405、HP 1104、ATK 123、DEF 46
    static let ruins3 = EliteDef(
        key:              "elite_ruins_3",
        name:             "前殿誓約騎士長",
        floorKey:         "ruins_floor_3",
        regionKey:        "ancient_ruins",
        floorIndex:       3,
        lore:             "前殿最後的騎士統帥，以古王遺命為最高指引。",
        minPowerRequired: 405,
        hp:               1104,
        atk:              123,
        def:              46,
        reward:           EliteReward(gold: 360, material: .foreShrineClip, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 410 → 最低 451、HP 1230、ATK 137、DEF 51
    static let ruins4 = EliteDef(
        key:              "elite_ruins_4",
        name:             "王誓執行者・封印解除",
        floorKey:         "ruins_floor_4",
        regionKey:        "ancient_ruins",
        floorIndex:       4,
        lore:             "封印解除後的王誓執行者，古王的怒火在其體內完全甦醒。",
        minPowerRequired: 451,
        hp:               1230,
        atk:              137,
        def:              51,
        reward:           EliteReward(gold: 500, material: .ancientKingCore, materialCount: 2)
    )
}

// MARK: - 沉落王城菁英

extension EliteDef {

    // F1 推薦戰力 530 → 最低 583、HP 1590、ATK 177、DEF 66
    static let sunken1 = EliteDef(
        key:              "elite_sunken_1",
        name:             "沉塔前哨統領",
        floorKey:         "sunken_floor_1",
        regionKey:        "sunken_city",
        floorIndex:       1,
        lore:             "沉落王城入口的最後守衛，腐蝕魔力已滲透其鎧甲與意志。",
        minPowerRequired: 583,
        hp:               1590,
        atk:              177,
        def:              66,
        reward:           EliteReward(gold: 420, material: .sunkenRuneShard, materialCount: 3)
    )

    // F2 推薦戰力 585 → 最低 644、HP 1755、ATK 195、DEF 73
    static let sunken2 = EliteDef(
        key:              "elite_sunken_2",
        name:             "溺殿晶液祭主",
        floorKey:         "sunken_floor_2",
        regionKey:        "sunken_city",
        floorIndex:       2,
        lore:             "以深淵晶液為媒介施術的祭司首領，迴廊中每一滴水都是他的眼睛。",
        minPowerRequired: 644,
        hp:               1755,
        atk:              195,
        def:              73,
        reward:           EliteReward(gold: 510, material: .abyssalCrystalDrop, materialCount: 3)
    )

    // F3 推薦戰力 645 → 最低 710、HP 1935、ATK 215、DEF 81
    static let sunken3 = EliteDef(
        key:              "elite_sunken_3",
        name:             "沉冕王室禁衛長",
        floorKey:         "sunken_floor_3",
        regionKey:        "sunken_city",
        floorIndex:       3,
        lore:             "戴著溺冕的王室最後守護者，誓死捍衛通往沉王聖座的入口。",
        minPowerRequired: 710,
        hp:               1935,
        atk:              215,
        def:              81,
        reward:           EliteReward(gold: 610, material: .drownedCrownFragment, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 710 → 最低 781、HP 2130、ATK 237、DEF 89
    static let sunken4 = EliteDef(
        key:              "elite_sunken_4",
        name:             "沉落王・深淵甦醒（覺醒態）",
        floorKey:         "sunken_floor_4",
        regionKey:        "sunken_city",
        floorIndex:       4,
        lore:             "沉落王城的主宰，深淵之力完全甦醒後的最終型態，幽暗海水在其周圍凝固成刃。",
        minPowerRequired: 781,
        hp:               2130,
        atk:              237,
        def:              89,
        reward:           EliteReward(gold: 850, material: .sunkenKingSeal, materialCount: 2)
    )
}
