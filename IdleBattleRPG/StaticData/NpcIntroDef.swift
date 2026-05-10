// NpcIntroDef.swift
// V10-1 NPC 首次對話靜態定義

import Foundation

struct NpcIntroDef {
    let actorKey:    String   // 對應 TaskModel.actorKey
    let defaultName: String   // 系統預設名（玩家命名前顯示）
    let introLine:   String   // 首次對話台詞
    let shortLine:   String   // 看過首次對話後的短招呼
}

extension NpcIntroDef {

    static let all: [NpcIntroDef] = [
        NpcIntroDef(
            actorKey:    "gatherer_1",
            defaultName: "伐木工阿森",
            introLine:   "醒了就好。我在森林邊緣找到你，木材的事交給我，先把要塞撐起來。",
            shortLine:   "森林那邊風向不錯，今天適合砍木材。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_2",
            defaultName: "採礦工鐵叔",
            introLine:   "礦脈會說話，只是多數人聽不懂。需要礦石時找我，我知道哪裡下鎬最穩。",
            shortLine:   "鎬子磨好了，想挖礦就出發。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_3",
            defaultName: "採藥師阿芷",
            introLine:   "你的傷能好，全靠幾味草藥吊住。我會替你找能救命的藥材，別把它們只當雜草。",
            shortLine:   "露水還沒乾，這時候採藥最好。"
        ),
        NpcIntroDef(
            actorKey:    "gatherer_4",
            defaultName: "漁夫小潮",
            introLine:   "水面比人誠實，什麼時候有收成一看就知道。要魚就喊我，我去溪邊走一趟。",
            shortLine:   "水色很清，今天應該有好魚。"
        ),
        NpcIntroDef(
            actorKey:    "farmer",
            defaultName: "農夫老禾",
            introLine:   "土地不會騙人，撒下什麼就等什麼長出來。要塞想久一點，田就不能荒。",
            shortLine:   "田裡還有空位，種點東西總不虧。"
        ),
        NpcIntroDef(
            actorKey:    "blacksmith",
            defaultName: "鑄造師老鐵",
            introLine:   "空手上陣是找死。把素材給我，我替你打出能活下來的裝備。",
            shortLine:   "爐火正旺，想打造就趁現在。"
        ),
        NpcIntroDef(
            actorKey:    "chef",
            defaultName: "廚師阿灶",
            introLine:   "先吃飯，再談冒險。肚子穩了，手才穩，地下城裡才不會出差錯。",
            shortLine:   "鍋還熱著，出門前帶點吃的。"
        ),
        NpcIntroDef(
            actorKey:    "pharmacist",
            defaultName: "藥師白芷",
            introLine:   "傷口恢復得不錯，但別逞強。進地下城前備好藥，活著回來才有下次。",
            shortLine:   "藥瓶都封好了，需要就帶上。"
        ),
        NpcIntroDef(
            actorKey:    "merchant",
            defaultName: "商人老錢",
            introLine:   "素材、金幣、稀有貨，我都能想辦法周轉。你只管冒險，買賣交給我。",
            shortLine:   "貨架補好了，看看有沒有缺的。"
        ),
        NpcIntroDef(
            actorKey:    "armorer",
            defaultName: "皮甲師阿革",
            introLine:   "會打只是開始，撐得住才走得遠。拿皮料來，我替你做件像樣的護甲。",
            shortLine:   "量身的尺還在，護甲可以開工。"
        ),
        NpcIntroDef(
            actorKey:    "weaponsmith",
            defaultName: "鍛造學徒小錘",
            introLine:   "師父說小件也有大用。盾牌、短刃、副手武器，關鍵時候都能救你一命。",
            shortLine:   "小件我最拿手，交給我吧。"
        ),
        NpcIntroDef(
            actorKey:    "jeweler",
            defaultName: "飾品師銀鈴",
            introLine:   "我做的不是擺飾，是能在戰鬥裡派上用場的飾品。想補哪種能力，挑清楚。",
            shortLine:   "寶石和扣環都備好了，來挑一件。"
        ),
        NpcIntroDef(
            actorKey:    "tailor",
            defaultName: "裁縫師阿針",
            introLine:   "皮料、布料、鏈環都能縫成護身的東西。想輕一點還是厚一點，我替你量。",
            shortLine:   "針線都順手了，防具可以開工。"
        ),
    ]

    static func find(actorKey: String) -> NpcIntroDef? {
        all.first { $0.actorKey == actorKey }
    }
}
