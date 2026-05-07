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

    /// 複製並覆蓋戰鬥數值（教程引導戰用）
    func copying(overrideHP: Int, overrideATK: Int, overrideDEF: Int) -> EliteDef {
        EliteDef(
            key:              key,
            name:             name,
            floorKey:         floorKey,
            regionKey:        regionKey,
            floorIndex:       floorIndex,
            lore:             lore,
            minPowerRequired: minPowerRequired,
            hp:               overrideHP,
            atk:              overrideATK,
            def:              overrideDEF,
            reward:           reward
        )
    }
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
        name:             "穀道裂爪衛",
        floorKey:         "wildland_floor_1",
        regionKey:        "wildland",
        floorIndex:       1,
        lore:             "守衛穀倉前道多年的傷痕老兵，身上的裂爪傷痕是每場護糧廝殺的勳章。",
        minPowerRequired: 44,
        hp:               120,
        atk:              13,
        def:              5,
        reward:           EliteReward(gold: 60, material: .oldPostBadge, materialCount: 3)
    )

    // F2 推薦戰力 65 → 最低 72、HP 195、ATK 22、DEF 8
    static let wildland2 = EliteDef(
        key:              "elite_wildland_2",
        name:             "田野獵禍首",
        floorKey:         "wildland_floor_2",
        regionKey:        "wildland",
        floorIndex:       2,
        lore:             "率領獸群掠奪農田的禍首，廢棄農舍中堆滿了其洗劫的穀物與獸骨。",
        minPowerRequired: 72,
        hp:               195,
        atk:              22,
        def:              8,
        reward:           EliteReward(gold: 90, material: .driedHideBundle, materialCount: 3)
    )

    // F3 推薦戰力 90 → 最低 99、HP 270、ATK 30、DEF 11
    static let wildland3 = EliteDef(
        key:              "elite_wildland_3",
        name:             "田界收割者",
        floorKey:         "wildland_floor_3",
        regionKey:        "wildland",
        floorIndex:       3,
        lore:             "被詛咒束縛於穀倉田界的收割者，任何跨越田界的生命都難逃其鐮。",
        minPowerRequired: 99,
        hp:               270,
        atk:              30,
        def:              11,
        reward:           EliteReward(gold: 120, material: .splitHornBone, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 120 → 最低 132、HP 360、ATK 40、DEF 15
    static let wildland4 = EliteDef(
        key:              "elite_wildland_4",
        name:             "穀禍裂牙・狂噬態",
        floorKey:         "wildland_floor_4",
        regionKey:        "wildland",
        floorIndex:       4,
        lore:             "摧毀金穗之野數個豐收季的巨獸，吞盡穀倉後進入無法遏止的狂噬型態。",
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
        name:             "林道截殺者",
        floorKey:         "mine_floor_1",
        regionKey:        "abandoned_mine",
        floorIndex:       1,
        lore:             "古林入口的隱秘獵人，以藤蔓陷阱捕殺入侵者，從未讓獵物逃脫。",
        minPowerRequired: 171,
        hp:               465,
        atk:              52,
        def:              19,
        reward:           EliteReward(gold: 140, material: .mineLampCopperClip, materialCount: 3)
    )

    // F2 推薦戰力 190 → 最低 209、HP 570、ATK 63、DEF 24
    static let mine2 = EliteDef(
        key:              "elite_mine_2",
        name:             "迷林古木傀儡",
        floorKey:         "mine_floor_2",
        regionKey:        "abandoned_mine",
        floorIndex:       2,
        lore:             "被腐化靈氣侵蝕的千年樹精，在迷宮深處守護著古樹最後的記憶。",
        minPowerRequired: 209,
        hp:               570,
        atk:              63,
        def:              24,
        reward:           EliteReward(gold: 180, material: .tunnelIronClip, materialCount: 3)
    )

    // F3 推薦戰力 225 → 最低 248、HP 675、ATK 75、DEF 28
    static let mine3 = EliteDef(
        key:              "elite_mine_3",
        name:             "幽林靈脈守將",
        floorKey:         "mine_floor_3",
        regionKey:        "abandoned_mine",
        floorIndex:       3,
        lore:             "鎮守古林靈脈核心的黑夜獸靈，其嘶吼能令周遭樹木瞬間枯死。",
        minPowerRequired: 248,
        hp:               675,
        atk:              75,
        def:              28,
        reward:           EliteReward(gold: 220, material: .veinStoneSlab, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 260 → 最低 286、HP 780、ATK 87、DEF 33
    static let mine4 = EliteDef(
        key:              "elite_mine_4",
        name:             "腐林吞木獸・狂蝕態",
        floorKey:         "mine_floor_4",
        regionKey:        "abandoned_mine",
        floorIndex:       4,
        lore:             "沉睡於古林王座的遠古神獸，吞噬千年樹心後進入無法抑制的狂蝕狀態。",
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
        name:             "草原前哨斥候長",
        floorKey:         "ruins_floor_1",
        regionKey:        "ancient_ruins",
        floorIndex:       1,
        lore:             "血旗部落的游動斥候首領，以極速奔襲與殘忍手段鎮壓一切入侵者。",
        minPowerRequired: 325,
        hp:               885,
        atk:              98,
        def:              37,
        reward:           EliteReward(gold: 260, material: .relicSealRing, materialCount: 3)
    )

    // F2 推薦戰力 330 → 最低 363、HP 990、ATK 110、DEF 41
    static let ruins2 = EliteDef(
        key:              "elite_ruins_2",
        name:             "遊牧巫祭首領",
        floorKey:         "ruins_floor_2",
        regionKey:        "ancient_ruins",
        floorIndex:       2,
        lore:             "廢棄營地中最後的部落薩滿，以詛咒與鮮血喚醒戰神之力。",
        minPowerRequired: 363,
        hp:               990,
        atk:              110,
        def:              41,
        reward:           EliteReward(gold: 310, material: .oathInscriptionShard, materialCount: 3)
    )

    // F3 推薦戰力 368 → 最低 405、HP 1104、ATK 123、DEF 46
    static let ruins3 = EliteDef(
        key:              "elite_ruins_3",
        name:             "衝鋒鐵甲統帥",
        floorKey:         "ruins_floor_3",
        regionKey:        "ancient_ruins",
        floorIndex:       3,
        lore:             "率領精銳重甲兵衝鋒陷陣的草原統帥，從未嘗過一場敗績。",
        minPowerRequired: 405,
        hp:               1104,
        atk:              123,
        def:              46,
        reward:           EliteReward(gold: 360, material: .foreShrineClip, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 410 → 最低 451、HP 1230、ATK 137、DEF 51
    static let ruins4 = EliteDef(
        key:              "elite_ruins_4",
        name:             "血旗戰令者・狂王附體",
        floorKey:         "ruins_floor_4",
        regionKey:        "ancient_ruins",
        floorIndex:       4,
        lore:             "血旗草原王直屬的戰令執行者，王者怒火完全甦醒後勢不可擋。",
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
        name:             "沙丘哨守統領",
        floorKey:         "sunken_floor_1",
        regionKey:        "sunken_city",
        floorIndex:       1,
        lore:             "把守法老領地入口的不死守衛，在烈日炙烤下永不疲憊、永不倒下。",
        minPowerRequired: 583,
        hp:               1590,
        atk:              177,
        def:              66,
        reward:           EliteReward(gold: 420, material: .sunkenRuneShard, materialCount: 3)
    )

    // F2 推薦戰力 585 → 最低 644、HP 1755、ATK 195、DEF 73
    static let sunken2 = EliteDef(
        key:              "elite_sunken_2",
        name:             "沙暴迴廊祭主",
        floorKey:         "sunken_floor_2",
        regionKey:        "sunken_city",
        floorIndex:       2,
        lore:             "以詛咒符文操控沙暴的法老祭司，每句咒語都能召喚烈焰風沙肆虐。",
        minPowerRequired: 644,
        hp:               1755,
        atk:              195,
        def:              73,
        reward:           EliteReward(gold: 510, material: .abyssalCrystalDrop, materialCount: 3)
    )

    // F3 推薦戰力 645 → 最低 710、HP 1935、ATK 215、DEF 81
    static let sunken3 = EliteDef(
        key:              "elite_sunken_3",
        name:             "法老禁衛統帥",
        floorKey:         "sunken_floor_3",
        regionKey:        "sunken_city",
        floorIndex:       3,
        lore:             "守護法老深墓最後一道門的王室禁衛長，以自身性命為詛咒護盾。",
        minPowerRequired: 710,
        hp:               1935,
        atk:              215,
        def:              81,
        reward:           EliteReward(gold: 610, material: .drownedCrownFragment, materialCount: 3)
    )

    // F4 Boss 層 推薦戰力 710 → 最低 781、HP 2130、ATK 237、DEF 89
    static let sunken4 = EliteDef(
        key:              "elite_sunken_4",
        name:             "焰獄法老・神力覺醒（覺醒態）",
        floorKey:         "sunken_floor_4",
        regionKey:        "sunken_city",
        floorIndex:       4,
        lore:             "在烈陽神座深處覺醒的古老法老，以沙漠之火與詛咒之力對抗一切入侵者。",
        minPowerRequired: 781,
        hp:               2130,
        atk:              237,
        def:              89,
        reward:           EliteReward(gold: 850, material: .sunkenKingSeal, materialCount: 2)
    )
}
