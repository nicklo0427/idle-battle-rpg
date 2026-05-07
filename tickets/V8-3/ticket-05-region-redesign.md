# V8-3 Ticket 05：地下城主題重設計（農場 / 森林 / 草原 / 沙漠）

**狀態：** ✅ 完成

**依賴：** 無

---

## 目標

將現有 4 個地下城地區換成新主題，強化世界觀差異化。**所有 key / rawValue 保持不變**，存檔完全相容。

---

## 修改細節

### `StaticData/DungeonRegionDef.swift`

只修改 `name`、`desc`、`suiteName`、樓層名稱、敵人名、Boss 名，不動任何 key。

---

#### Region 1 — key: `wildland` → 金穗之野（農場）

- **name：** `"金穗之野"`
- **desc：** `"豐饒農地被野獸與惡靈侵擾，收穫與危險並存。"`
- **suiteName：** `"農地衛守套裝"`

| 樓層 key | 新名稱 | 敵人 |
|---------|--------|------|
| wildland_floor_1 | 穀倉前道 | 野豬掠奪者、偷糧鳥獸、田間流氓 |
| wildland_floor_2 | 荒廢農舍 | 稻草人惡靈、農場狂戰士、豐收鬼魂 |
| wildland_floor_3 | 豐收穀倉 | 倉庫守衛長、巨型倉鼠王、飢餓農奴 |
| wildland_floor_4 ❖ | 農神祭壇 | Boss：**豐收惡神** |

---

#### Region 2 — key: `abandoned_mine` → 暮色古林（森林）

- **name：** `"暮色古林"`
- **desc：** `"古老森林深處靈氣充溢，卻被腐化的精靈與獸靈盤據。"`
- **suiteName：** `"森林獵人套裝"`

| 樓層 key | 新名稱 | 敵人 |
|---------|--------|------|
| abandoned_mine_floor_1 | 林道入口 | 森林狼群、荊棘射手、藤蔓蟲群 |
| abandoned_mine_floor_2 | 古樹迷宮 | 腐木傀儡、精靈游獵者、暗夜追蹤者 |
| abandoned_mine_floor_3 | 幽暗深處 | 古林守護者、黑夜獸靈、腐化樹人 |
| abandoned_mine_floor_4 ❖ | 古林王座 | Boss：**千年古林王** |

---

#### Region 3 — key: `ancient_ruins` → 血色曠野（草原）

- **name：** `"血色曠野"`
- **desc：** `"廣闊草原上游牧部落互相征伐，天際染血的戰場。"`
- **suiteName：** `"草原霸主套裝"`

| 樓層 key | 新名稱 | 敵人 |
|---------|--------|------|
| ancient_ruins_floor_1 | 草原邊緣 | 游牧斥候、草原鬣狗、騎馬獵手 |
| ancient_ruins_floor_2 | 遊牧廢營 | 部落戰士、祭祀巫師、旗手騎兵 |
| ancient_ruins_floor_3 | 衝突前線 | 精銳重甲兵、前線指揮官、衝鋒戰士 |
| ancient_ruins_floor_4 ❖ | 血旗王庭 | Boss：**血旗草原王** |

---

#### Region 4 — key: `sunken_city` → 烈焰沙海（沙漠）

- **name：** `"烈焰沙海"`
- **desc：** `"永恆烈日下，古老法老的詛咒在廢墟中沸騰。"`
- **suiteName：** `"沙漠遠征套裝"`

| 樓層 key | 新名稱 | 敵人 |
|---------|--------|------|
| sunken_city_floor_1 | 沙丘入口 | 沙漠蠍兵、骷髏流浪者、熱焰精靈 |
| sunken_city_floor_2 | 沙暴迴廊 | 沙漠術士、沙暴戰士、沙中游魂 |
| sunken_city_floor_3 | 法老深墓 | 木乃伊衛兵、古墓祭司、守墓傀儡 |
| sunken_city_floor_4 ❖ | 烈陽神座 | Boss：**不死沙漠法老** |

---

### `StaticData/MaterialType.swift` — displayName + icon 更新（rawValue 不動）

| rawValue | 舊名 | 新名 | 新 icon |
|----------|------|------|---------|
| outpost_badge | 舊哨徽片 | 收成勳章 | 🌾 |
| dried_hide | 風乾獸皮束 | 野豬獠牙 | 🐗 |
| antler_bone | 裂角繫骨 | 倉庫鎖片 | 🗝️ |
| fang_crest | 裂牙王徽 | 農神印記 | 🌻 |
| lamp_copper | 礦燈銅扣 | 精靈羽毛 | 🪶 |
| shaft_iron | 坑道鐵扣 | 古樹皮塊 | 🌳 |
| vein_slate | 脈石板 | 腐化木紋板 | 🍃 |
| rock_core | 吞石核心 | 千年樹心 | 🖤 |
| seal_ring | 殘印石環 | 部落圖騰 | 🔮 |
| oath_shard | 誓約刻片 | 破碎戰旗 | 🚩 |
| hall_clip | 前殿扣片 | 鐵蹄護符 | ⚜️ |
| king_core | 古王核心 | 草原王核 | 🟡 |
| sunken_fragment | 沉紋碎片 | 沙漠符文石 | 🟠 |
| abyss_crystal | 深淵晶滴 | 熱焰水晶 | 🔶 |
| crown_shard | 溺冕碎片 | 法老封印片 | 🏺 |
| sunken_seal | 沉王印璽 | 法老王璽 | 👁️ |

---

### `StaticData/EquipmentDef.swift` — name 更新（key 不動）

| key | 舊名 | 新名 |
|-----|------|------|
| outpost_charm | 前哨護符 | 農地護符 |
| trail_leather | 荒徑皮甲 | 田野皮甲 |
| antler_brace | 裂角臂扣 | 豐收臂環 |
| cracked_fang | 裂牙獵刃 | 農神鐮刀 |
| miner_lamp | 礦燈墜飾 | 林靈護符 |
| vein_iron_armor | 脈鐵工作甲 | 荊棘葉甲 |
| vein_brace | 承脈護架 | 藤蔓護腕 |
| rock_crusher | 吞岩重鑿 | 古林巨斧 |
| oath_ring | 守誓印環 | 草原獸牙環 |
| rune_oath_armor | 碑紋誓甲 | 游牧皮甲 |
| hall_crest | 前殿聖徽 | 戰旗護盾 |
| oath_blade | 王誓聖刃 | 草原彎刀 |
| sunken_charm | 沉紋護符 | 沙漠護符 |
| abyss_armor | 深淵溺甲 | 法老甲冑 |
| crown_crest | 沉冕王徽 | 古墓護盾 |
| sunken_blade | 沉王裂水刃 | 法老鑲金劍 |

---

## 修改檔案

- `StaticData/DungeonRegionDef.swift`（4 區域名稱 / 描述 / 16 樓層 / 敵人）
- `StaticData/MaterialType.swift`（16 個素材 displayName + icon）
- `StaticData/EquipmentDef.swift`（16 件裝備 name）

---

## 驗收標準

- [ ] Build 無錯誤
- [ ] 4 個地區名稱 / 描述全部更新
- [ ] 16 個樓層名稱更新（含 Boss 名）
- [ ] 16 個素材 displayName + icon 更新（rawValue 不動）
- [ ] 16 件裝備 name 更新（key 不動）
- [ ] 舊存檔進入後：已解鎖樓層 / 地區仍顯示為已解鎖（key 未變，存檔相容）
