# Ticket T02 — Boss 武器最低值保底

## 問題
所有 Boss 武器的 `atkRange` 下限都低於同區鑄造武器，導致 Boss 掉落可能比自己打造的還差。

## 解法
Boss 武器下限 = 鑄造武器 ATK + 2，保持上限幅度供 farming 動機。

| 武器 key | 鑄造 ATK | 舊範圍 | 新範圍 |
|---|---|---|---|
| `wildland_weapon` | +22 | `18...30` | `24...36` |
| `mine_weapon` | +40 | `34...48` | `42...56` |
| `ruins_weapon` | +62 | `54...72` | `64...84` |
| `sunken_city_weapon` | +80 | `70...92` | `82...108` |

## 修改的檔案

### `IdleBattleRPG/StaticData/EquipmentDef.swift`
四個 Boss 武器的 `atkRange` 調整（L191, L231, L272, L313）。

## 驗證
- Boss 掉落武器 ATK 下限 ≥ 同區鑄造武器 ATK + 2
