# levels —— 关卡组装、重置与通关

> 实现:`scenes/levels/Level_01.tscn` + `scripts/level/level_01_manager.gd` + `tools/build_level_01.gd`;规范:docs/02 §8、docs/05。

## 关卡场景骨架(由构建脚本生成,勿手摆)

```
Level_XX (Node2D, 挂 LevelXXManager)
├── Floor (TileMapLayer isometric 64×32 DIAMOND_DOWN)
├── WallColliders (StaticBody2D: 周界+横墙脚印菱形;出口格不设、背后虚拟格兜底)
├── YSorted (y_sort): 周界墙 / 横墙 / SecurityDoor / PressureSwitch / 装置 / ExitArea / Player
├── EchoManager (unique name)
└── UI (CanvasLayer 实例)
```

- 布局常量集中在构建脚本头部(SPAWN_CELL/DOOR_CELL/SWITCH_CELL/EXIT_CELLS)。
- **接线归属**:机关间/机关与门/机关与流程的信号连接,由 LevelXXManager 在 `_ready` 完成(如 `_switch.switch_activated.connect(_door.set_open.bind(true))`)——pack() 不保存运行时连接,dev 房间脚本先例。

## Level01Manager 状态机

```
INTRO → PLAY(自由探索/记录/回放) → COMPLETE(冻结世界+通关)
```
- Backspace(PLAY 中)→ `reset_room()`。
- 出口 `player_entered` → 记录中则 `discard_buffer()`(E-09)→ `paused = true`(冻结防误动)→ `level_completed.emit(1)` → `SaveManager.mark_level_completed(1)`。
- `restart_requested`(通关界面任意键,延迟 1.2s 且忽略按住键 echo;或暂停菜单重开)→ `reset_room()` + 解除冻结 + 回 PLAY。

## 重置四步(docs/02 §8.2,顺序勿变)

```gdscript
_echo_mgr.clear_all()          # 1 回声+调试线,并广播 echo_count_changed(0)
_player.recorder.clear_all()   # 1 未完成 + 最近已完成记录
_switch.force_reset()          # 2 机关复位(门联动关闭)
_door.force_reset()
_device.force_reset()          #    装置提示重新武装
_player.reset_to(_spawn_position)  # 3 玩家复位
_switch_seen = false ...       # 4 教学阶段复位
```
新增机关/可复位对象 → 必须提供 `force_reset()` 并在此调用。

## 教学提示链(docs/05 §6,经 GameEvents.notify_requested → HUD)

T-03(首次靠近装置,重置重武装)→ T-02(首次踩上开关后离开)→ T-05(每次记录完成)→ T-06(回声超限,EchoManager 发)。新增提示一律加 `UIText` 常量。

## 新增关卡步骤

1. 复制 `tools/build_level_04.gd`(第二章模板:含记录区/出口区手搭)为 `build_level_XX.gd`,改布局常量与机关组合(走 isometric.md 的格位/锚点规则);
2. 新建 `scripts/level/level_XX_manager.gd`(继承 LevelManagerBase),root `set_script` 挂接;
3. **每关必设** `max_echoes` 与 `next_scene`(漏设 = 过关原地重玩,L4/L5/L7 三次返修教训——构建脚本模板固定行);章末关 next_scene 留空 → 完成界面任意键打开关卡选择菜单;
4. `GameEvents` 增加新信号须同步 docs/02 §2.2;
5. 构建:`timeout 90 godot --headless --path EchoesOfYesterday -s tools/build_level_XX.gd`;新 class_name 先跑一次 `--import` 入全局缓存;
6. 冒烟剧本按新布局调整走位(门洞通道 |dx|≤10,路线要预留滑行);**推进链必须断言 `current_scene` 变化**。

## 第二章(L4—L6)构建要点(docs/13—16)

| 关 | 地图 | 机关 | 记录区 | 上限 | next_scene |
| --- | --- | --- | --- | --- | --- |
| L4 时间干扰 | 16×12 | 干扰场×2、脉冲板×2、同振窗门 | x0..3, y9..11 | 3 | Level_05 |
| L5 重复的实验 | 16×12 | 能量核心×2、联动桥、干扰场 | x0..6, y1..11(前厅) | 3 | Level_06 |
| L6 失控区域 | 18×14 | 序列门(关卡层)、时间锁、核心、干扰场×4 | x0..5, y9..13 | 3 | ""(章末→菜单) |

- **记录区注入**:`_add_record_zone(level, floor_layer, decals, from, to, SPAWN_CELL)`——世界包围盒 Area + 出生点标记(z_index=1 置顶,防墙体精灵遮挡);
- **出口触发区手搭**:单格 44×20(128×32 泄漏邻格,实例内部子节点修改 pack() 不记录);
- **门位铁律**:门正对出口且不占回声必经渡口(L6 门 (9,1) 正对出口,回声跨区走 y2 行);
- **聚合逻辑归关卡层**:同振窗(L4,1.5s 维持)、门 AND(L5)、序列门(L6,乱序无效+闪红);
- 干扰场判定圈 = 格心圆 r8(isometric.md 32px 口径);回声车道贴行绝不误伤。

## 第三章(L7—L8)构建要点(docs/17—19)

| 关 | 地图 | 机关 | 记录区 | 上限 | next_scene |
| --- | --- | --- | --- | --- | --- |
| L7 相位回廊 | 18×12 | 相位门(核心供电)、悖论区×2(P1 横贯回廊,S2 在区内)、双开关 AND 门 | x1..3, y8..10 | 3 | Level_08 |
| L8 昨日回声 | 18×14 | 悖论之海(36 格,C1 在区内——拨核必须进区)、供电门断电窗(关卡层计时 10s)、时间锁(常 arm)、三重门 | x1..5, y9..12 | 3 | ""(章末→菜单) |

- **覆层层级**(硬规则 15):悖论区/危害区覆层节点先于 Decals 加入(Floor → 覆层 → Decals → YSorted);
- **谜题语法「时空在场调度」**:回声末帧停留持续占用在场身份;L7 标准解含「先穿区北上、再从北侧发射回声」(Space 全局可用 + R2 回原位);L8 断电计时归关卡层(EnergyCore 契约零改动,`core_toggled(false)` → 10s → `set_on(true)`);
- **录一条发一条**:记录只保留最近一条——每条回声的发射必须紧跟各自录制,「录两条再发两条」会复放同一路线;
- 冒烟脚本对真实存档**备份/还原**(硬规则 16);关卡选择菜单第一关恒可选。

## 推进链与关卡选择(用户验收新增)

L1→L2→…→L6 全链 `next_scene`;章末(next_scene 为空)完成界面任意键 → `LevelSelect` 菜单(已通关可点选重玩、未通关灰置);暂停菜单「关卡选择」按钮同入口;`LevelSelect.previous_scene` 静态记录来源,Esc 返回。
