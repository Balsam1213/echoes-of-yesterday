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

1. 复制 `tools/build_level_01.gd` 为 `build_level_XX.gd`,改布局常量与机关组合(走 isometric.md 的格位/锚点规则);
2. 新建 `scripts/level/level_XX_manager.gd`(可继承 Level01Manager 模式),root `set_script` 挂接;
3. `GameEvents` 增加新信号须同步 docs/02 §2.2;
4. 构建:`timeout 90 godot --headless --path EchoesOfYesterday -s tools/build_level_XX.gd`;新 class_name 先跑一次 `--import` 入全局缓存;
5. 主场景切换改 project.godot `run/main_scene`;
6. 冒烟剧本按新布局调整走位(门洞通道 |dx|≤10,路线要预留滑行)。
