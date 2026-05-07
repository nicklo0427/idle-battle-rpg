// NpcIntroDef.swift
// V10-1 NPC 首次對話靜態定義

import Foundation

struct NpcIntroDef {
    let actorKey:    String   // 對應 TaskModel.actorKey
    let defaultName: String   // 系統預設名（玩家命名前顯示）
    let introLine:   String   // 首次對話台詞
}

extension NpcIntroDef {

    static let all: [NpcIntroDef] = [
        NpcIntroDef(
            actorKey:    "gatherer_1",
            defaultName: "石頭",
            introLine:   "嘿，你終於醒了。是我在森林邊緣找到你的——半埋在廢石裡，差點沒認出是個人。叫我石頭就好，需要採集，找我。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_2",
            defaultName: "二毛",
            introLine:   "哦，廢墟撿回來的？我是採集者，跑腿的活交給我。不用謝，反正我閒著也是閒著。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_3",
            defaultName: "藥草婆",
            introLine:   "這些草藥我認識，你身上的傷多虧了它們才好得快。我採草藥採了幾十年，叫我藥草婆就好。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_4",
            defaultName: "魚仔",
            introLine:   "嗯，你醒了啊。我一天到晚在溪邊，魚比人好說話。需要魚就找我，不需要也沒關係。"
        ),
        NpcIntroDef(
            actorKey:    "farmer",
            defaultName: "老農",
            introLine:   "孩子，你算是命大。我在這片土地耕種了大半輩子，見過不少倒在荒野的人，能活著醒來的沒幾個。"
        ),
        NpcIntroDef(
            actorKey:    "blacksmith",
            defaultName: "老鐵",
            introLine:   "嗯，你的劍我看過了，再打幾場就廢了。我是鑄造師，什麼料到我手上都能變成裝備。把素材給我，我替你打。"
        ),
        NpcIntroDef(
            actorKey:    "chef",
            defaultName: "阿廚",
            introLine:   "哎，坐下來！你剛醒，第一件事就該好好吃一頓。上陣前帶些料理——肚子飽，手才穩。"
        ),
        NpcIntroDef(
            actorKey:    "pharmacist",
            defaultName: "藥師",
            introLine:   "讓我看看。傷口恢復不錯，體質不差。進地下城前來備藥，沒有人只靠意志力撐過深層的。"
        ),
        NpcIntroDef(
            actorKey:    "merchant",
            defaultName: "魚商",
            introLine:   "大難不死的傢伙！我就說嘛，撿回來的准是人物。什麼都賣什麼都收，素材換金幣，最實在。"
        ),
        NpcIntroDef(
            actorKey:    "armorer",
            defaultName: "皮甲師",
            introLine:   "你剛才那一戰，我看出來你是個能打的。防具才是長命百歲的關鍵——讓我給你做一件像樣的護甲。"
        ),
        NpcIntroDef(
            actorKey:    "weaponsmith",
            defaultName: "副手師",
            introLine:   "副手武器嘛，一般人都不重視。但我告訴你，一把好的格擋刃或箭筒，關鍵時刻能救你一命。"
        ),
        NpcIntroDef(
            actorKey:    "jeweler",
            defaultName: "飾品師",
            introLine:   "珠寶？不，我做的是戰鬥飾品。攻擊、防禦、生命——看你需要什麼，我替你鑲嵌。"
        ),
    ]

    static func find(actorKey: String) -> NpcIntroDef? {
        all.first { $0.actorKey == actorKey }
    }
}
